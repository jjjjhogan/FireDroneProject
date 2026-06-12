from datetime import datetime, timezone


def _first(container, names, default=None):
    if not isinstance(container, dict):
        return default
    for name in names:
        value = container.get(name)
        if value not in (None, ""):
            return value
    return default


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


def _connection(value):
    text = str(value or "online").lower()
    if text in {"connected", "online", "ready", "flying"}:
        return "online"
    if text in {"standby", "idle"}:
        return "standby"
    return "offline"


def mobile_sdk_state_to_ingest_payload(payload):
    payload = payload if isinstance(payload, dict) else {}
    aircraft = payload.get("aircraft") if isinstance(payload.get("aircraft"), dict) else {}
    flight = payload.get("flight") if isinstance(payload.get("flight"), dict) else {}
    controller = (
        payload.get("controller") if isinstance(payload.get("controller"), dict) else {}
    )

    aircraft_id = str(
        _first(
            aircraft,
            ["serialNumber", "serial_number", "deviceSn", "id", "sn"],
            "mobile-sdk-aircraft",
        )
    )
    controller_id = str(
        _first(controller, ["serialNumber", "serial_number", "deviceId", "id"], "")
    )

    return {
        "source": "mobile-sdk-bridge",
        "bridge": {
            "adapter": "mobile-sdk",
            "deviceId": controller_id,
            "appVersion": str(_first(controller, ["appVersion", "app_version"], "")),
        },
        "drones": [
            {
                "id": aircraft_id,
                "name": str(_first(aircraft, ["name", "callsign"], aircraft_id)),
                "model": str(
                    _first(aircraft, ["model", "modelName"], "DJI Mobile SDK aircraft")
                ),
                "connection": _connection(
                    _first(aircraft, ["connection", "connectionState"], "online")
                ),
                "batteryPct": _as_int(
                    _first(aircraft, ["batteryPercent", "batteryPct", "battery"], 0)
                ),
                "signalPct": _as_int(
                    _first(aircraft, ["signalPercent", "signalPct", "linkQuality"], 0)
                ),
                "lat": _as_float(
                    _first(aircraft, ["latitude", "lat", "homeLatitude"], 0)
                ),
                "lng": _as_float(
                    _first(aircraft, ["longitude", "lng", "homeLongitude"], 0)
                ),
                "altitudeM": _as_int(
                    _first(aircraft, ["altitudeMeters", "altitudeM", "altitude"], 0)
                ),
                "lastSeen": str(
                    _first(
                        aircraft,
                        ["lastSeen", "timestamp"],
                        datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
                    )
                ),
                "warnings": payload.get("warnings", []),
            }
        ],
        "telemetry": {
            "activeDroneId": aircraft_id,
            "missionState": str(
                _first(flight, ["state", "missionState", "flightMode"], "device-online")
            ),
            "routeProgressPct": _as_int(
                _first(flight, ["routeProgressPercent", "routeProgressPct"], 0)
            ),
            "windMph": _as_float(_first(flight, ["windMph", "windSpeedMph"], 0)),
            "temperatureF": _as_float(_first(flight, ["temperatureF"], 0)),
            "firePerimeterRisk": str(
                _first(flight, ["firePerimeterRisk"], "operator-feed")
            ),
            "linkHealth": str(_first(flight, ["linkHealth"], "stable")),
        },
    }
