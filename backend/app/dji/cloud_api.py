from datetime import datetime, timezone


def _topic_gateway_sn(topic):
    parts = str(topic or "").split("/")
    if "product" in parts:
        index = parts.index("product")
        if len(parts) > index + 1:
            return parts[index + 1]
    return "dji-cloud-gateway"


def _payload_data(message):
    if not isinstance(message, dict):
        return {}
    data = message.get("data")
    if isinstance(data, dict):
        return data
    return message


def _first(container, paths, default=None):
    for path in paths:
        value = container
        for part in path:
            if not isinstance(value, dict) or part not in value:
                value = None
                break
            value = value[part]
        if value not in (None, ""):
            return value
    return default


def _timestamp_iso(message):
    value = _first(message, [("timestamp",), ("ts",), ("time",)])
    if value in (None, ""):
        return datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    try:
        number = float(value)
    except (TypeError, ValueError):
        return str(value)
    if number > 10_000_000_000:
        number = number / 1000
    return datetime.fromtimestamp(number, tz=timezone.utc).replace(microsecond=0).isoformat()


def _as_int(value, default=0):
    try:
        return round(float(value))
    except (TypeError, ValueError):
        return default


def _as_float(value, default=0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def cloud_api_message_to_ingest_payload(payload):
    topic = payload.get("topic", "") if isinstance(payload, dict) else ""
    message = payload.get("payload", payload) if isinstance(payload, dict) else {}
    if not isinstance(message, dict):
        message = {}

    gateway_sn = _topic_gateway_sn(topic)
    data = _payload_data(message)
    device_id = str(
        _first(
            data,
            [
                ("device_sn",),
                ("sn",),
                ("serial_number",),
                ("gateway_sn",),
                ("host", "sn"),
            ],
            gateway_sn,
        )
    )
    battery_pct = _as_int(
        _first(
            data,
            [
                ("battery", "capacity_percent"),
                ("battery", "percent"),
                ("battery_percent",),
                ("capacity_percent",),
                ("battery",),
            ],
            0,
        )
    )
    signal_pct = _as_int(
        _first(
            data,
            [
                ("wireless_link", "link_quality"),
                ("wireless_link", "signal_quality"),
                ("signal_quality",),
                ("signal_percent",),
                ("link_quality",),
            ],
            0,
        )
    )
    mode = str(
        _first(
            data,
            [("mode_code",), ("flight_status",), ("state",), ("status",)],
            "cloud-api-osd",
        )
    )

    return {
        "source": "dji-cloud-api",
        "bridge": {
            "adapter": "cloud-api-mqtt",
            "deviceId": gateway_sn,
            "appVersion": str(_first(message, [("method",), ("bid",)], "")),
        },
        "drones": [
            {
                "id": device_id,
                "name": str(
                    _first(
                        data,
                        [("device_name",), ("nickname",), ("callsign",)],
                        device_id,
                    )
                ),
                "model": str(
                    _first(
                        data,
                        [("model",), ("device_model",), ("product_model",)],
                        "DJI Cloud API aircraft",
                    )
                ),
                "connection": "online",
                "batteryPct": battery_pct,
                "signalPct": signal_pct,
                "lat": _as_float(
                    _first(
                        data,
                        [("latitude",), ("lat",), ("position", "latitude")],
                        0,
                    )
                ),
                "lng": _as_float(
                    _first(
                        data,
                        [("longitude",), ("lng",), ("position", "longitude")],
                        0,
                    )
                ),
                "altitudeM": _as_int(
                    _first(
                        data,
                        [("height",), ("altitude",), ("elevation",)],
                        0,
                    )
                ),
                "lastSeen": _timestamp_iso(message),
                "warnings": [],
            }
        ],
        "telemetry": {
            "activeDroneId": device_id,
            "missionState": mode,
            "routeProgressPct": _as_int(_first(data, [("route_progress",)], 0)),
            "windMph": _as_float(_first(data, [("wind_mph",), ("windSpeed",)], 0)),
            "temperatureF": _as_float(
                _first(data, [("temperature_f",), ("temperatureF",)], 0)
            ),
            "firePerimeterRisk": str(
                _first(data, [("fire_perimeter_risk",), ("firePerimeterRisk",)], "unknown")
            ),
            "linkHealth": "stable" if signal_pct > 0 else "unknown",
        },
    }
