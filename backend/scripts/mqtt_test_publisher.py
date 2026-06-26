#!/usr/bin/env python3
"""Publish synthetic DJI Cloud API OSD messages for local EMQX development.

Simulates a fire-perimeter patrol: takeoff, ridge thermal scan, flank inspect,
containment check, and return-to-launch — not a fixed hover point.
"""
import argparse
import json
import os
import ssl
import sys
import time
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

try:
    from dotenv import load_dotenv

    load_dotenv(BACKEND_DIR / ".env")
except ImportError:
    pass

from app.dji.demo_patrol import FIRE_PERIMETER_MISSION, build_cloud_osd_payload


def _parse_args():
    parser = argparse.ArgumentParser(
        description="Republish synthetic DJI OSD messages to a local MQTT broker."
    )
    parser.add_argument(
        "--mqtt-host",
        default=os.getenv("DJI_CLOUD_API_MQTT_HOST", "127.0.0.1"),
    )
    parser.add_argument(
        "--mqtt-port",
        type=int,
        default=int(os.getenv("DJI_CLOUD_MQTT_PORT", "1883")),
    )
    parser.add_argument(
        "--mqtt-username",
        default=os.getenv("DJI_CLOUD_MQTT_USERNAME", ""),
    )
    parser.add_argument(
        "--mqtt-password",
        default=os.getenv("DJI_CLOUD_MQTT_PASSWORD", ""),
    )
    parser.add_argument(
        "--device-id",
        default="demo-aircraft",
        help="Aircraft id used in thing/product/{device-id}/osd",
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=60,
        help="Seconds between publishes (default 60, under 300s TTL)",
    )
    parser.add_argument(
        "--ticks-per-leg",
        type=int,
        default=6,
        help="OSD publishes per route leg (default 6)",
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Publish one message and exit",
    )
    parser.add_argument(
        "--no-tls",
        action="store_true",
        help="Disable TLS for local Docker EMQX (also set DJI_CLOUD_MQTT_USE_TLS=false in .env)",
    )
    return parser.parse_args()


def _use_tls(args):
    if args.no_tls:
        return False
    env_value = str(os.getenv("DJI_CLOUD_MQTT_USE_TLS", "")).strip().lower()
    if env_value in {"0", "false", "no", "off"}:
        return False
    if env_value in {"1", "true", "yes", "on"}:
        return True
    return args.mqtt_port != 1883


def main():
    args = _parse_args()
    host = str(args.mqtt_host).strip()
    if not host:
        print("DJI_CLOUD_API_MQTT_HOST or --mqtt-host is required", file=sys.stderr)
        return 2

    try:
        import paho.mqtt.client as mqtt
    except ImportError:
        print(
            "Missing paho-mqtt. Run: pip install -r backend/requirements.txt",
            file=sys.stderr,
        )
        return 2

    topic = f"thing/product/{args.device_id}/osd"
    use_tls = _use_tls(args)
    callback_version = getattr(mqtt, "CallbackAPIVersion", None)
    client_id = f"firedrone-test-publisher-{args.device_id}"
    if callback_version is not None:
        client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=client_id)
    else:
        client = mqtt.Client(client_id=client_id)
    if args.mqtt_username or args.mqtt_password:
        client.username_pw_set(args.mqtt_username, args.mqtt_password)
    if use_tls:
        client.tls_set(cert_reqs=ssl.CERT_REQUIRED)

    legs = len(FIRE_PERIMETER_MISSION) - 1
    loop_min = (legs * args.ticks_per_leg * args.interval) / 60
    scheme = "mqtts" if use_tls else "mqtt"
    print(f"Connecting to {scheme}://{host}:{args.mqtt_port} ...")
    print(
        f"Mission: {FIRE_PERIMETER_MISSION[0]['label']} -> "
        f"{FIRE_PERIMETER_MISSION[-1]['label']} "
        f"({legs} legs, ~{loop_min:.0f} min/loop @ {args.interval}s interval)"
    )
    client.connect(host, args.mqtt_port, keepalive=60)
    client.loop_start()

    sequence = 0
    try:
        while True:
            sequence += 1
            payload = build_cloud_osd_payload(
                args.device_id,
                sequence,
                args.ticks_per_leg,
            )
            demo = payload.pop("_demo", {})
            client.publish(topic, json.dumps(payload))
            data = payload["data"]
            print(
                f"Published #{sequence} -> {topic} "
                f"({data['latitude']:.4f}, {data['longitude']:.4f}) "
                f"alt={data['height']}m "
                f"[{demo.get('waypoint', '?')} {demo.get('routeProgressPct', 0)}%]"
            )
            if args.once:
                break
            time.sleep(max(args.interval, 1))
    except KeyboardInterrupt:
        print("\nStopped.")
    finally:
        client.loop_stop()
        client.disconnect()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
