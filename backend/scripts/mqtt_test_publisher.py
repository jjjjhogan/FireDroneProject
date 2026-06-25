#!/usr/bin/env python3
"""Publish synthetic DJI Cloud API OSD messages for local EMQX development.

Simulates a fire-perimeter patrol: takeoff, ridge thermal scan, flank inspect,
containment check, and return-to-launch — not a fixed hover point.
"""
import argparse
import json
import math
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

# Min Mountains incident area — matches mock connector / mission preview coords.
FIRE_PERIMETER_MISSION = [
    {
        "label": "LZ Alpha",
        "lat": 37.2064,
        "lng": -119.5531,
        "altitude_m": 92,
        "mode": "takeoff",
    },
    {
        "label": "North ridge thermal",
        "lat": 37.2138,
        "lng": -119.5414,
        "altitude_m": 118,
        "mode": "waypoint-flight",
    },
    {
        "label": "Eastern flank",
        "lat": 37.2188,
        "lng": -119.5324,
        "altitude_m": 124,
        "mode": "waypoint-flight",
    },
    {
        "label": "Southern perimeter",
        "lat": 37.2102,
        "lng": -119.5256,
        "altitude_m": 116,
        "mode": "waypoint-flight",
    },
    {
        "label": "Western containment",
        "lat": 37.2048,
        "lng": -119.5388,
        "altitude_m": 108,
        "mode": "hover-inspect",
    },
    {
        "label": "RTL",
        "lat": 37.2064,
        "lng": -119.5531,
        "altitude_m": 92,
        "mode": "return-to-home",
    },
]


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


def _lerp(start, end, t):
    return start + (end - start) * t


def _mission_state(sequence, ticks_per_leg, waypoints):
    leg_count = len(waypoints) - 1
    loop_ticks = leg_count * ticks_per_leg
    tick = (sequence - 1) % loop_ticks
    leg_index = tick // ticks_per_leg
    t = (tick % ticks_per_leg) / max(ticks_per_leg - 1, 1)

    start = waypoints[leg_index]
    end = waypoints[leg_index + 1]
    lat = _lerp(start["lat"], end["lat"], t)
    lng = _lerp(start["lng"], end["lng"], t)
    alt = _lerp(start["altitude_m"], end["altitude_m"], t)

    # Gentle drift so the icon doesn't move in perfectly straight lines.
    wobble = math.sin(sequence * 0.7) * 0.00003
    lat += wobble
    lng -= wobble * 0.6

    loops_completed = (sequence - 1) // loop_ticks
    base_battery = 96 - (loops_completed * 14) - (tick * 0.35)
    battery_pct = max(22, round(base_battery))

    route_progress = round(((tick + leg_index * ticks_per_leg) / loop_ticks) * 100)
    mode = end["mode"] if t > 0.55 else start["mode"]
    link_quality = max(68, min(99, 94 - abs(math.sin(sequence * 0.4)) * 12))

    return {
        "lat": lat,
        "lng": lng,
        "altitude_m": round(alt, 1),
        "battery_pct": battery_pct,
        "mode": mode,
        "link_quality": round(link_quality),
        "leg_label": end["label"] if t > 0.5 else start["label"],
        "route_progress_pct": route_progress,
        "leg_index": leg_index + 1,
        "leg_count": leg_count,
    }


def _build_payload(device_id, sequence, ticks_per_leg):
    state = _mission_state(sequence, ticks_per_leg, FIRE_PERIMETER_MISSION)
    return {
        "data": {
            "device_sn": device_id,
            "device_id": device_id,
            "device_name": "Demo Matrice Perimeter Unit",
            "model": "DJI Matrice 30T",
            "latitude": round(state["lat"], 6),
            "longitude": round(state["lng"], 6),
            "height": state["altitude_m"],
            "battery": {"capacity_percent": state["battery_pct"]},
            "wireless_link": {"link_quality": state["link_quality"]},
            "mode_code": state["mode"],
            "route_progress": state["route_progress_pct"],
        },
        "_demo": {
            "leg": f"{state['leg_index']}/{state['leg_count']}",
            "waypoint": state["leg_label"],
            "routeProgressPct": state["route_progress_pct"],
        },
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
            payload = _build_payload(args.device_id, sequence, args.ticks_per_leg)
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
