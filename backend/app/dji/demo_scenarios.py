from dataclasses import dataclass


@dataclass(frozen=True)
class DemoWaypoint:
    label: str
    lat: float
    lng: float
    altitude_m: float
    mode: str


@dataclass(frozen=True)
class DemoScenario:
    scenario_id: str
    title: str
    region: str
    device_name: str
    model: str
    wind_mph: float
    temperature_f: float
    fire_perimeter_risk: str
    waypoints: tuple[DemoWaypoint, ...]


def _wp(label, lat, lng, altitude_m, mode):
    return DemoWaypoint(
        label=label,
        lat=lat,
        lng=lng,
        altitude_m=altitude_m,
        mode=mode,
    )


DEMO_SCENARIOS = {
    "canyon-ridge": DemoScenario(
        scenario_id="canyon-ridge",
        title="San Bernardino Mountain Ridge",
        region="Mountain",
        device_name="Demo Matrice Ridge Unit",
        model="DJI Matrice 30T",
        wind_mph=18,
        temperature_f=83,
        fire_perimeter_risk="ridge-thermal-watch",
        waypoints=(
            _wp("LZ Alpha", 37.2064, -119.5531, 92, "takeoff"),
            _wp("North ridge thermal", 37.2138, -119.5414, 118, "waypoint-flight"),
            _wp("Eastern flank", 37.2188, -119.5324, 124, "waypoint-flight"),
            _wp("Southern perimeter", 37.2102, -119.5256, 116, "waypoint-flight"),
            _wp("Western containment", 37.2048, -119.5388, 108, "hover-inspect"),
            _wp("RTL", 37.2064, -119.5531, 92, "return-to-home"),
        ),
    ),
    "santa-cruz-fog": DemoScenario(
        scenario_id="santa-cruz-fog",
        title="Santa Cruz Fog Belt",
        region="Coastal",
        device_name="Demo Mavic Fog Unit",
        model="DJI Mavic 3T",
        wind_mph=9,
        temperature_f=64,
        fire_perimeter_risk="marine-layer-visibility",
        waypoints=(
            _wp("Coastal launch", 36.9748, -122.0303, 72, "takeoff"),
            _wp("Fog line", 36.9824, -122.0188, 96, "waypoint-flight"),
            _wp("Thermal lock", 36.9892, -122.0072, 102, "hover-inspect"),
            _wp("Harbor return", 36.9796, -122.0015, 88, "waypoint-flight"),
            _wp("Coastal launch", 36.9748, -122.0303, 72, "return-to-home"),
        ),
    ),
    "yukon-boreal": DemoScenario(
        scenario_id="yukon-boreal",
        title="Yukon Boreal Line",
        region="Boreal",
        device_name="Demo Boreal Relay Unit",
        model="DJI Matrice 350 RTK",
        wind_mph=11,
        temperature_f=52,
        fire_perimeter_risk="canopy-relay",
        waypoints=(
            _wp("Perimeter start", 60.7211, -135.0568, 122, "takeoff"),
            _wp("Canopy gap", 60.7294, -135.0392, 148, "waypoint-flight"),
            _wp("Cold uplift", 60.7398, -135.0196, 154, "waypoint-flight"),
            _wp("North relay", 60.7317, -135.0008, 142, "hover-inspect"),
            _wp("Perimeter start", 60.7211, -135.0568, 122, "return-to-home"),
        ),
    ),
    "colorado-plateau": DemoScenario(
        scenario_id="colorado-plateau",
        title="Colorado Plateau Watch",
        region="Plateau",
        device_name="Demo Plateau Watch Unit",
        model="DJI Matrice 30T",
        wind_mph=25,
        temperature_f=91,
        fire_perimeter_risk="wind-corridor",
        waypoints=(
            _wp("Mesa launch", 38.5745, -109.5498, 136, "takeoff"),
            _wp("Canyon relay", 38.5836, -109.5352, 168, "waypoint-flight"),
            _wp("Plateau shoulder", 38.5942, -109.5211, 176, "waypoint-flight"),
            _wp("Wind corridor fire", 38.5862, -109.5037, 162, "hover-inspect"),
            _wp("Mesa launch", 38.5745, -109.5498, 136, "return-to-home"),
        ),
    ),
    "sonoran-dust-front": DemoScenario(
        scenario_id="sonoran-dust-front",
        title="Sonoran Dust Front",
        region="Desert",
        device_name="Demo Desert Outflow Unit",
        model="DJI Mavic 3 Enterprise",
        wind_mph=32,
        temperature_f=101,
        fire_perimeter_risk="dust-front",
        waypoints=(
            _wp("Desert pad", 32.2458, -111.1662, 86, "takeoff"),
            _wp("Arroyo crossing", 32.2547, -111.1505, 112, "waypoint-flight"),
            _wp("Monsoon gust front", 32.2641, -111.1334, 118, "waypoint-flight"),
            _wp("Dust shelf", 32.2573, -111.1168, 106, "hover-inspect"),
            _wp("Desert pad", 32.2458, -111.1662, 86, "return-to-home"),
        ),
    ),
    "plains-wind-run": DemoScenario(
        scenario_id="plains-wind-run",
        title="Great Plains Wind Run",
        region="Grassland",
        device_name="Demo Grassfire Chase Unit",
        model="DJI Matrice 30",
        wind_mph=23,
        temperature_f=88,
        fire_perimeter_risk="fast-grass-spread",
        waypoints=(
            _wp("Range gate", 37.4221, -101.0841, 78, "takeoff"),
            _wp("Fence relay", 37.4313, -101.0612, 96, "waypoint-flight"),
            _wp("Head-fire flank", 37.4405, -101.0374, 102, "waypoint-flight"),
            _wp("Windward turn", 37.4299, -101.0195, 92, "hover-inspect"),
            _wp("Range gate", 37.4221, -101.0841, 78, "return-to-home"),
        ),
    ),
    "sierra-foothills-wui": DemoScenario(
        scenario_id="sierra-foothills-wui",
        title="Sierra Foothills WUI",
        region="Urban-Wildland",
        device_name="Demo WUI Structure Unit",
        model="DJI Matrice 30T",
        wind_mph=14,
        temperature_f=86,
        fire_perimeter_risk="structure-defense",
        waypoints=(
            _wp("Staging street", 38.7428, -120.7338, 82, "takeoff"),
            _wp("Structure line", 38.7504, -120.7189, 104, "waypoint-flight"),
            _wp("Evac corridor", 38.7598, -120.7026, 110, "waypoint-flight"),
            _wp("Ember shower zone", 38.7516, -120.6892, 98, "hover-inspect"),
            _wp("Staging street", 38.7428, -120.7338, 82, "return-to-home"),
        ),
    ),
    "gulf-coast-fuel-belt": DemoScenario(
        scenario_id="gulf-coast-fuel-belt",
        title="Gulf Coast Fuel Belt",
        region="Subtropical",
        device_name="Demo Palmetto Sweep Unit",
        model="DJI Mavic 3T",
        wind_mph=19,
        temperature_f=92,
        fire_perimeter_risk="humid-fuel-belt",
        waypoints=(
            _wp("Coastal inlet", 30.3897, -86.5128, 66, "takeoff"),
            _wp("Palmetto gap", 30.3984, -86.4986, 86, "waypoint-flight"),
            _wp("Humid fuel belt", 30.4076, -86.4829, 92, "waypoint-flight"),
            _wp("Storm outflow", 30.3991, -86.4663, 84, "hover-inspect"),
            _wp("Coastal inlet", 30.3897, -86.5128, 66, "return-to-home"),
        ),
    ),
    "cascade-high-country": DemoScenario(
        scenario_id="cascade-high-country",
        title="Cascade High Country",
        region="Alpine",
        device_name="Demo Alpine Snowline Unit",
        model="DJI Matrice 350 RTK",
        wind_mph=22,
        temperature_f=49,
        fire_perimeter_risk="thin-air-snowline",
        waypoints=(
            _wp("Trailhead pad", 44.2719, -121.8132, 142, "takeoff"),
            _wp("Talus bench", 44.2807, -121.7986, 184, "waypoint-flight"),
            _wp("Alpine smoke pool", 44.2913, -121.7831, 196, "waypoint-flight"),
            _wp("Snow line", 44.2821, -121.7668, 176, "hover-inspect"),
            _wp("Trailhead pad", 44.2719, -121.8132, 142, "return-to-home"),
        ),
    ),
    "everglades-peat-margin": DemoScenario(
        scenario_id="everglades-peat-margin",
        title="Everglades Peat Margin",
        region="Wetland",
        device_name="Demo Peat Margin Unit",
        model="DJI Mavic 3 Enterprise",
        wind_mph=9,
        temperature_f=87,
        fire_perimeter_risk="peat-smolder",
        waypoints=(
            _wp("Levee pad", 25.3862, -80.6424, 54, "takeoff"),
            _wp("Peat channel", 25.3948, -80.6275, 72, "waypoint-flight"),
            _wp("Smolder line", 25.4039, -80.6117, 76, "waypoint-flight"),
            _wp("Mangrove edge", 25.3957, -80.5963, 68, "hover-inspect"),
            _wp("Levee pad", 25.3862, -80.6424, 54, "return-to-home"),
        ),
    ),
}


DEFAULT_DEMO_SCENARIO_ID = "canyon-ridge"


def scenario_ids():
    return tuple(DEMO_SCENARIOS.keys())


def get_demo_scenario(scenario_id=None):
    key = str(scenario_id or DEFAULT_DEMO_SCENARIO_ID).strip().lower()
    return DEMO_SCENARIOS.get(key, DEMO_SCENARIOS[DEFAULT_DEMO_SCENARIO_ID])


_WAYPOINT_ACTIONS = {
    "takeoff": "Launch and link check",
    "waypoint-flight": "Patrol segment",
    "hover-inspect": "Inspect hazard corridor",
    "return-to-home": "Return to launch",
}

_ALERT_TYPES = ("thermal", "smoke", "fire")
_ALERT_SEVERITIES = ("high", "medium", "critical")


def scenario_map_center(scenario):
    lats = [point.lat for point in scenario.waypoints]
    lngs = [point.lng for point in scenario.waypoints]
    return {
        "lat": round(sum(lats) / len(lats), 4),
        "lng": round(sum(lngs) / len(lngs), 4),
        "zoom": 13,
    }


def scenario_mission_route(scenario):
    return {
        "id": f"{scenario.scenario_id}-perimeter-route",
        "name": f"{scenario.title} patrol",
        "source": "demo-scenario-planner",
        "points": [
            {
                "label": point.label,
                "lat": point.lat,
                "lng": point.lng,
                "altitudeM": round(point.altitude_m),
                "action": _WAYPOINT_ACTIONS.get(point.mode, "Patrol segment"),
            }
            for point in scenario.waypoints
        ],
    }


def scenario_alert_points(scenario):
    patrol_points = [
        point
        for point in scenario.waypoints
        if point.mode != "return-to-home" and point.label.lower() != "rtl"
    ][1:4]
    alerts = []
    for index, point in enumerate(patrol_points):
        alerts.append(
            {
                "id": f"{scenario.scenario_id}-{_ALERT_TYPES[index % 3]}",
                "label": f"{point.label} watch point",
                "type": _ALERT_TYPES[index % 3],
                "severity": _ALERT_SEVERITIES[index % 3],
                "confidence": round(0.9 - (index * 0.04), 2),
                "lat": point.lat,
                "lng": point.lng,
                "source": "demo-scenario-gis-seed",
            }
        )
    return alerts


def _bbox_from_waypoints(waypoints, lat_pad, lng_pad):
    lats = [point.lat for point in waypoints]
    lngs = [point.lng for point in waypoints]
    return {
        "south": min(lats) - lat_pad,
        "north": max(lats) + lat_pad,
        "west": min(lngs) - lng_pad,
        "east": max(lngs) + lng_pad,
    }


def _polygon_ring(bbox):
    return [
        [bbox["west"], bbox["south"]],
        [bbox["west"], bbox["north"]],
        [bbox["east"], bbox["north"]],
        [bbox["east"], bbox["south"]],
        [bbox["west"], bbox["south"]],
    ]


def scenario_geofence_collection(scenario):
    perimeter = _bbox_from_waypoints(scenario.waypoints, 0.008, 0.012)
    mission = _bbox_from_waypoints(scenario.waypoints, 0.018, 0.024)
    corridor = _bbox_from_waypoints(scenario.waypoints[1:4], 0.004, 0.008)
    return {
        "type": "FeatureCollection",
        "source": "demo-scenario-gis",
        "scenarioId": scenario.scenario_id,
        "updatedAt": "2026-06-18T00:00:00+00:00",
        "features": [
            {
                "type": "Feature",
                "properties": {
                    "id": f"incident-{scenario.scenario_id}",
                    "name": f"{scenario.title} perimeter",
                    "layerType": "incident_perimeter",
                    "status": "active",
                    "source": "demo-scenario-gis",
                    "strokeColor": "#ef553b",
                    "fillColor": "#ef553b",
                    "fillOpacity": 0.22,
                },
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [_polygon_ring(perimeter)],
                },
            },
            {
                "type": "Feature",
                "properties": {
                    "id": f"mission-geofence-{scenario.scenario_id}",
                    "name": "Mission geofence",
                    "layerType": "mission_geofence",
                    "status": "operator_review_required",
                    "source": "demo-scenario-gis",
                    "strokeColor": "#22b7ae",
                    "fillColor": "#22b7ae",
                    "fillOpacity": 0.10,
                },
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [_polygon_ring(mission)],
                },
            },
            {
                "type": "Feature",
                "properties": {
                    "id": f"no-fly-{scenario.scenario_id}",
                    "name": "Crewed aircraft corridor buffer",
                    "layerType": "no_fly_buffer",
                    "status": "blocked",
                    "source": "demo-scenario-gis",
                    "strokeColor": "#f4c84a",
                    "fillColor": "#f4c84a",
                    "fillOpacity": 0.16,
                },
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [_polygon_ring(corridor)],
                },
            },
        ],
    }


def infer_scenario_id_from_coordinates(lat, lng):
    try:
        lat = float(lat)
        lng = float(lng)
    except (TypeError, ValueError):
        return None
    if lat == 0 and lng == 0:
        return None

    best_id = None
    best_score = float("inf")
    for scenario_id, scenario in DEMO_SCENARIOS.items():
        center = scenario_map_center(scenario)
        score = (lat - center["lat"]) ** 2 + (lng - center["lng"]) ** 2
        if score < best_score:
            best_score = score
            best_id = scenario_id
    return best_id


def infer_scenario_id_from_drones(drones):
    for drone in drones or []:
        scenario_id = infer_scenario_id_from_coordinates(
            drone.get("lat"),
            drone.get("lng"),
        )
        if scenario_id:
            return scenario_id
    return None
