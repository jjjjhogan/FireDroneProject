import json
import ssl
import threading

from app.dji.cloud_api import cloud_api_message_to_ingest_payload
from app.dji.ingest import normalize_ingest_payload
from app.dji.state_store import DjiStateStore, utc_now_iso


class CloudMqttBridgeManager:
    def __init__(self):
        self._lock = threading.Lock()
        self._client = None
        self._status = {
            "running": False,
            "state": "stopped",
            "lastError": None,
            "lastMessageAt": None,
            "subscribedTopics": [],
            "host": "",
        }

    def status(self):
        with self._lock:
            return dict(self._status)

    def stop(self):
        with self._lock:
            client = self._client
            self._client = None
            self._status = {
                **self._status,
                "running": False,
                "state": "stopped",
            }
        if client is not None:
            client.loop_stop()
            client.disconnect()

    def start(self, config):
        host = str(config.get("DJI_CLOUD_API_MQTT_HOST", "")).strip()
        token = str(config.get("DJI_INGEST_TOKEN", "")).strip()
        if not host or not token:
            with self._lock:
                self._status = {
                    **self._status,
                    "running": False,
                    "state": "missing-config",
                    "lastError": "MQTT host and ingest token are required.",
                    "host": host,
                }
            return self.status()

        try:
            import paho.mqtt.client as mqtt
        except ImportError:
            with self._lock:
                self._status = {
                    **self._status,
                    "running": False,
                    "state": "missing-dependency",
                    "lastError": "Install paho-mqtt to start Cloud API bridge.",
                    "host": host,
                }
            return self.status()

        self.stop()

        port = int(config.get("DJI_CLOUD_MQTT_PORT", 8883))
        username = str(config.get("DJI_CLOUD_MQTT_USERNAME", "")).strip()
        password = str(config.get("DJI_CLOUD_MQTT_PASSWORD", ""))
        client_id = str(
            config.get("DJI_CLOUD_MQTT_CLIENT_ID", "firedrone-web-connector")
        ).strip()
        topics = ["thing/product/+/osd", "thing/product/+/state"]
        state_file = config.get("DJI_STATE_FILE", "instance/dji_state.json")
        ttl_seconds = config.get("DJI_TELEMETRY_TTL_SECONDS", 300)
        max_drones = config.get("DJI_MAX_INGEST_DRONES", 16)
        store = DjiStateStore(state_file, ttl_seconds)

        client = mqtt.Client(client_id=client_id)
        if username or password:
            client.username_pw_set(username, password)
        use_tls = config.get("DJI_CLOUD_MQTT_USE_TLS", True)
        if isinstance(use_tls, str):
            use_tls = use_tls.strip().lower() in {"1", "true", "yes", "on"}
        if use_tls:
            client.tls_set(cert_reqs=ssl.CERT_REQUIRED)

        def on_connect(client, userdata, flags, reason_code):
            if int(reason_code) != 0:
                with self._lock:
                    self._status = {
                        **self._status,
                        "state": "connect-failed",
                        "lastError": f"MQTT connect failed rc={reason_code}",
                    }
                return
            for topic in topics:
                client.subscribe(topic)
            with self._lock:
                self._status = {
                    **self._status,
                    "running": True,
                    "state": "subscribed",
                    "lastError": None,
                    "subscribedTopics": topics,
                }

        def on_message(client, userdata, message):
            try:
                raw_payload = json.loads(message.payload.decode("utf-8"))
                ingest_payload = cloud_api_message_to_ingest_payload(
                    {"topic": message.topic, "payload": raw_payload}
                )
                normalized = normalize_ingest_payload(
                    ingest_payload,
                    received_at=utc_now_iso(),
                    max_drones=max_drones,
                )
                if normalized["accepted"]:
                    store.write_state(normalized["state"])
                with self._lock:
                    self._status = {
                        **self._status,
                        "lastMessageAt": utc_now_iso(),
                        "lastError": None if normalized["accepted"] else "; ".join(normalized["errors"]),
                    }
            except Exception as error:
                with self._lock:
                    self._status = {
                        **self._status,
                        "lastError": str(error),
                    }

        client.on_connect = on_connect
        client.on_message = on_message
        client.connect_async(host, port, keepalive=60)
        client.loop_start()

        with self._lock:
            self._client = client
            self._status = {
                "running": True,
                "state": "starting",
                "lastError": None,
                "lastMessageAt": None,
                "subscribedTopics": topics,
                "host": host,
            }
        return self.status()


cloud_bridge_manager = CloudMqttBridgeManager()


def _bridge_min_config_ready(config, *, mode="cloud-api"):
    if mode == "mobile-sdk":
        return False
    host = str(config.get("DJI_CLOUD_API_MQTT_HOST", "")).strip()
    token = str(config.get("DJI_INGEST_TOKEN", "")).strip()
    return bool(host and token)


def try_start_cloud_bridge(app_config, runtime_store):
    runtime = runtime_store.read()
    mode = runtime.get("mode") or "cloud-api"
    if mode == "mobile-sdk":
        return cloud_bridge_manager.status()
    effective = runtime_store.effective_config(app_config)
    if not _bridge_min_config_ready(effective, mode=mode):
        return cloud_bridge_manager.status()
    return cloud_bridge_manager.start(effective)


def init_auto_start_cloud_bridge(app):
    if not app.config.get("DJI_AUTO_START_CLOUD_BRIDGE"):
        return
    from app.dji.runtime_config import DjiRuntimeConfigStore

    store = DjiRuntimeConfigStore(
        app.config.get(
            "DJI_RUNTIME_CONFIG_FILE",
            "instance/dji_runtime_config.json",
        )
    )
    try_start_cloud_bridge(app.config, store)
