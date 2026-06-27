from datetime import datetime


def _clean_string(value, default="", max_length=120):
    if value is None:
        return default
    text = str(value).strip()
    if not text:
        return default
    return text[:max_length]


def _require_string(container, field, errors, path, max_length=120):
    value = _clean_string(container.get(field), max_length=max_length)
    if not value:
        errors.append(f"{path}.{field} is required")
    return value


def _number(container, field, errors, path, minimum=None, maximum=None, default=None):
    value = container.get(field, default)
    if value is None:
        return default
    if isinstance(value, bool):
        errors.append(f"{path}.{field} must be a number")
        return default
    try:
        number = float(value)
    except (TypeError, ValueError):
        errors.append(f"{path}.{field} must be a number")
        return default
    if minimum is not None and number < minimum:
        errors.append(f"{path}.{field} must be between {minimum:g} and {maximum:g}")
    if maximum is not None and number > maximum:
        errors.append(f"{path}.{field} must be between {minimum:g} and {maximum:g}")
    return number


def _int_number(container, field, errors, path, minimum=None, maximum=None, default=None):
    value = _number(container, field, errors, path, minimum, maximum, default)
    if value is None:
        return default
    return round(value)


def _iso_timestamp(container, field, errors, path, default):
    value = _clean_string(container.get(field), default=default, max_length=80)
    try:
        datetime.fromisoformat(value)
    except ValueError:
        errors.append(f"{path}.{field} must be ISO-8601")
    return value


def _string_list(value, path, errors, max_items=8, max_length=160):
    if value is None:
        return []
    if not isinstance(value, list):
        errors.append(f"{path} must be a list")
        return []
    result = []
    for index, item in enumerate(value[:max_items]):
        text = _clean_string(item, max_length=max_length)
        if text:
            result.append(text)
        else:
            errors.append(f"{path}[{index}] must be a non-empty string")
    return result


def _normalize_bridge(raw_bridge, errors):
    if raw_bridge in (None, ""):
        raw_bridge = {}
    if not isinstance(raw_bridge, dict):
        errors.append("bridge must be an object")
        raw_bridge = {}
    bridge = {
        "adapter": _clean_string(
            raw_bridge.get("adapter"),
            default="operator-bridge",
            max_length=80,
        ),
        "deviceId": _clean_string(raw_bridge.get("deviceId"), max_length=120),
        "appVersion": _clean_string(raw_bridge.get("appVersion"), max_length=60),
    }
    scenario_id = _clean_string(raw_bridge.get("scenarioId"), max_length=80)
    scenario_name = _clean_string(raw_bridge.get("scenarioName"), max_length=120)
    if scenario_id:
        bridge["scenarioId"] = scenario_id
    if scenario_name:
        bridge["scenarioName"] = scenario_name
    return bridge


def _normalize_drone(raw_drone, index, received_at, errors):
    path = f"drones[{index}]"
    if not isinstance(raw_drone, dict):
        errors.append(f"{path} must be an object")
        return None

    drone = {
        "id": _require_string(raw_drone, "id", errors, path, max_length=120),
        "name": _clean_string(raw_drone.get("name"), default="DJI aircraft"),
        "model": _clean_string(
            raw_drone.get("model"),
            default="DJI enterprise aircraft",
        ),
        "connection": _clean_string(
            raw_drone.get("connection"),
            default="online",
            max_length=40,
        ).lower(),
        "batteryPct": _int_number(
            raw_drone,
            "batteryPct",
            errors,
            path,
            minimum=0,
            maximum=100,
            default=0,
        ),
        "signalPct": _int_number(
            raw_drone,
            "signalPct",
            errors,
            path,
            minimum=0,
            maximum=100,
            default=0,
        ),
        "lat": _number(
            raw_drone,
            "lat",
            errors,
            path,
            minimum=-90,
            maximum=90,
            default=0,
        ),
        "lng": _number(
            raw_drone,
            "lng",
            errors,
            path,
            minimum=-180,
            maximum=180,
            default=0,
        ),
        "altitudeM": _int_number(
            raw_drone,
            "altitudeM",
            errors,
            path,
            minimum=-1000,
            maximum=20000,
            default=0,
        ),
        "lastSeen": _iso_timestamp(raw_drone, "lastSeen", errors, path, received_at),
        "warnings": _string_list(raw_drone.get("warnings"), f"{path}.warnings", errors),
    }
    if not drone["name"] or drone["name"] == "DJI aircraft":
        drone["name"] = drone["id"] or "DJI aircraft"
    return drone


def _normalize_telemetry(raw_telemetry, errors):
    if raw_telemetry in (None, ""):
        raw_telemetry = {}
    if not isinstance(raw_telemetry, dict):
        errors.append("telemetry must be an object")
        raw_telemetry = {}
    if not raw_telemetry:
        return {}

    telemetry = {
        "activeDroneId": _clean_string(raw_telemetry.get("activeDroneId"), max_length=120),
        "missionState": _clean_string(
            raw_telemetry.get("missionState"),
            default="device-online",
            max_length=80,
        ),
        "routeProgressPct": _int_number(
            raw_telemetry,
            "routeProgressPct",
            errors,
            "telemetry",
            minimum=0,
            maximum=100,
            default=0,
        ),
        "windMph": _number(raw_telemetry, "windMph", errors, "telemetry"),
        "temperatureF": _number(raw_telemetry, "temperatureF", errors, "telemetry"),
        "firePerimeterRisk": _clean_string(
            raw_telemetry.get("firePerimeterRisk"),
            default="unknown",
            max_length=80,
        ),
        "linkHealth": _clean_string(
            raw_telemetry.get("linkHealth"),
            default="stable",
            max_length=80,
        ),
    }
    scenario_id = _clean_string(raw_telemetry.get("scenarioId"), max_length=80)
    scenario_name = _clean_string(raw_telemetry.get("scenarioName"), max_length=120)
    if scenario_id:
        telemetry["scenarioId"] = scenario_id
    if scenario_name:
        telemetry["scenarioName"] = scenario_name
    return telemetry


def normalize_ingest_payload(payload, received_at, max_drones=16):
    errors = []
    warnings = []

    if not isinstance(payload, dict):
        return {
            "accepted": False,
            "errors": ["DJI ingest payload must be a JSON object"],
            "warnings": [],
            "state": None,
        }

    raw_drones = payload.get("drones", [])
    if raw_drones in (None, ""):
        raw_drones = []
    if not isinstance(raw_drones, list):
        errors.append("drones must be a list")
        raw_drones = []
    if len(raw_drones) > int(max_drones):
        errors.append(f"drones must contain at most {int(max_drones)} aircraft")
        raw_drones = raw_drones[: int(max_drones)]

    drones = []
    for index, raw_drone in enumerate(raw_drones):
        drone = _normalize_drone(raw_drone, index, received_at, errors)
        if drone is not None:
            drones.append(drone)

    telemetry = _normalize_telemetry(payload.get("telemetry"), errors)
    bridge = _normalize_bridge(payload.get("bridge"), errors)
    source = _clean_string(payload.get("source"), default="operator-bridge", max_length=80)

    if not drones:
        warnings.append("No aircraft telemetry in ingest payload")

    return {
        "accepted": not errors,
        "errors": errors,
        "warnings": warnings,
        "state": {
            "source": source,
            "receivedAt": received_at,
            "bridge": bridge,
            "drones": drones,
            "telemetry": telemetry,
            "warnings": warnings,
        },
    }
