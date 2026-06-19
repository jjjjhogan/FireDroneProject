import json
from pathlib import Path

from app.dji.state_store import utc_now_iso


SECRET_KEYS = {
    "DJI_INGEST_TOKEN",
    "DJI_CLOUD_MQTT_PASSWORD",
    "DJI_CLOUD_API_APP_KEY",
    "DJI_CLOUD_API_APP_LICENSE",
}


def _clean_string(value, default="", max_length=240):
    if value is None:
        return default
    text = str(value).strip()
    if not text:
        return default
    return text[:max_length]


def _int_value(value, default):
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _port_value(payload_port, existing_port, default=8883):
    if payload_port in (None, "", 0):
        return _int_value(existing_port, default)
    return _int_value(payload_port, default)


class DjiRuntimeConfigStore:
    def __init__(self, path):
        self.path = Path(path)

    def read(self):
        if not self.path.exists():
            return {}
        try:
            with self.path.open("r", encoding="utf-8") as file:
                data = json.load(file)
        except (OSError, json.JSONDecodeError):
            return {}
        return data if isinstance(data, dict) else {}

    def write_from_payload(self, payload):
        payload = payload if isinstance(payload, dict) else {}
        existing = self.read()
        mode = _clean_string(payload.get("mode"), existing.get("mode") or "cloud-api")
        if mode not in {"cloud-api", "mobile-sdk"}:
            raise ValueError("mode must be cloud-api or mobile-sdk")

        updated = {
            **existing,
            "mode": mode,
            "operatorLabel": _clean_string(
                payload.get("operatorLabel"),
                existing.get("operatorLabel", ""),
            ),
            "DJI_CLOUD_API_APP_ID": _clean_string(
                payload.get("cloudApiAppId"),
                existing.get("DJI_CLOUD_API_APP_ID", ""),
            ),
            "DJI_WORKSPACE_ID": _clean_string(
                payload.get("workspaceId"),
                existing.get("DJI_WORKSPACE_ID", ""),
            ),
            "DJI_CLOUD_API_MQTT_HOST": _clean_string(
                payload.get("cloudMqttHost"),
                existing.get("DJI_CLOUD_API_MQTT_HOST", ""),
            ),
            "DJI_CLOUD_MQTT_PORT": _port_value(
                payload.get("cloudMqttPort"),
                existing.get("DJI_CLOUD_MQTT_PORT", 8883),
            ),
            "DJI_CLOUD_MQTT_USERNAME": _clean_string(
                payload.get("cloudMqttUsername"),
                existing.get("DJI_CLOUD_MQTT_USERNAME", ""),
            ),
            "DJI_CLOUD_MQTT_CLIENT_ID": _clean_string(
                payload.get("cloudMqttClientId"),
                existing.get("DJI_CLOUD_MQTT_CLIENT_ID", "firedrone-web-connector"),
            ),
            "updatedAt": utc_now_iso(),
        }

        for payload_key, config_key in [
            ("ingestToken", "DJI_INGEST_TOKEN"),
            ("cloudMqttPassword", "DJI_CLOUD_MQTT_PASSWORD"),
            ("cloudApiAppKey", "DJI_CLOUD_API_APP_KEY"),
            ("cloudApiAppLicense", "DJI_CLOUD_API_APP_LICENSE"),
        ]:
            value = _clean_string(payload.get(payload_key), max_length=500)
            if value:
                updated[config_key] = value
            elif config_key in existing:
                updated[config_key] = existing[config_key]

        self.path.parent.mkdir(parents=True, exist_ok=True)
        temp_path = self.path.with_suffix(f"{self.path.suffix}.tmp")
        with temp_path.open("w", encoding="utf-8") as file:
            json.dump(updated, file, indent=2, sort_keys=True)
        temp_path.replace(self.path)
        return updated

    def effective_config(self, base_config):
        effective = dict(base_config)
        for key, value in self.read().items():
            if key == "mode" or key == "operatorLabel" or key == "updatedAt":
                continue
            if value not in (None, ""):
                effective[key] = value
        return effective

    def public_config(self, base_url=""):
        config = self.read()
        mode = config.get("mode") or "not-configured"
        ingest_configured = bool(config.get("DJI_INGEST_TOKEN"))
        cloud_host_configured = bool(config.get("DJI_CLOUD_API_MQTT_HOST"))
        configured = ingest_configured and (
            mode == "mobile-sdk" or (mode == "cloud-api" and cloud_host_configured)
        )
        mobile_endpoint = ""
        if base_url:
            mobile_endpoint = f"{base_url.rstrip('/')}/api/dji/ingest/mobile-sdk"
        return {
            "configured": configured,
            "mode": mode,
            "operatorLabel": config.get("operatorLabel", ""),
            "ingestTokenConfigured": ingest_configured,
            "cloudMqttHostConfigured": cloud_host_configured,
            "cloudMqttUsernameConfigured": bool(config.get("DJI_CLOUD_MQTT_USERNAME")),
            "cloudMqttClientId": config.get("DJI_CLOUD_MQTT_CLIENT_ID", ""),
            "workspaceIdConfigured": bool(config.get("DJI_WORKSPACE_ID")),
            "appIdConfigured": bool(config.get("DJI_CLOUD_API_APP_ID")),
            "mobileBridgeEndpoint": mobile_endpoint,
            "updatedAt": config.get("updatedAt"),
        }
