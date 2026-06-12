from datetime import datetime, timezone
from uuid import uuid4


def _utc_now():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


class BaseDjiConnector:
    connector_name = "base"

    def __init__(self, allow_commands=False):
        self.allow_commands = allow_commands

    def status(self):
        raise NotImplementedError

    def fleet(self):
        raise NotImplementedError

    def telemetry(self):
        raise NotImplementedError

    def preview_mission(self, payload):
        raise NotImplementedError

    def confirm_mission(self, payload):
        if not self.allow_commands:
            return (
                {
                    "accepted": False,
                    "blockedReason": (
                        "ALLOW_DJI_COMMANDS is false; live DJI command "
                        "dispatch is locked."
                    ),
                    "missionId": None,
                    "nextRequiredAction": "Enable backend command gate",
                },
                403,
            )

        return (
            {
                "accepted": True,
                "blockedReason": None,
                "missionId": payload.get("missionId") or f"mission-{uuid4().hex[:8]}",
                "nextRequiredAction": "Monitor DJI Pilot confirmation",
            },
            200,
        )


class MockDjiConnector(BaseDjiConnector):
    connector_name = "mock"

    def status(self):
        return {
            "provider": "DJI",
            "connector": self.connector_name,
            "connection": "simulated",
            "commandEnabled": self.allow_commands,
            "reservedAdapters": ["DJI Cloud API", "DJI Mobile SDK Bridge"],
            "lastSync": _utc_now(),
        }

    def fleet(self):
        return {
            "drones": [
                {
                    "id": "dji-thermal-01",
                    "name": "DJI Thermal Lead",
                    "model": "DJI enterprise aircraft",
                    "connection": "online",
                    "batteryPct": 82,
                    "signalPct": 94,
                    "lat": 37.2138,
                    "lng": -119.5414,
                    "altitudeM": 118,
                    "lastSeen": _utc_now(),
                    "warnings": [],
                },
                {
                    "id": "dji-relay-02",
                    "name": "DJI Relay Scout",
                    "model": "DJI enterprise aircraft",
                    "connection": "standby",
                    "batteryPct": 68,
                    "signalPct": 87,
                    "lat": 37.2204,
                    "lng": -119.5266,
                    "altitudeM": 96,
                    "lastSeen": _utc_now(),
                    "warnings": ["Manual launch confirmation required"],
                },
                {
                    "id": "dji-map-03",
                    "name": "DJI Mapper Reserve",
                    "model": "DJI enterprise aircraft",
                    "connection": "charging",
                    "batteryPct": 54,
                    "signalPct": 0,
                    "lat": 37.2064,
                    "lng": -119.5531,
                    "altitudeM": 0,
                    "lastSeen": _utc_now(),
                    "warnings": ["Dock battery below dispatch target"],
                },
            ]
        }

    def telemetry(self):
        return {
            "activeDroneId": "dji-thermal-01",
            "missionState": "preview-ready",
            "routeProgressPct": 0,
            "windMph": 14,
            "temperatureF": 73,
            "firePerimeterRisk": "elevated",
            "linkHealth": "stable",
        }

    def preview_mission(self, payload):
        route_points = payload.get("routePoints") or [
            {"lat": 37.2102, "lng": -119.5481},
            {"lat": 37.2188, "lng": -119.5324},
            {"lat": 37.2256, "lng": -119.5198},
        ]
        return {
            "scenarioId": payload.get("scenarioId", "min-mountains"),
            "routePoints": route_points,
            "estimatedDurationMin": 18,
            "maxAltitudeM": 120,
            "riskLevel": "elevated",
            "warnings": [
                "DJI command dispatch is locked until a human confirms.",
                "Route intersects the active fire perimeter buffer.",
            ],
            "requiresConfirmation": True,
        }


class RealDjiConnector(BaseDjiConnector):
    connector_name = "real"

    required_configuration = [
        "DJI_CLOUD_API_APP_ID",
        "DJI_CLOUD_API_APP_KEY",
        "DJI_CLOUD_API_APP_LICENSE",
        "DJI_CLOUD_API_MQTT_HOST",
        "DJI_WORKSPACE_ID",
    ]

    def __init__(self, allow_commands=False, config=None):
        super().__init__(allow_commands=allow_commands)
        self.config = config or {}

    def missing_configuration(self):
        return [
            key
            for key in self.required_configuration
            if not str(self.config.get(key, "")).strip()
        ]

    def is_configured(self):
        return len(self.missing_configuration()) == 0

    def status(self):
        missing = self.missing_configuration()
        configured = len(missing) == 0
        return {
            "provider": "DJI",
            "connector": self.connector_name,
            "connection": "configured" if configured else "not-configured",
            "commandEnabled": self.allow_commands and configured,
            "liveData": False,
            "missingConfiguration": missing,
            "reservedAdapters": ["DJI Cloud API", "DJI Mobile SDK Bridge"],
            "lastSync": _utc_now(),
        }

    def fleet(self):
        return {"drones": []}

    def telemetry(self):
        return {
            "activeDroneId": None,
            "missionState": "not-configured",
            "routeProgressPct": 0,
            "windMph": None,
            "temperatureF": None,
            "firePerimeterRisk": "unknown",
            "linkHealth": "not-configured",
        }

    def preview_mission(self, payload):
        return (
            {
                "available": False,
                "scenarioId": payload.get("scenarioId", "unknown"),
                "routePoints": payload.get("routePoints") or [],
                "estimatedDurationMin": 0,
                "maxAltitudeM": 0,
                "riskLevel": "unknown",
                "warnings": [
                    "DJI connector is not configured; mission package was not sent to an aircraft."
                ],
                "requiresConfirmation": True,
            },
            409,
        )


class DjiCloudConnector(RealDjiConnector):
    connector_name = "dji-cloud-api"


class DjiMobileBridgeConnector(RealDjiConnector):
    connector_name = "dji-mobile-sdk-bridge"


def create_dji_connector(config):
    connector_name = str(config.get("DRONE_CONNECTOR", "real")).lower()
    allow_commands = bool(config.get("ALLOW_DJI_COMMANDS", False))

    if connector_name == "mock":
        return MockDjiConnector(allow_commands=allow_commands)
    if connector_name in {"cloud", "dji-cloud", "dji-cloud-api"}:
        return DjiCloudConnector(allow_commands=allow_commands, config=config)
    if connector_name in {"mobile", "mobile-sdk", "dji-mobile-sdk-bridge"}:
        return DjiMobileBridgeConnector(allow_commands=allow_commands, config=config)
    return RealDjiConnector(allow_commands=allow_commands, config=config)
