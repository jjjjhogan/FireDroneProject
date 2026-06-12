#!/usr/bin/env python3
import argparse
import json
import os
import ssl
import sys
import urllib.error
import urllib.request


def _post_cloud_payload(api_base, token, topic, payload):
    body = json.dumps({"topic": topic, "payload": payload}).encode("utf-8")
    request = urllib.request.Request(
        f"{api_base.rstrip('/')}/dji/ingest/cloud-api",
        data=body,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=8) as response:
        return response.status, response.read().decode("utf-8")


def _parse_args():
    parser = argparse.ArgumentParser(
        description="Forward DJI Cloud API MQTT device-property messages to FireDrone."
    )
    parser.add_argument("--mqtt-host", default=os.getenv("DJI_CLOUD_MQTT_HOST", ""))
    parser.add_argument(
        "--mqtt-port",
        type=int,
        default=int(os.getenv("DJI_CLOUD_MQTT_PORT", "8883")),
    )
    parser.add_argument("--mqtt-username", default=os.getenv("DJI_CLOUD_MQTT_USERNAME", ""))
    parser.add_argument("--mqtt-password", default=os.getenv("DJI_CLOUD_MQTT_PASSWORD", ""))
    parser.add_argument(
        "--mqtt-client-id",
        default=os.getenv("DJI_CLOUD_MQTT_CLIENT_ID", "firedrone-cloud-worker"),
    )
    parser.add_argument(
        "--topic",
        action="append",
        default=None,
        help="MQTT topic to subscribe. Repeat for multiple topics.",
    )
    parser.add_argument(
        "--api-base",
        default=os.getenv("FIRE_DRONE_API_BASE", "http://127.0.0.1:5000/api"),
    )
    parser.add_argument("--token", default=os.getenv("DJI_INGEST_TOKEN", ""))
    parser.add_argument(
        "--no-tls",
        action="store_true",
        help="Disable TLS for local MQTT testing only.",
    )
    return parser.parse_args()


def main():
    args = _parse_args()
    if not args.mqtt_host:
        print("DJI_CLOUD_MQTT_HOST or --mqtt-host is required", file=sys.stderr)
        return 2
    if not args.token:
        print("DJI_INGEST_TOKEN or --token is required", file=sys.stderr)
        return 2

    try:
        import paho.mqtt.client as mqtt
    except ImportError:
        print(
            "Missing paho-mqtt. Install backend requirements before running this worker.",
            file=sys.stderr,
        )
        return 2

    topics = args.topic or ["thing/product/+/osd", "thing/product/+/state"]
    client = mqtt.Client(client_id=args.mqtt_client_id)
    if args.mqtt_username or args.mqtt_password:
        client.username_pw_set(args.mqtt_username, args.mqtt_password)
    if not args.no_tls:
        client.tls_set(cert_reqs=ssl.CERT_REQUIRED)

    def on_connect(client, userdata, flags, rc):
        if rc != 0:
            print(f"MQTT connection failed rc={rc}", file=sys.stderr)
            return
        for topic in topics:
            client.subscribe(topic)
            print(f"Subscribed {topic}")

    def on_message(client, userdata, message):
        try:
            payload = json.loads(message.payload.decode("utf-8"))
            status, response_body = _post_cloud_payload(
                args.api_base,
                args.token,
                message.topic,
                payload,
            )
            print(f"Forwarded {message.topic} -> HTTP {status} {response_body}")
        except (json.JSONDecodeError, UnicodeDecodeError) as exc:
            print(f"Bad MQTT JSON on {message.topic}: {exc}", file=sys.stderr)
        except (urllib.error.URLError, TimeoutError) as exc:
            print(f"FireDrone ingest failed for {message.topic}: {exc}", file=sys.stderr)

    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(args.mqtt_host, args.mqtt_port, keepalive=60)
    client.loop_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
