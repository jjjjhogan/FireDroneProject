from app.routes import api_bp

ANALYTICS_SUMMARY = {
    "dataSource": "api",
    "lastUpdated": "2026-06-10T09:42:00-07:00",
    "kpis": [
        {
            "id": "detection_latency",
            "label": "Detection Latency",
            "value": "2.6 min",
            "detail": "Median time from hotspot cue to operator alert",
            "trend": "Down 31% vs manual patrol",
        },
        {
            "id": "thermal_confidence",
            "label": "Thermal Confidence",
            "value": "91%",
            "detail": "Model ensemble average across active sorties",
            "trend": "+4 pts this week",
        },
        {
            "id": "safe_return",
            "label": "Safe Return Rate",
            "value": "97%",
            "detail": "Battery-aware routing with reserve margin",
            "trend": "Stable over 14 days",
        },
        {
            "id": "coverage_efficiency",
            "label": "Coverage Efficiency",
            "value": "84%",
            "detail": "Perimeter scanned vs planned patrol corridor",
            "trend": "+9% after route optimizer",
        },
        {
            "id": "false_positive_rate",
            "label": "False Positive Rate",
            "value": "6.2%",
            "detail": "Thermal hits cleared after visual confirmation",
            "trend": "Down 1.8 pts",
        },
        {
            "id": "command_gate",
            "label": "Command Gate",
            "value": "Locked",
            "detail": "DJI dispatch requires human confirmation",
            "trend": "Awaiting backend enable",
        },
    ],
    "weeklyDetections": [
        {"label": "Mon", "value": 4, "unit": "hotspots"},
        {"label": "Tue", "value": 7, "unit": "hotspots"},
        {"label": "Wed", "value": 5, "unit": "hotspots"},
        {"label": "Thu", "value": 9, "unit": "hotspots"},
        {"label": "Fri", "value": 6, "unit": "hotspots"},
        {"label": "Sat", "value": 11, "unit": "hotspots"},
        {"label": "Sun", "value": 8, "unit": "hotspots"},
    ],
    "responseTimesMin": [
        {"label": "Scout launch", "value": 3.4, "unit": "min"},
        {"label": "Perimeter scan", "value": 12.8, "unit": "min"},
        {"label": "Hotspot verify", "value": 5.1, "unit": "min"},
        {"label": "Operator handoff", "value": 2.2, "unit": "min"},
    ],
    "recentMissions": [
        {
            "missionId": "MSN-240610-01",
            "scenarioName": "Canyon Ridge Fire",
            "outcome": "completed",
            "durationMin": 18,
            "hotspotsDetected": 3,
            "completedAt": "Jun 10, 08:14 AM",
        },
        {
            "missionId": "MSN-240609-04",
            "scenarioName": "Min Mountains",
            "outcome": "completed",
            "durationMin": 22,
            "hotspotsDetected": 1,
            "completedAt": "Jun 9, 04:52 PM",
        },
        {
            "missionId": "MSN-240609-02",
            "scenarioName": "Santa Cruz Fog Belt",
            "outcome": "aborted",
            "durationMin": 9,
            "hotspotsDetected": 0,
            "completedAt": "Jun 9, 11:06 AM",
        },
    ],
    "environmental": {
        "windMph": 14,
        "humidityPct": 38,
        "visibilityMi": 4.2,
        "smokeIndex": "elevated",
        "thermalNoise": "moderate",
    },
    "fleetUtilization": {
        "activeDrones": 1,
        "availableDrones": 1,
        "chargingDrones": 1,
        "flightHoursToday": 3.6,
        "sortiesToday": 4,
        "avgBatteryAtLaunchPct": 81,
    },
    "integrationTargets": [
        {
            "label": "Analytics summary feed",
            "endpoint": "GET /api/analytics/summary",
            "status": "connected",
        },
        {
            "label": "Mission history archive",
            "endpoint": "GET /api/analytics/missions",
            "status": "planned",
        },
        {
            "label": "Thermal model scores",
            "endpoint": "GET /api/analytics/thermal-scores",
            "status": "planned",
        },
        {
            "label": "DJI telemetry stream",
            "endpoint": "GET /api/dji/telemetry",
            "status": "planned",
        },
    ],
}


@api_bp.route("/status", methods=["GET"])
def status():
    return {
        "message": "FireDrone API is running",
        "version": "0.1.0",
    }


@api_bp.route("/analytics/summary", methods=["GET"])
def analytics_summary():
    return ANALYTICS_SUMMARY
