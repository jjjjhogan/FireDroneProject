import math

# Min Mountains incident area — matches mission preview / map layers.
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


def _lerp(start, end, t):
    return start + (end - start) * t


def mission_state(sequence, ticks_per_leg, waypoints=None):
    waypoints = waypoints or FIRE_PERIMETER_MISSION
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


def build_cloud_osd_payload(device_id, sequence, ticks_per_leg=6):
    state = mission_state(sequence, ticks_per_leg)
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


def cloud_osd_topic(device_id):
    return f"thing/product/{device_id}/osd"
