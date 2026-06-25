#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from dotenv import load_dotenv

from app.dji.cloud_mqtt_relay import (
    DEFAULT_TOPICS,
    RelayConfig,
    relay_config_from_env,
    run_cloud_mqtt_relay,
    validate_relay_config,
)


def _load_env_file(path):
    env_path = Path(path)
    if env_path.exists():
        load_dotenv(env_path, override=False)


def _parse_args(env_config):
    parser = argparse.ArgumentParser(
        description=(
            "Subscribe to DJI Cloud API MQTT topics and forward device "
            "messages to FireDrone HTTP ingest."
        )
    )
    parser.add_argument("--mqtt-host", default=env_config.mqtt_host)
    parser.add_argument("--mqtt-port", type=int, default=env_config.mqtt_port)
    parser.add_argument("--mqtt-username", default=env_config.mqtt_username)
    parser.add_argument("--mqtt-password", default=env_config.mqtt_password)
    parser.add_argument(
        "--mqtt-client-id",
        default=env_config.mqtt_client_id,
    )
    parser.add_argument(
        "--topic",
        action="append",
        default=None,
        help="MQTT topic to subscribe. Repeat for multiple topics.",
    )
    parser.add_argument("--api-base", default=env_config.api_base)
    parser.add_argument("--token", default=env_config.ingest_token)
    parser.add_argument(
        "--no-tls",
        action="store_true",
        help="Disable TLS for local MQTT testing only.",
    )
    parser.add_argument(
        "--log-interval",
        type=float,
        default=30.0,
        help="Seconds between summary log lines (default: 30).",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Log every forwarded MQTT message.",
    )
    parser.add_argument(
        "--env-file",
        default=str(BACKEND_DIR / ".env"),
        help="Optional .env file to load before starting (default: backend/.env).",
    )
    return parser.parse_args()


def _build_config(args, env_config):
    topics = tuple(args.topic) if args.topic else env_config.topics
    use_tls = env_config.use_tls and not args.no_tls
    return RelayConfig(
        mqtt_host=str(args.mqtt_host or "").strip(),
        ingest_token=str(args.token or "").strip(),
        api_base=str(args.api_base or "").strip(),
        mqtt_port=args.mqtt_port,
        mqtt_username=str(args.mqtt_username or "").strip(),
        mqtt_password=str(args.mqtt_password or ""),
        mqtt_client_id=str(args.mqtt_client_id or "").strip() or "firedrone-cloud-worker",
        topics=topics,
        use_tls=use_tls,
        log_interval_seconds=max(1.0, float(args.log_interval)),
        verbose=bool(args.verbose),
    )


def main():
    _load_env_file(BACKEND_DIR / ".env")
    env_config = relay_config_from_env()
    args = _parse_args(env_config)
    _load_env_file(args.env_file)
    env_config = relay_config_from_env()

    config = _build_config(args, env_config)
    errors = validate_relay_config(config)
    if errors:
        for message in errors:
            print(message, file=sys.stderr)
        return 2

    return run_cloud_mqtt_relay(config)


if __name__ == "__main__":
    raise SystemExit(main())
