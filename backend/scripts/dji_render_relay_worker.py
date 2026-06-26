#!/usr/bin/env python3
"""Render / production entrypoint for the DJI cloud relay.

Modes (auto-selected):
  DJI_DEMO_INGEST=true  -> HTTP patrol demo (no MQTT broker; good for Render worker)
  DJI_CLOUD_API_MQTT_HOST set -> MQTT relay to DJI or EMQX
"""
import argparse
import os
import sys
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from dotenv import load_dotenv

from app.dji.cloud_mqtt_relay import relay_config_from_env, run_cloud_mqtt_relay
from app.dji.demo_ingest_worker import (
    DemoIngestConfig,
    demo_ingest_config_from_env,
    run_demo_ingest_worker,
)
from app.dji.demo_scenarios import DEFAULT_DEMO_SCENARIO_ID, scenario_ids


def _load_env_file(path):
    env_path = Path(path)
    if env_path.exists():
        load_dotenv(env_path, override=False)


def _env_bool(key):
    return str(os.getenv(key, "")).strip().lower() in {"1", "true", "yes", "on"}


def _should_run_demo_ingest(mqtt_host):
    if _env_bool("DJI_DEMO_INGEST"):
        return True
    if _env_bool("DJI_FORCE_MQTT_RELAY"):
        return False
    return not str(mqtt_host or "").strip()


def _parse_demo_args(env_config):
    parser = argparse.ArgumentParser(
        description="FireDrone DJI cloud relay worker (Render demo or MQTT)."
    )
    parser.add_argument("--api-base", default=env_config.api_base)
    parser.add_argument("--token", default=env_config.ingest_token)
    parser.add_argument("--device-id", default=env_config.device_id)
    parser.add_argument(
        "--scenario",
        choices=scenario_ids(),
        default=env_config.scenario_id or DEFAULT_DEMO_SCENARIO_ID,
        help="Demo scenario route to publish.",
    )
    parser.add_argument("--interval", type=float, default=env_config.interval_seconds)
    parser.add_argument(
        "--ticks-per-leg",
        type=int,
        default=env_config.ticks_per_leg,
        help="OSD publishes per route leg.",
    )
    parser.add_argument("--once", action="store_true", default=env_config.once)
    parser.add_argument("--verbose", action="store_true", default=env_config.verbose)
    parser.add_argument(
        "--demo",
        action="store_true",
        help="Force HTTP demo ingest (no MQTT).",
    )
    parser.add_argument(
        "--env-file",
        default=str(BACKEND_DIR / ".env"),
        help="Optional .env file (default: backend/.env).",
    )
    return parser.parse_args()


def main():
    _load_env_file(BACKEND_DIR / ".env")
    env_config = demo_ingest_config_from_env()
    mqtt_config = relay_config_from_env()
    args = _parse_demo_args(env_config)
    _load_env_file(args.env_file)

    env_config = demo_ingest_config_from_env()
    mqtt_config = relay_config_from_env()

    use_demo = args.demo or _should_run_demo_ingest(mqtt_config.mqtt_host)
    if use_demo:
        config = DemoIngestConfig(
            ingest_token=str(args.token or env_config.ingest_token).strip(),
            api_base=str(args.api_base or env_config.api_base).strip(),
            device_id=str(args.device_id or env_config.device_id).strip(),
            scenario_id=str(args.scenario or env_config.scenario_id).strip(),
            interval_seconds=max(1.0, float(args.interval)),
            ticks_per_leg=max(1, int(args.ticks_per_leg)),
            verbose=bool(args.verbose or env_config.verbose),
            once=bool(args.once or env_config.once),
        )
        return run_demo_ingest_worker(config)

    from app.dji.cloud_mqtt_relay import validate_relay_config

    errors = validate_relay_config(mqtt_config)
    if errors:
        print(
            "MQTT relay not configured. Set DJI_DEMO_INGEST=true for HTTP demo, "
            "or provide DJI_CLOUD_API_MQTT_HOST + DJI_INGEST_TOKEN.",
            file=sys.stderr,
        )
        for message in errors:
            print(message, file=sys.stderr)
        return 2

    return run_cloud_mqtt_relay(mqtt_config)


if __name__ == "__main__":
    raise SystemExit(main())
