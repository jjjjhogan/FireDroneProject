import math

from app.dji.demo_scenarios import DEFAULT_DEMO_SCENARIO_ID, get_demo_scenario


def _waypoint_dict(point):
    return {
        "label": point.label,
        "lat": point.lat,
        "lng": point.lng,
        "altitude_m": point.altitude_m,
        "mode": point.mode,
    }


# Backward-compatible alias for tests and local MQTT scripts.
FIRE_PERIMETER_MISSION = [
    _waypoint_dict(point)
    for point in get_demo_scenario(DEFAULT_DEMO_SCENARIO_ID).waypoints
]


def _lerp(start, end, t):
    return start + (end - start) * t


def mission_state(sequence, ticks_per_leg, scenario_id=None, waypoints=None):
    scenario = get_demo_scenario(scenario_id)
    waypoints = waypoints or [_waypoint_dict(point) for point in scenario.waypoints]
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

    wobble = math.sin(sequence * 0.7) * 0.00003
    lat += wobble
    lng -= wobble * 0.6

    loops_completed = (sequence - 1) // loop_ticks
    base_battery = 96 - (loops_completed * 14) - (tick * 0.35)
    battery_pct = max(22, round(base_battery))

    route_progress = min(
        100,
        max(0, round((tick / max(loop_ticks - 1, 1)) * 100)),
    )
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


def build_cloud_osd_payload(
    device_id,
    sequence,
    ticks_per_leg=6,
    scenario_id=None,
):
    scenario = get_demo_scenario(scenario_id)
    state = mission_state(sequence, ticks_per_leg, scenario.scenario_id)
    return {
        "data": {
            "device_sn": device_id,
            "device_id": device_id,
            "device_name": scenario.device_name,
            "model": scenario.model,
            "latitude": round(state["lat"], 6),
            "longitude": round(state["lng"], 6),
            "height": state["altitude_m"],
            "battery": {"capacity_percent": state["battery_pct"]},
            "wireless_link": {"link_quality": state["link_quality"]},
            "mode_code": state["mode"],
            "route_progress": state["route_progress_pct"],
            "wind_mph": scenario.wind_mph,
            "temperature_f": scenario.temperature_f,
            "fire_perimeter_risk": scenario.fire_perimeter_risk,
            "scenario_id": scenario.scenario_id,
            "scenario_name": scenario.title,
        },
        "_demo": {
            "scenarioId": scenario.scenario_id,
            "scenarioName": scenario.title,
            "leg": f"{state['leg_index']}/{state['leg_count']}",
            "waypoint": state["leg_label"],
            "routeProgressPct": state["route_progress_pct"],
        },
    }


def cloud_osd_topic(device_id):
    return f"thing/product/{device_id}/osd"
