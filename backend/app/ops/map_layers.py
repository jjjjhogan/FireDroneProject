MAP_CENTER = {
    "lat": 34.6234,
    "lng": -119.7196,
    "zoom": 13,
}


MISSION_ROUTE = {
    "id": "canyon-ridge-route",
    "name": "Canyon Ridge mission route",
    "source": "incident-mission-planner",
    "points": [
        {
            "label": "LZ",
            "lat": 34.6368,
            "lng": -119.7334,
            "altitudeM": 92,
            "action": "Launch and link check",
        },
        {
            "label": "WP1",
            "lat": 34.6282,
            "lng": -119.7104,
            "altitudeM": 118,
            "action": "Thermal scan north ridge",
        },
        {
            "label": "WP2",
            "lat": 34.6098,
            "lng": -119.7192,
            "altitudeM": 122,
            "action": "Inspect southern perimeter",
        },
        {
            "label": "WP3",
            "lat": 34.6214,
            "lng": -119.7444,
            "altitudeM": 110,
            "action": "Check containment line",
        },
        {
            "label": "RTL",
            "lat": 34.6368,
            "lng": -119.7334,
            "altitudeM": 92,
            "action": "Return to launch",
        },
    ],
}

MISSION_ALERT_POINTS = [
    {
        "id": "thermal-hotspot-north",
        "label": "Thermal hotspot north",
        "type": "thermal",
        "severity": "high",
        "confidence": 0.87,
        "lat": 34.6308,
        "lng": -119.7294,
        "source": "incident-gis-seed",
    },
    {
        "id": "smoke-column-center",
        "label": "Smoke column center",
        "type": "smoke",
        "severity": "medium",
        "confidence": 0.78,
        "lat": 34.6234,
        "lng": -119.7196,
        "source": "incident-gis-seed",
    },
    {
        "id": "fire-edge-south",
        "label": "Fire edge south",
        "type": "fire",
        "severity": "critical",
        "confidence": 0.91,
        "lat": 34.6162,
        "lng": -119.7336,
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
        "lat": 34.6376,
        "lng": -119.7340,
        "altitudeM": 0,
        "source": "mission-planning",
        "warnings": ["No live aircraft position has been ingested."],
    }
]


def mission_map_layer(alerts=None, drones=None):
    mission_alerts = _mission_alerts(alerts or [])
    mission_drones = _mission_drones(drones or [])
    return {
        "source": "backend-mission-gis",
        "updatedAt": "2026-06-12T18:00:00+00:00",
        "route": MISSION_ROUTE,
        "alerts": mission_alerts,
        "drones": mission_drones,
        "bounds": _mission_bounds(MISSION_ROUTE["points"], mission_alerts, mission_drones),
    }


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


def _mission_alerts(alerts):
    if not alerts:
        return MISSION_ALERT_POINTS
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
    return mission_alerts or MISSION_ALERT_POINTS


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
                "id": "incident-canyon-ridge-fire",
                "name": "Canyon Ridge Fire perimeter",
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
                        [-119.7428, 34.6308],
                        [-119.7337, 34.6411],
                        [-119.7138, 34.6387],
                        [-119.7016, 34.6232],
                        [-119.7114, 34.6079],
                        [-119.7332, 34.6092],
                        [-119.7462, 34.6205],
                        [-119.7428, 34.6308],
                    ]
                ],
            },
        },
        {
            "type": "Feature",
            "properties": {
                "id": "mission-geofence-canyon-ridge",
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
                        [-119.7598, 34.6515],
                        [-119.6836, 34.6497],
                        [-119.6812, 34.5904],
                        [-119.7609, 34.5893],
                        [-119.7598, 34.6515],
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
                        [-119.7522, 34.6452],
                        [-119.7346, 34.6488],
                        [-119.6921, 34.6039],
                        [-119.7084, 34.5995],
                        [-119.7522, 34.6452],
                    ]
                ],
            },
        },
    ],
}
