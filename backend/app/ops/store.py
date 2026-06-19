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

            create table if not exists missions (
              mission_id text primary key,
              scenario_id text not null,
              scenario_name text not null,
              area text not null,
              status text not null,
              assigned_drone_id text not null,
              operator_name text not null,
              route_points_json text not null,
              progress_pct integer not null default 0,
              estimated_duration_min integer not null default 0,
              risk_level text not null default 'unknown',
              data_source text not null default 'simulation',
              notes text not null,
              started_at text not null,
              updated_at text not null,
              completed_at text
            );

            create index if not exists missions_status_idx
              on missions(status, updated_at desc);
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

    MISSION_STATUSES = {
        "planning",
        "preview_ready",
        "confirmed",
        "active",
        "paused",
        "completed",
        "aborted",
    }

    TERMINAL_MISSION_STATUSES = {"completed", "aborted"}

    def _mission_from_row(self, row):
        route_points = json.loads(row["route_points_json"] or "[]")
        return {
            "missionId": row["mission_id"],
            "scenarioId": row["scenario_id"],
            "scenarioName": row["scenario_name"],
            "area": row["area"],
            "status": row["status"],
            "assignedDroneId": row["assigned_drone_id"],
            "operatorName": row["operator_name"],
            "routePoints": route_points,
            "progressPct": row["progress_pct"],
            "estimatedDurationMin": row["estimated_duration_min"],
            "riskLevel": row["risk_level"],
            "dataSource": row["data_source"],
            "notes": row["notes"],
            "startedAt": row["started_at"],
            "updatedAt": row["updated_at"],
            "completedAt": row["completed_at"],
        }

    def list_missions(self, limit=20):
        with self._connect() as connection:
            rows = connection.execute(
                """
                select *
                from missions
                order by updated_at desc, mission_id desc
                limit ?
                """,
                (int(limit),),
            ).fetchall()
        return [self._mission_from_row(row) for row in rows]

    def get_mission(self, mission_id):
        with self._connect() as connection:
            row = connection.execute(
                "select * from missions where mission_id = ?",
                (mission_id,),
            ).fetchone()
        return self._mission_from_row(row) if row else None

    def get_active_mission(self):
        with self._connect() as connection:
            row = connection.execute(
                """
                select *
                from missions
                where status not in ('completed', 'aborted')
                order by updated_at desc, mission_id desc
                limit 1
                """
            ).fetchone()
        return self._mission_from_row(row) if row else None

    def plan_mission(self, payload):
        scenario_id = str(payload.get("scenarioId", "unknown")).strip()
        scenario_name = str(payload.get("scenarioName", "Unknown scenario")).strip()
        area = str(payload.get("area", "Unknown area")).strip()
        operator_name = str(payload.get("operatorName", "Simulation Operator")).strip()
        assigned_drone_id = str(
            payload.get("assignedDroneId", "unassigned")
        ).strip()
        route_points = payload.get("routePoints") or []
        notes = str(
            payload.get(
                "notes",
                "Simulation-first mission package. Hardware dispatch remains gated.",
            )
        ).strip()
        data_source = str(payload.get("dataSource", "simulation")).strip()
        timestamp = utc_now_iso()
        mission_id = str(payload.get("missionId") or f"mission-{uuid4().hex[:10]}")

        active = self.get_active_mission()
        if active and active["scenarioId"] != scenario_id:
            self.transition_mission(
                active["missionId"],
                "aborted",
                notes="Superseded by a newly planned scenario mission.",
            )

        record = {
            "missionId": mission_id,
            "scenarioId": scenario_id,
            "scenarioName": scenario_name,
            "area": area,
            "status": "planning",
            "assignedDroneId": assigned_drone_id,
            "operatorName": operator_name,
            "routePoints": route_points,
            "progressPct": 0,
            "estimatedDurationMin": 0,
            "riskLevel": "unknown",
            "dataSource": data_source,
            "notes": notes,
            "startedAt": timestamp,
            "updatedAt": timestamp,
            "completedAt": None,
        }

        with self._connect() as connection:
            connection.execute(
                """
                insert into missions
                (mission_id, scenario_id, scenario_name, area, status,
                 assigned_drone_id, operator_name, route_points_json,
                 progress_pct, estimated_duration_min, risk_level, data_source,
                 notes, started_at, updated_at, completed_at)
                values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                on conflict(mission_id) do update set
                  scenario_id=excluded.scenario_id,
                  scenario_name=excluded.scenario_name,
                  area=excluded.area,
                  status=excluded.status,
                  assigned_drone_id=excluded.assigned_drone_id,
                  operator_name=excluded.operator_name,
                  route_points_json=excluded.route_points_json,
                  progress_pct=excluded.progress_pct,
                  estimated_duration_min=excluded.estimated_duration_min,
                  risk_level=excluded.risk_level,
                  data_source=excluded.data_source,
                  notes=excluded.notes,
                  updated_at=excluded.updated_at,
                  completed_at=excluded.completed_at
                """,
                (
                    record["missionId"],
                    record["scenarioId"],
                    record["scenarioName"],
                    record["area"],
                    record["status"],
                    record["assignedDroneId"],
                    record["operatorName"],
                    json.dumps(record["routePoints"]),
                    record["progressPct"],
                    record["estimatedDurationMin"],
                    record["riskLevel"],
                    record["dataSource"],
                    record["notes"],
                    record["startedAt"],
                    record["updatedAt"],
                    record["completedAt"],
                ),
            )
            connection.commit()
        return record

    def apply_preview(self, mission_id, preview):
        mission = self.get_mission(mission_id)
        if not mission:
            raise ValueError("Mission not found")

        updated = {
            **mission,
            "status": "preview_ready" if preview.get("available") else "planning",
            "routePoints": preview.get("routePoints") or mission["routePoints"],
            "estimatedDurationMin": int(preview.get("estimatedDurationMin") or 0),
            "riskLevel": str(preview.get("riskLevel") or mission["riskLevel"]),
            "notes": "; ".join(preview.get("warnings") or []) or mission["notes"],
            "updatedAt": utc_now_iso(),
        }

        with self._connect() as connection:
            connection.execute(
                """
                update missions
                set status = ?, route_points_json = ?, estimated_duration_min = ?,
                    risk_level = ?, notes = ?, updated_at = ?
                where mission_id = ?
                """,
                (
                    updated["status"],
                    json.dumps(updated["routePoints"]),
                    updated["estimatedDurationMin"],
                    updated["riskLevel"],
                    updated["notes"],
                    updated["updatedAt"],
                    mission_id,
                ),
            )
            connection.commit()
        return updated

    def confirm_mission_record(self, mission_id, confirm_result):
        mission = self.get_mission(mission_id)
        if not mission:
            raise ValueError("Mission not found")

        accepted = bool(confirm_result.get("accepted"))
        timestamp = utc_now_iso()
        if accepted:
            updated = {
                **mission,
                "missionId": confirm_result.get("missionId") or mission_id,
                "status": "active",
                "progressPct": max(mission["progressPct"], 5),
                "notes": confirm_result.get("nextRequiredAction") or mission["notes"],
                "updatedAt": timestamp,
                "completedAt": None,
            }
        else:
            updated = {
                **mission,
                "status": "confirmed" if mission["status"] == "preview_ready" else mission["status"],
                "notes": confirm_result.get("blockedReason") or mission["notes"],
                "updatedAt": timestamp,
            }

        with self._connect() as connection:
            if accepted and updated["missionId"] != mission_id:
                connection.execute(
                    "delete from missions where mission_id = ?",
                    (mission_id,),
                )
            connection.execute(
                """
                insert into missions
                (mission_id, scenario_id, scenario_name, area, status,
                 assigned_drone_id, operator_name, route_points_json,
                 progress_pct, estimated_duration_min, risk_level, data_source,
                 notes, started_at, updated_at, completed_at)
                values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                on conflict(mission_id) do update set
                  status=excluded.status,
                  progress_pct=excluded.progress_pct,
                  notes=excluded.notes,
                  updated_at=excluded.updated_at,
                  completed_at=excluded.completed_at
                """,
                (
                    updated["missionId"],
                    updated["scenarioId"],
                    updated["scenarioName"],
                    updated["area"],
                    updated["status"],
                    updated["assignedDroneId"],
                    updated["operatorName"],
                    json.dumps(updated["routePoints"]),
                    updated["progressPct"],
                    updated["estimatedDurationMin"],
                    updated["riskLevel"],
                    updated["dataSource"],
                    updated["notes"],
                    updated["startedAt"],
                    updated["updatedAt"],
                    updated["completedAt"],
                ),
            )
            connection.commit()
        return updated

    def transition_mission(self, mission_id, status, notes=None, progress_pct=None):
        if status not in self.MISSION_STATUSES:
            raise ValueError(f"Unsupported mission status: {status}")

        mission = self.get_mission(mission_id)
        if not mission:
            raise ValueError("Mission not found")

        timestamp = utc_now_iso()
        completed_at = mission["completedAt"]
        if status in self.TERMINAL_MISSION_STATUSES:
            completed_at = timestamp

        with self._connect() as connection:
            connection.execute(
                """
                update missions
                set status = ?, notes = ?, progress_pct = ?, updated_at = ?,
                    completed_at = ?
                where mission_id = ?
                """,
                (
                    status,
                    notes if notes is not None else mission["notes"],
                    progress_pct
                    if progress_pct is not None
                    else mission["progressPct"],
                    timestamp,
                    completed_at,
                    mission_id,
                ),
            )
            connection.commit()
        return self.get_mission(mission_id)

    def sync_progress(self, mission_id, progress_pct):
        mission = self.get_mission(mission_id)
        if not mission or mission["status"] in self.TERMINAL_MISSION_STATUSES:
            return mission
        return self.transition_mission(
            mission_id,
            mission["status"],
            progress_pct=max(0, min(int(progress_pct), 100)),
        )
