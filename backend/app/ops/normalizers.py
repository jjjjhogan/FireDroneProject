from uuid import uuid4

from app.dji.state_store import utc_now_iso


STATUS_LABELS = {
    "unconfirmed": "Unconfirmed",
    "confirmed": "Confirmed",
    "falsepositive": "False Positive",
    "false-positive": "False Positive",
    "resolved": "Resolved",
}


SEVERITY_LABELS = {
    "low": "Low",
    "medium": "Medium",
    "high": "High",
    "critical": "Critical",
}


def _clean_text(value, default="", max_length=240):
    text = str(value if value is not None else default).strip()
    return (text or default)[:max_length]


def _float(value, default=0.0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _int(value, default=0):
    try:
        return round(float(value))
    except (TypeError, ValueError):
        return default


def _first(container, names, default=None):
    if not isinstance(container, dict):
        return default
    for name in names:
        value = container.get(name)
        if value not in (None, ""):
            return value
    return default


def _status(value):
    key = str(value or "unconfirmed").replace(" ", "").lower()
    return STATUS_LABELS.get(key, "Unconfirmed")


def _severity(value):
    key = str(value or "medium").lower()
    return SEVERITY_LABELS.get(key, "Medium")


def normalize_detection_payload(payload):
    payload = payload if isinstance(payload, dict) else {}
    detections = payload.get("detections")
    if detections is None:
        detections = [payload]
    if not isinstance(detections, list):
        return {"accepted": False, "errors": ["detections must be a list"], "alerts": []}

    errors = []
    alerts = []
    for index, detection in enumerate(detections):
        if not isinstance(detection, dict):
            errors.append(f"detections[{index}] must be an object")
            continue
        detection_type = _clean_text(
            _first(detection, ["detectionType", "classLabel", "type"], "smoke"),
            max_length=40,
        ).lower()
        if detection_type not in {"fire", "smoke"}:
            errors.append(f"detections[{index}].detectionType must be fire or smoke")
            continue
        confidence = _float(_first(detection, ["confidence", "confidencePct"], 0))
        if confidence > 1:
            confidence = confidence / 100
        if confidence < 0 or confidence > 1:
            errors.append(f"detections[{index}].confidence must be between 0 and 1")
            continue
        lat = _float(_first(detection, ["lat", "latitude"], 0))
        lon = _float(_first(detection, ["lon", "lng", "longitude"], 0))
        if lat < -90 or lat > 90 or lon < -180 or lon > 180:
            errors.append(f"detections[{index}].location is out of range")
            continue
        event_id = _clean_text(
            _first(detection, ["eventId", "id"], f"alert-{uuid4().hex[:12]}"),
            max_length=120,
        )
        alerts.append(
            {
                "eventId": event_id,
                "detectionType": detection_type.title(),
                "confidence": confidence,
                "severity": _severity(detection.get("severity")),
                "lat": lat,
                "lon": lon,
                "sourceDroneId": _clean_text(
                    _first(detection, ["sourceDroneId", "droneId", "source"], "unknown"),
                    max_length=120,
                ),
                "imageUri": _clean_text(
                    _first(detection, ["imageUri", "imageUrl", "frameUri"], ""),
                    max_length=500,
                ),
                "thermalUri": _clean_text(
                    _first(detection, ["thermalUri", "thermalUrl"], ""),
                    max_length=500,
                ),
                "timestamp": _clean_text(
                    _first(detection, ["timestamp", "detectedAt"], utc_now_iso()),
                    max_length=120,
                ),
                "status": _status(detection.get("status")),
                "reviewer": None,
                "reviewTimestamp": None,
                "notes": _clean_text(detection.get("notes", ""), max_length=1000),
                "raw": detection,
            }
        )

    return {"accepted": len(errors) == 0, "errors": errors, "alerts": alerts}


def mavlink_payload_to_ingest_payload(payload, adapter, model):
    payload = payload if isinstance(payload, dict) else {}
    aircraft_id = _clean_text(
        _first(payload, ["systemId", "system_id", "id", "vehicleId"], "sitl-aircraft"),
        max_length=120,
    )
    lat = _float(_first(payload, ["lat", "latitude"], 0))
    lng = _float(_first(payload, ["lon", "lng", "longitude"], 0))
    altitude = _int(
        _first(payload, ["altitudeMeters", "altitudeM", "relative_altitude_m", "alt"], 0)
    )
    battery = _int(
        _first(payload, ["batteryPercent", "battery_remaining", "batteryPct"], 0)
    )
    flight_mode = _clean_text(
        _first(payload, ["flightMode", "custom_mode", "mode", "missionState"], "read-only"),
        max_length=80,
    )
    source = _clean_text(payload.get("source"), adapter, max_length=80)
    if adapter == "px4-sitl-readonly":
        source = "px4-sitl-readonly"

    return {
        "source": source,
        "bridge": {
            "adapter": adapter,
            "mode": "read-only",
            "deviceId": aircraft_id,
        },
        "drones": [
            {
                "id": aircraft_id,
                "name": _clean_text(
                    _first(payload, ["vehicleName", "vehicle_name", "name"], aircraft_id),
                    max_length=120,
                ),
                "model": model,
                "connection": "online",
                "batteryPct": max(0, min(100, battery)),
                "signalPct": _int(_first(payload, ["signalPct", "linkQuality"], 100)),
                "lat": lat,
                "lng": lng,
                "altitudeM": altitude,
                "lastSeen": _clean_text(payload.get("timestamp"), utc_now_iso()),
                "warnings": [
                    "Read-only SITL telemetry; command dispatch disabled.",
                ],
            }
        ],
        "telemetry": {
            "activeDroneId": aircraft_id,
            "missionState": flight_mode,
            "routeProgressPct": _int(
                _first(payload, ["routeProgressPct", "route_progress_pct"], 0)
            ),
            "windMph": _float(_first(payload, ["windMph", "wind_mph"], 0)),
            "temperatureF": _float(_first(payload, ["temperatureF", "temperature_f"], 0)),
            "firePerimeterRisk": _clean_text(
                _first(payload, ["firePerimeterRisk", "fire_perimeter_risk"], "unknown"),
                max_length=80,
            ),
            "linkHealth": _clean_text(
                _first(payload, ["linkHealth", "link_health"], "read-only"),
                max_length=80,
            ),
        },
    }
