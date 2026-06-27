from app.dji.demo_scenarios import (
    get_demo_scenario,
    scenario_alert_points,
    scenario_geofence_collection,
    scenario_map_center,
    scenario_mission_route,
)


MAP_CENTER = {
    "lat": 37.2110,
    "lng": -119.5400,
    "zoom": 13,
}


MISSION_ROUTE = {
    "id": "min-mountains-perimeter-route",
    "name": "Min Mountains fire perimeter patrol",
    "source": "incident-mission-planner",
    "points": [
        {
            "label": "LZ Alpha",
            "lat": 37.2064,
            "lng": -119.5531,
            "altitudeM": 92,
            "action": "Launch and link check",
        },
        {
            "label": "North ridge thermal",
            "lat": 37.2138,
            "lng": -119.5414,
            "altitudeM": 118,
            "action": "Thermal scan north ridge",
        },
        {
            "label": "Eastern flank",
            "lat": 37.2188,
            "lng": -119.5324,
            "altitudeM": 124,
            "action": "Inspect eastern flank",
        },
        {
            "label": "Southern perimeter",
            "lat": 37.2102,
            "lng": -119.5256,
            "altitudeM": 116,
            "action": "Check southern fire edge",
        },
        {
            "label": "Western containment",
            "lat": 37.2048,
            "lng": -119.5388,
            "altitudeM": 108,
            "action": "Verify containment line",
        },
        {
            "label": "RTL",
            "lat": 37.2064,
            "lng": -119.5531,
            "altitudeM": 92,
            "action": "Return to launch",
        },
    ],
}

MISSION_ALERT_POINTS = [
    {
        "id": "thermal-hotspot-north",
        "label": "Thermal hotspot north ridge",
        "type": "thermal",
        "severity": "high",
        "confidence": 0.87,
        "lat": 37.2145,
        "lng": -119.5380,
        "source": "incident-gis-seed",
    },
    {
        "id": "smoke-column-center",
        "label": "Smoke column center",
        "type": "smoke",
        "severity": "medium",
        "confidence": 0.78,
        "lat": 37.2110,
        "lng": -119.5400,
        "source": "incident-gis-seed",
    },
    {
        "id": "fire-edge-south",
        "label": "Active fire edge south",
        "type": "fire",
        "severity": "critical",
        "confidence": 0.91,
        "lat": 37.2070,
        "lng": -119.5280,
        "source": "incident-gis-seed",
    },
]

MISSION_DRONE_MARKERS = [
    {
        "id": "planned-launch-zone",
        "name": "Planned launch zone",
        "model": "Operator-selected aircraft",
        "connection": "planned",
        "live": False,
        "lat": 37.2064,
        "lng": -119.5531,
        "altitudeM": 0,
        "source": "mission-planning",
        "warnings": ["No live aircraft position has been ingested."],
    }
]


def active_scenario_id_from_state(state):
    if not state:
        return None
    bridge = state.get("bridge") or {}
    telemetry = state.get("telemetry") or {}
    scenario_id = bridge.get("scenarioId") or telemetry.get("scenarioId")
    if not scenario_id:
        return None
    return str(scenario_id).strip().lower()


def map_center_for_scenario(scenario_id=None):
    if scenario_id:
        return scenario_map_center(get_demo_scenario(scenario_id))
    return MAP_CENTER


def geofence_map_layer(scenario_id=None):
    if scenario_id:
        return scenario_geofence_collection(get_demo_scenario(scenario_id))
    return GEOFENCE_FEATURE_COLLECTION


def mission_map_layer(alerts=None, drones=None, scenario_id=None):
    if scenario_id:
        scenario = get_demo_scenario(scenario_id)
        route = scenario_mission_route(scenario)
        seed_alerts = scenario_alert_points(scenario)
    else:
        route = MISSION_ROUTE
        seed_alerts = MISSION_ALERT_POINTS

    mission_alerts = _mission_alerts(alerts or [], seed_alerts)
    mission_drones = _mission_drones(drones or [])
    payload = {
        "source": "backend-mission-gis",
        "updatedAt": "2026-06-12T18:00:00+00:00",
        "route": route,
        "alerts": mission_alerts,
        "drones": mission_drones,
        "bounds": _mission_bounds(route["points"], mission_alerts, mission_drones),
    }
    if scenario_id:
        payload["scenarioId"] = scenario_id
    return payload


def _mission_bounds(route_points, alerts, drones):
    points = []
    points.extend(route_points or [])
    points.extend(alerts or [])
    points.extend(drones or [])
    coordinate_points = [
        (float(point["lat"]), float(point["lng"]))
        for point in points
        if point.get("lat") is not None and point.get("lng") is not None
    ]
    if not coordinate_points:
        return {
            "source": "configured-center",
            "north": MAP_CENTER["lat"],
            "south": MAP_CENTER["lat"],
            "east": MAP_CENTER["lng"],
            "west": MAP_CENTER["lng"],
        }
    latitudes = [point[0] for point in coordinate_points]
    longitudes = [point[1] for point in coordinate_points]
    return {
        "source": "computed-from-map-layers",
        "north": max(latitudes),
        "south": min(latitudes),
        "east": max(longitudes),
        "west": min(longitudes),
    }


def _mission_alerts(alerts, seed_alerts=None):
    fallback_alerts = seed_alerts or MISSION_ALERT_POINTS
    if not alerts:
        return fallback_alerts
    mission_alerts = []
    for alert in alerts:
        if alert.get("lat") is None or alert.get("lon") is None:
            continue
        mission_alerts.append(
            {
                "id": alert.get("eventId", "alert"),
                "label": alert.get("notes")
                or alert.get("detectionType")
                or "Map alert",
                "type": str(alert.get("detectionType", "alert")).lower(),
                "severity": str(alert.get("severity", "medium")).lower(),
                "confidence": float(alert.get("confidence", 0)),
                "lat": float(alert["lat"]),
                "lng": float(alert["lon"]),
                "source": alert.get("sourceDroneId", "operations-store"),
                "status": alert.get("status", "Unconfirmed"),
            }
        )
    return mission_alerts or fallback_alerts


def _mission_drones(drones):
    live_drones = []
    for drone in drones:
        if drone.get("lat") is None or drone.get("lng") is None:
            continue
        live_drones.append(
            {
                "id": drone.get("id", "aircraft"),
                "name": drone.get("name") or drone.get("id") or "Aircraft",
                "model": drone.get("model", "aircraft"),
                "connection": drone.get("connection", "unknown"),
                "live": True,
                "lat": float(drone["lat"]),
                "lng": float(drone["lng"]),
                "altitudeM": float(drone.get("altitudeM", 0)),
                "source": "dji-state-store",
                "warnings": drone.get("warnings") or [],
            }
        )
    return live_drones or MISSION_DRONE_MARKERS


GEOFENCE_FEATURE_COLLECTION = {
    "type": "FeatureCollection",
    "source": "backend-gis",
    "updatedAt": "2026-06-12T18:00:00+00:00",
    "features": [
        {
            "type": "Feature",
            "properties": {
                "id": "incident-min-mountains-fire",
                "name": "Min Mountains Fire perimeter",
                "layerType": "incident_perimeter",
                "status": "active",
                "source": "incident-gis-review",
                "strokeColor": "#ef553b",
                "fillColor": "#ef553b",
                "fillOpacity": 0.22,
            },
            "geometry": {
                "type": "Polygon",
                "coordinates": [
                    [
                        [-119.5560, 37.2050],
                        [-119.5480, 37.2210],
                        [-119.5280, 37.2180],
                        [-119.5220, 37.2080],
                        [-119.5300, 37.2020],
                        [-119.5480, 37.2030],
                        [-119.5560, 37.2050],
                    ]
                ],
            },
        },
        {
            "type": "Feature",
            "properties": {
                "id": "mission-geofence-min-mountains",
                "name": "Mission geofence",
                "layerType": "mission_geofence",
                "status": "operator_review_required",
                "source": "backend-gis-review",
                "strokeColor": "#22b7ae",
                "fillColor": "#22b7ae",
                "fillOpacity": 0.10,
            },
            "geometry": {
                "type": "Polygon",
                "coordinates": [
                    [
                        [-119.5640, 37.1990],
                        [-119.5160, 37.1985],
                        [-119.5140, 37.2245],
                        [-119.5620, 37.2250],
                        [-119.5640, 37.1990],
                    ]
                ],
            },
        },
        {
            "type": "Feature",
            "properties": {
                "id": "no-fly-air-tanker-corridor",
                "name": "Crewed aircraft corridor buffer",
                "layerType": "no_fly_buffer",
                "status": "blocked",
                "source": "airspace-review-placeholder",
                "strokeColor": "#f4c84a",
                "fillColor": "#f4c84a",
                "fillOpacity": 0.16,
            },
            "geometry": {
                "type": "Polygon",
                "coordinates": [
                    [
                        [-119.5580, 37.2180],
                        [-119.5340, 37.2200],
                        [-119.5200, 37.2060],
                        [-119.5380, 37.2040],
                        [-119.5580, 37.2180],
                    ]
                ],
            },
        },
    ],
}
