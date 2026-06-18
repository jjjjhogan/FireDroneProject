import json
import sqlite3
from contextlib import contextmanager
from pathlib import Path
from uuid import uuid4

from app.dji.state_store import utc_now_iso


SAFETY_CHECKLIST_DEFAULTS = {
    "geofence": {
        "status": "not_verified",
        "notes": "No operational geofence has been verified for the current incident.",
        "engaged": False,
    },
    "remoteId": {
        "status": "not_verified",
        "notes": "Remote ID compliance has not been verified for a real aircraft.",
        "engaged": False,
    },
    "airspaceApproval": {
        "status": "not_verified",
        "notes": "Airspace approval has not been attached to this mission package.",
        "engaged": False,
    },
    "emergencyStop": {
        "status": "ready",
        "notes": "Simulation emergency stop is armed; no hardware command is sent.",
        "engaged": False,
    },
}

SAFETY_CHECKLIST_STATUSES = {
    "not_verified",
    "pending",
    "verified",
    "blocked",
    "ready",
    "engaged",
}


class OperationsStore:
    def __init__(self, path):
        self.path = Path(path)

    def _connect(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(self.path)
        connection.row_factory = sqlite3.Row
        self._ensure_schema(connection)
        return connection

    @contextmanager
    def _session(self):
        connection = self._connect()
        try:
            yield connection
        finally:
            connection.close()

    def _ensure_schema(self, connection):
        connection.executescript(
            """
            create table if not exists audit_entries (
              entry_id text primary key,
              timestamp text not null,
              actor text not null,
              role text not null,
              action text not null,
              target_id text not null,
              details text not null
            );

            create table if not exists alerts (
              event_id text primary key,
              detection_type text not null,
              confidence real not null,
              severity text not null,
              lat real not null,
              lon real not null,
              source_drone_id text not null,
              image_uri text not null,
              thermal_uri text not null,
              timestamp text not null,
              status text not null,
              reviewer text,
              review_timestamp text,
              notes text not null,
              raw_json text not null
            );

            create table if not exists safety_checklist (
              key text primary key,
              status text not null,
              notes text not null,
              engaged integer not null default 0,
              updated_at text not null,
              updated_by text not null
            );
            """
        )
        connection.commit()

    def record_audit(self, actor, role, action, target_id, details):
        entry = {
            "entryId": f"audit-{uuid4().hex[:12]}",
            "timestamp": utc_now_iso(),
            "actor": actor or "system",
            "role": role or "system",
            "action": action,
            "targetId": target_id or "",
            "details": details or "",
        }
        with self._session() as connection:
            connection.execute(
                """
                insert into audit_entries
                (entry_id, timestamp, actor, role, action, target_id, details)
                values (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    entry["entryId"],
                    entry["timestamp"],
                    entry["actor"],
                    entry["role"],
                    entry["action"],
                    entry["targetId"],
                    entry["details"],
                ),
            )
            connection.commit()
        return entry

    def list_audit(self, limit=100):
        with self._session() as connection:
            rows = connection.execute(
                """
                select entry_id, timestamp, actor, role, action, target_id, details
                from audit_entries
                order by timestamp desc, entry_id desc
                limit ?
                """,
                (int(limit),),
            ).fetchall()
        return [
            {
                "entryId": row["entry_id"],
                "timestamp": row["timestamp"],
                "actor": row["actor"],
                "role": row["role"],
                "action": row["action"],
                "targetId": row["target_id"],
                "details": row["details"],
            }
            for row in rows
        ]

    def upsert_alert(self, alert):
        stored = {
            "eventId": alert["eventId"],
            "detectionType": alert["detectionType"],
            "confidence": float(alert["confidence"]),
            "severity": alert["severity"],
            "lat": float(alert["lat"]),
            "lon": float(alert["lon"]),
            "sourceDroneId": alert["sourceDroneId"],
            "imageUri": alert.get("imageUri", ""),
            "thermalUri": alert.get("thermalUri", ""),
            "timestamp": alert["timestamp"],
            "status": alert.get("status", "Unconfirmed"),
            "reviewer": alert.get("reviewer"),
            "reviewTimestamp": alert.get("reviewTimestamp"),
            "notes": alert.get("notes", ""),
            "raw": alert.get("raw", alert),
        }
        with self._session() as connection:
            connection.execute(
                """
                insert into alerts
                (event_id, detection_type, confidence, severity, lat, lon,
                 source_drone_id, image_uri, thermal_uri, timestamp, status,
                 reviewer, review_timestamp, notes, raw_json)
                values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                on conflict(event_id) do update set
                  detection_type=excluded.detection_type,
                  confidence=excluded.confidence,
                  severity=excluded.severity,
                  lat=excluded.lat,
                  lon=excluded.lon,
                  source_drone_id=excluded.source_drone_id,
                  image_uri=excluded.image_uri,
                  thermal_uri=excluded.thermal_uri,
                  timestamp=excluded.timestamp,
                  notes=excluded.notes,
                  raw_json=excluded.raw_json
                """,
                (
                    stored["eventId"],
                    stored["detectionType"],
                    stored["confidence"],
                    stored["severity"],
                    stored["lat"],
                    stored["lon"],
                    stored["sourceDroneId"],
                    stored["imageUri"],
                    stored["thermalUri"],
                    stored["timestamp"],
                    stored["status"],
                    stored["reviewer"],
                    stored["reviewTimestamp"],
                    stored["notes"],
                    json.dumps(stored["raw"], sort_keys=True),
                ),
            )
            connection.commit()
        return stored

    def list_alerts(self):
        with self._session() as connection:
            rows = connection.execute(
                """
                select event_id, detection_type, confidence, severity, lat, lon,
                       source_drone_id, image_uri, thermal_uri, timestamp, status,
                       reviewer, review_timestamp, notes
                from alerts
                order by timestamp desc, event_id asc
                """
            ).fetchall()
        return [self._alert_from_row(row) for row in rows]

    def get_alert(self, event_id):
        with self._session() as connection:
            row = connection.execute(
                """
                select event_id, detection_type, confidence, severity, lat, lon,
                       source_drone_id, image_uri, thermal_uri, timestamp, status,
                       reviewer, review_timestamp, notes
                from alerts
                where event_id=?
                """,
                (event_id,),
            ).fetchone()
        if row is None:
            return None
        return self._alert_from_row(row)

    def review_alert(self, event_id, status, reviewer, notes):
        review_timestamp = utc_now_iso()
        with self._session() as connection:
            cursor = connection.execute(
                """
                update alerts
                set status=?, reviewer=?, review_timestamp=?, notes=?
                where event_id=?
                """,
                (status, reviewer, review_timestamp, notes or "", event_id),
            )
            connection.commit()
            if cursor.rowcount == 0:
                return None
        return self.get_alert(event_id)

    def safety_checklist(self):
        checklist = {
            key: {
                "status": value["status"],
                "notes": value["notes"],
                "engaged": bool(value["engaged"]),
                "updatedAt": None,
                "updatedBy": "system",
            }
            for key, value in SAFETY_CHECKLIST_DEFAULTS.items()
        }
        with self._session() as connection:
            rows = connection.execute(
                """
                select key, status, notes, engaged, updated_at, updated_by
                from safety_checklist
                """
            ).fetchall()
        for row in rows:
            if row["key"] not in checklist:
                continue
            checklist[row["key"]] = {
                "status": row["status"],
                "notes": row["notes"],
                "engaged": bool(row["engaged"]),
                "updatedAt": row["updated_at"],
                "updatedBy": row["updated_by"],
            }
        return checklist

    def update_safety_checklist(self, payload, actor):
        if not isinstance(payload, dict):
            raise ValueError("Checklist update must be a JSON object")

        rows = []
        timestamp = utc_now_iso()
        actor = actor or "system"
        for key, value in payload.items():
            if key not in SAFETY_CHECKLIST_DEFAULTS:
                raise ValueError(f"Unsupported safety checklist item: {key}")
            if not isinstance(value, dict):
                raise ValueError(f"{key} must be an object")

            current = self.safety_checklist()[key]
            status = str(value.get("status", current["status"])).strip()
            if status not in SAFETY_CHECKLIST_STATUSES:
                raise ValueError(
                    "status must be one of "
                    + ", ".join(sorted(SAFETY_CHECKLIST_STATUSES))
                )

            notes = str(value.get("notes", current["notes"])).strip()
            engaged = bool(value.get("engaged", current["engaged"]))
            rows.append((key, status, notes, 1 if engaged else 0, timestamp, actor))

        with self._session() as connection:
            connection.executemany(
                """
                insert into safety_checklist
                (key, status, notes, engaged, updated_at, updated_by)
                values (?, ?, ?, ?, ?, ?)
                on conflict(key) do update set
                  status=excluded.status,
                  notes=excluded.notes,
                  engaged=excluded.engaged,
                  updated_at=excluded.updated_at,
                  updated_by=excluded.updated_by
                """,
                rows,
            )
            connection.commit()
        return self.safety_checklist()

    def set_emergency_stop(self, engaged, actor, notes):
        status = "engaged" if engaged else "ready"
        return self.update_safety_checklist(
            {
                "emergencyStop": {
                    "status": status,
                    "engaged": bool(engaged),
                    "notes": notes,
                }
            },
            actor=actor,
        )

    def _alert_from_row(self, row):
        return {
            "eventId": row["event_id"],
            "detectionType": row["detection_type"],
            "confidence": row["confidence"],
            "severity": row["severity"],
            "lat": row["lat"],
            "lon": row["lon"],
            "sourceDroneId": row["source_drone_id"],
            "imageUri": row["image_uri"],
            "thermalUri": row["thermal_uri"],
            "timestamp": row["timestamp"],
            "status": row["status"],
            "reviewer": row["reviewer"],
            "reviewTimestamp": row["review_timestamp"],
            "notes": row["notes"],
        }
