#!/usr/bin/env python3
"""Publish synthetic DJI Cloud API OSD messages for local EMQX development.

Keeps the in-app Cloud MQTT bridge from going bridge-stale during demos by
republishing telemetry before DJI_TELEMETRY_TTL_SECONDS expires.
"""
import argparse
import json
import os
import ssl
import sys
import time
from pathlib import Path

try:
    from dotenv import load_dotenv

    load_dotenv(Path(__file__).resolve().parents[1] / ".env")
except ImportError:
    pass


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
        "--once",
        action="store_true",
        help="Publish one message and exit",
    )
    parser.add_argument(
        "--no-tls",
        action="store_true",
        help="Disable TLS for local Docker EMQX",
    )
    return parser.parse_args()


def _build_payload(device_id, sequence):
    base_lat = 37.21
    base_lng = -119.54
    offset = (sequence % 10) * 0.0001
    return {
        "data": {
            "latitude": base_lat + offset,
            "longitude": base_lng + offset,
            "height": 118 + (sequence % 5),
            "battery": {"capacity_percent": max(70, 90 - (sequence % 8))},
            "device_id": device_id,
        }
    }


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
    client = mqtt.Client(client_id=f"firedrone-test-publisher-{args.device_id}")
    if args.mqtt_username or args.mqtt_password:
        client.username_pw_set(args.mqtt_username, args.mqtt_password)
    if not args.no_tls:
        client.tls_set(cert_reqs=ssl.CERT_REQUIRED)

    print(f"Connecting to mqtt://{host}:{args.mqtt_port} ...")
    client.connect(host, args.mqtt_port, keepalive=60)
    client.loop_start()

    sequence = 0
    try:
        while True:
            sequence += 1
            payload = _build_payload(args.device_id, sequence)
            client.publish(topic, json.dumps(payload))
            print(
                f"Published #{sequence} -> {topic} "
                f"({payload['data']['latitude']:.4f}, {payload['data']['longitude']:.4f})"
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
