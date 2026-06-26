import os
import sys
import time
from dataclasses import dataclass

from app.dji.cloud_mqtt_relay import (
    CloudIngestError,
    RateLimitedLogger,
    RelayStats,
    post_cloud_ingest,
)
from app.dji.demo_patrol import (
    FIRE_PERIMETER_MISSION,
    build_cloud_osd_payload,
    cloud_osd_topic,
)


@dataclass
class DemoIngestConfig:
    ingest_token: str
    api_base: str = "http://127.0.0.1:5000/api"
    device_id: str = "demo-aircraft"
    interval_seconds: float = 45.0
    ticks_per_leg: int = 6
    http_timeout_seconds: float = 8.0
    log_interval_seconds: float = 30.0
    verbose: bool = False
    once: bool = False


def _env_bool(key, default=False):
    value = str(os.getenv(key, "")).strip().lower()
    if not value:
        return default
    return value in {"1", "true", "yes", "on"}


def demo_ingest_config_from_env():
    return DemoIngestConfig(
        ingest_token=str(os.getenv("DJI_INGEST_TOKEN", "")).strip(),
        api_base=str(
            os.getenv("FIRE_DRONE_API_BASE", "http://127.0.0.1:5000/api")
        ).strip(),
        device_id=str(os.getenv("DJI_DEMO_DEVICE_ID", "demo-aircraft")).strip(),
        interval_seconds=float(os.getenv("DJI_DEMO_INTERVAL_SECONDS", "45")),
        ticks_per_leg=int(os.getenv("DJI_DEMO_TICKS_PER_LEG", "6")),
        verbose=_env_bool("DJI_DEMO_VERBOSE"),
        once=_env_bool("DJI_DEMO_ONCE"),
    )


def validate_demo_config(config: DemoIngestConfig) -> list[str]:
    errors = []
    if not config.ingest_token:
        errors.append("DJI_INGEST_TOKEN or --token is required")
    if not config.api_base:
        errors.append("FIRE_DRONE_API_BASE or --api-base is required")
    if not config.device_id:
        errors.append("DJI_DEMO_DEVICE_ID or --device-id is required")
    if config.interval_seconds < 1:
        errors.append("interval must be at least 1 second")
    return errors


def run_demo_ingest_worker(config: DemoIngestConfig):
    errors = validate_demo_config(config)
    if errors:
        for message in errors:
            print(message, file=sys.stderr)
        return 2

    stats = RelayStats()
    logger = RateLimitedLogger(
        interval_seconds=config.log_interval_seconds,
        verbose=config.verbose,
    )
    topic = cloud_osd_topic(config.device_id)
    legs = len(FIRE_PERIMETER_MISSION) - 1
    loop_min = (legs * config.ticks_per_leg * config.interval_seconds) / 60

    logger.info(
        f"[demo] HTTP patrol ingest -> {config.api_base} "
        f"device={config.device_id} interval={config.interval_seconds}s "
        f"(~{loop_min:.0f} min/loop, no MQTT broker required)"
    )

    sequence = 0
    try:
        while True:
            sequence += 1
            stats.messages_received += 1
            payload = build_cloud_osd_payload(
                config.device_id,
                sequence,
                config.ticks_per_leg,
            )
            demo = payload.pop("_demo", {})
            stats.last_topic = topic
            try:
                status, response_body = post_cloud_ingest(
                    config.api_base,
                    config.ingest_token,
                    topic,
                    payload,
                    timeout_seconds=config.http_timeout_seconds,
                )
                stats.forwarded_ok += 1
                stats.last_http_status = status
                stats.last_error = ""
                if config.verbose:
                    data = payload["data"]
                    logger.info(
                        f"[demo] posted #{sequence} HTTP {status} "
                        f"({data['latitude']:.4f}, {data['longitude']:.4f}) "
                        f"[{demo.get('waypoint', '?')} "
                        f"{demo.get('routeProgressPct', 0)}%] "
                        f"{response_body[:120]}"
                    )
            except CloudIngestError as error:
                stats.forward_failed += 1
                stats.last_http_status = error.status_code
                stats.last_error = str(error)
                logger.error(f"[demo] ingest rejected: {error}")
            except (OSError, TimeoutError) as error:
                stats.forward_failed += 1
                stats.last_error = str(error)
                logger.error(f"[demo] ingest unreachable: {error}")

            logger.maybe_summary(stats)

            if config.once:
                break
            time.sleep(config.interval_seconds)
    except KeyboardInterrupt:
        logger.info("[demo] stopped")

    return 0 if stats.forwarded_ok > 0 or config.once else 1
