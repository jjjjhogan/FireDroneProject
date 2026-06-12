import json
from datetime import datetime, timezone
from pathlib import Path


def utc_now():
    return datetime.now(timezone.utc).replace(microsecond=0)


def utc_now_iso():
    return utc_now().isoformat()


class DjiStateStore:
    def __init__(self, path, ttl_seconds=300):
        self.path = Path(path)
        self.ttl_seconds = int(ttl_seconds)

    def read(self):
        if not self.path.exists():
            return None
        try:
            with self.path.open("r", encoding="utf-8") as file:
                return json.load(file)
        except (OSError, json.JSONDecodeError):
            return None

    def write(self, payload):
        state = {
            "source": payload.get("source") or "operator-bridge",
            "receivedAt": utc_now_iso(),
            "bridge": payload.get("bridge") or {},
            "drones": payload.get("drones") or [],
            "telemetry": payload.get("telemetry") or {},
            "warnings": payload.get("warnings") or [],
        }
        return self.write_state(state)

    def write_state(self, state):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temp_path = self.path.with_suffix(f"{self.path.suffix}.tmp")
        with temp_path.open("w", encoding="utf-8") as file:
            json.dump(state, file, indent=2, sort_keys=True)
        temp_path.replace(self.path)
        return state

    def age_seconds(self, state):
        if not state or not state.get("receivedAt"):
            return None
        try:
            received_at = datetime.fromisoformat(state["receivedAt"])
        except ValueError:
            return None
        if received_at.tzinfo is None:
            received_at = received_at.replace(tzinfo=timezone.utc)
        age = utc_now() - received_at
        return age.total_seconds()

    def is_fresh(self, state):
        age = self.age_seconds(state)
        if age is None:
            return False
        return age <= self.ttl_seconds
