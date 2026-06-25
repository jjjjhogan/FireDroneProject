import json
import ssl
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field


DEFAULT_TOPICS = ("thing/product/+/osd", "thing/product/+/state")


@dataclass
class RelayConfig:
    mqtt_host: str
    ingest_token: str
    api_base: str = "http://127.0.0.1:5000/api"
    mqtt_port: int = 8883
    mqtt_username: str = ""
    mqtt_password: str = ""
    mqtt_client_id: str = "firedrone-cloud-worker"
    topics: tuple[str, ...] = DEFAULT_TOPICS
    use_tls: bool = True
    http_timeout_seconds: float = 8.0
    log_interval_seconds: float = 30.0
    verbose: bool = False


@dataclass
class RelayStats:
    messages_received: int = 0
    forwarded_ok: int = 0
    forward_failed: int = 0
    bad_payload: int = 0
    last_topic: str = ""
    last_http_status: int = 0
    last_error: str = ""
    started_at: float = field(default_factory=time.time)

    def summary(self) -> str:
        uptime = max(0, int(time.time() - self.started_at))
        return (
            f"uptime={uptime}s received={self.messages_received} "
            f"ok={self.forwarded_ok} failed={self.forward_failed} "
            f"bad_json={self.bad_payload}"
        )


class RateLimitedLogger:
    def __init__(self, interval_seconds=30.0, verbose=False):
        self.interval_seconds = max(1.0, float(interval_seconds))
        self.verbose = verbose
        self._last_summary_at = 0.0

    def info(self, message):
        print(message, flush=True)

    def error(self, message):
        print(message, file=__import__("sys").stderr, flush=True)

    def maybe_summary(self, stats: RelayStats):
        if self.verbose:
            return
        now = time.time()
        if now - self._last_summary_at < self.interval_seconds:
            return
        self._last_summary_at = now
        suffix = f" last_topic={stats.last_topic}" if stats.last_topic else ""
        if stats.last_error:
            suffix += f" last_error={stats.last_error}"
        self.info(f"[relay] {stats.summary()}{suffix}")


def validate_relay_config(config: RelayConfig) -> list[str]:
    errors = []
    if not str(config.mqtt_host or "").strip():
        errors.append("DJI_CLOUD_API_MQTT_HOST or --mqtt-host is required")
    if not str(config.ingest_token or "").strip():
        errors.append("DJI_INGEST_TOKEN or --token is required")
    if not str(config.api_base or "").strip():
        errors.append("FIRE_DRONE_API_BASE or --api-base is required")
    if not config.topics:
        errors.append("At least one MQTT topic is required")
    return errors


def post_cloud_ingest(
    api_base,
    token,
    topic,
    payload,
    *,
    timeout_seconds=8.0,
):
    body = json.dumps({"topic": topic, "payload": payload}).encode("utf-8")
    request = urllib.request.Request(
        f"{str(api_base).rstrip('/')}/dji/ingest/cloud-api",
        data=body,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
            status = response.status
            response_body = response.read().decode("utf-8")
    except urllib.error.HTTPError as error:
        status = error.code
        try:
            response_body = error.read().decode("utf-8")
        except (OSError, UnicodeDecodeError):
            response_body = str(error)
        raise CloudIngestError(status, response_body) from error
    return status, response_body


class CloudIngestError(Exception):
    def __init__(self, status_code, body):
        super().__init__(f"HTTP {status_code}: {body}")
        self.status_code = status_code
        self.body = body


def mqtt_reason_succeeded(reason_code):
    if reason_code is None:
        return True
    if hasattr(reason_code, "is_success"):
        return bool(reason_code.is_success)
    try:
        return int(reason_code) == 0
    except (TypeError, ValueError):
        if hasattr(reason_code, "value"):
            return int(reason_code.value) == 0
    return False


def mqtt_reason_label(reason_code):
    return str(reason_code)


def relay_config_from_env(env=None):
    import os

    env = env or os.environ
    topics = [
        item.strip()
        for item in str(env.get("DJI_CLOUD_MQTT_TOPICS", "")).split(",")
        if item.strip()
    ]
    use_tls = str(env.get("DJI_CLOUD_MQTT_USE_TLS", "true")).strip().lower() in {
        "1",
        "true",
        "yes",
        "on",
    }
    return RelayConfig(
        mqtt_host=str(env.get("DJI_CLOUD_API_MQTT_HOST", "")).strip(),
        ingest_token=str(env.get("DJI_INGEST_TOKEN", "")).strip(),
        api_base=str(
            env.get("FIRE_DRONE_API_BASE", "http://127.0.0.1:5000/api")
        ).strip(),
        mqtt_port=int(env.get("DJI_CLOUD_MQTT_PORT", "8883")),
        mqtt_username=str(env.get("DJI_CLOUD_MQTT_USERNAME", "")).strip(),
        mqtt_password=str(env.get("DJI_CLOUD_MQTT_PASSWORD", "")),
        mqtt_client_id=str(
            env.get("DJI_CLOUD_MQTT_CLIENT_ID", "firedrone-cloud-worker")
        ).strip(),
        topics=tuple(topics) if topics else DEFAULT_TOPICS,
        use_tls=use_tls,
    )


def run_cloud_mqtt_relay(config: RelayConfig):
    import sys

    errors = validate_relay_config(config)
    if errors:
        for message in errors:
            print(message, file=sys.stderr)
        return 2

    try:
        import paho.mqtt.client as mqtt
    except ImportError:
        print(
            "Missing paho-mqtt. Install backend requirements before running this worker.",
            file=sys.stderr,
        )
        return 2

    stats = RelayStats()
    logger = RateLimitedLogger(
        interval_seconds=config.log_interval_seconds,
        verbose=config.verbose,
    )

    def on_connect(client, userdata, flags, reason_code, properties=None):
        del userdata, flags, properties
        if not mqtt_reason_succeeded(reason_code):
            stats.last_error = f"MQTT connect failed rc={mqtt_reason_label(reason_code)}"
            logger.error(f"[relay] {stats.last_error}")
            return
        for topic in config.topics:
            client.subscribe(topic)
        logger.info(
            f"[relay] connected to {config.mqtt_host}:{config.mqtt_port} "
            f"topics={','.join(config.topics)} api={config.api_base}"
        )

    def on_disconnect(client, userdata, disconnect_flags, reason_code, properties=None):
        del client, userdata, disconnect_flags, properties
        if mqtt_reason_succeeded(reason_code):
            return
        stats.last_error = f"MQTT disconnected rc={mqtt_reason_label(reason_code)}"
        logger.error(f"[relay] {stats.last_error}; paho will retry")

    def on_message(client, userdata, message):
        del client, userdata
        stats.messages_received += 1
        stats.last_topic = message.topic
        try:
            payload = json.loads(message.payload.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError) as error:
            stats.bad_payload += 1
            stats.last_error = str(error)
            logger.error(f"[relay] bad MQTT JSON on {message.topic}: {error}")
            return

        try:
            status, response_body = post_cloud_ingest(
                config.api_base,
                config.ingest_token,
                message.topic,
                payload,
                timeout_seconds=config.http_timeout_seconds,
            )
            stats.forwarded_ok += 1
            stats.last_http_status = status
            stats.last_error = ""
            if config.verbose:
                logger.info(
                    f"[relay] forwarded {message.topic} -> HTTP {status} "
                    f"{response_body[:160]}"
                )
        except CloudIngestError as error:
            stats.forward_failed += 1
            stats.last_http_status = error.status_code
            stats.last_error = str(error)
            logger.error(f"[relay] ingest rejected for {message.topic}: {error}")
        except (urllib.error.URLError, TimeoutError) as error:
            stats.forward_failed += 1
            stats.last_error = str(error)
            logger.error(f"[relay] ingest unreachable for {message.topic}: {error}")

        logger.maybe_summary(stats)

    callback_version = getattr(mqtt, "CallbackAPIVersion", None)
    if callback_version is not None:
        client = mqtt.Client(
            mqtt.CallbackAPIVersion.VERSION2,
            client_id=config.mqtt_client_id,
        )
    else:
        client = mqtt.Client(client_id=config.mqtt_client_id)

    if config.mqtt_username or config.mqtt_password:
        client.username_pw_set(config.mqtt_username, config.mqtt_password)
    if config.use_tls:
        client.tls_set(cert_reqs=ssl.CERT_REQUIRED)

    client.reconnect_delay_set(min_delay=1, max_delay=120)
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_message = on_message

    logger.info(
        f"[relay] starting worker client_id={config.mqtt_client_id} "
        f"target={config.mqtt_host}:{config.mqtt_port} tls={config.use_tls} "
        f"api={config.api_base}"
    )
    try:
        client.connect_async(config.mqtt_host, config.mqtt_port, keepalive=60)
        client.loop_forever()
    except KeyboardInterrupt:
        logger.info("[relay] stopped")
        client.loop_stop()
        client.disconnect()
    return 0
