#!/usr/bin/env python3
import argparse
import json
import os
import sys
import urllib.request


SAMPLE_STATE = {
    "controller": {
        "serialNumber": "rc-pro-001",
        "appVersion": "0.1.0",
    },
    "aircraft": {
        "serialNumber": "msdk-m3t-01",
        "name": "MSDK Field Unit",
        "model": "DJI Matrice 30T",
        "batteryPercent": 89,
        "signalPercent": 93,
        "latitude": 34.621,
        "longitude": -119.721,
        "altitudeMeters": 124.2,
        "connection": "connected",
    },
    "flight": {
        "state": "device-online",
        "routeProgressPercent": 17,
        "windMph": 8,
        "temperatureF": 79,
        "firePerimeterRisk": "operator-feed",
        "linkHealth": "stable",
    },
}


def _load_payload(path, use_sample):
    if use_sample:
        return SAMPLE_STATE
    if path == "-":
        return json.load(sys.stdin)
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


def _parse_args():
    parser = argparse.ArgumentParser(
        description="Post a DJI Mobile SDK bridge snapshot to FireDrone."
    )
    parser.add_argument(
        "payload",
        nargs="?",
        default="-",
        help="JSON file to post, or '-' for stdin.",
    )
    parser.add_argument(
        "--sample",
        action="store_true",
        help="Send the built-in sample Mobile SDK state.",
    )
    parser.add_argument(
        "--api-base",
        default=os.getenv("FIRE_DRONE_API_BASE", "http://127.0.0.1:5000/api"),
    )
    parser.add_argument("--token", default=os.getenv("DJI_INGEST_TOKEN", ""))
    return parser.parse_args()


def main():
    args = _parse_args()
    if not args.token:
        print("DJI_INGEST_TOKEN or --token is required", file=sys.stderr)
        return 2

    payload = _load_payload(args.payload, args.sample)
    request = urllib.request.Request(
        f"{args.api_base.rstrip('/')}/dji/ingest/mobile-sdk",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {args.token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=8) as response:
        print(response.read().decode("utf-8"))
        return 0 if response.status < 400 else 1


if __name__ == "__main__":
    raise SystemExit(main())
