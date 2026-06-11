import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import create_app


class TestConfig:
    TESTING = True
    SECRET_KEY = "test"
    DRONE_CONNECTOR = "mock"
    ALLOW_DJI_COMMANDS = False


class DjiApiTest(unittest.TestCase):
    def setUp(self):
        self.app = create_app(TestConfig)
        self.client = self.app.test_client()

    def test_dji_status_uses_mock_connector(self):
        response = self.client.get("/api/dji/status")

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["connector"], "mock")
        self.assertEqual(data["provider"], "DJI")
        self.assertFalse(data["commandEnabled"])
        self.assertIn("DJI Cloud API", data["reservedAdapters"])
        self.assertIn("DJI Mobile SDK Bridge", data["reservedAdapters"])

    def test_dji_fleet_and_telemetry_shapes_are_stable(self):
        fleet_response = self.client.get("/api/dji/fleet")
        telemetry_response = self.client.get("/api/dji/telemetry")

        self.assertEqual(fleet_response.status_code, 200)
        fleet = fleet_response.get_json()
        self.assertGreaterEqual(len(fleet["drones"]), 2)
        drone = fleet["drones"][0]
        for field in [
            "id",
            "name",
            "model",
            "connection",
            "batteryPct",
            "signalPct",
            "lat",
            "lng",
            "altitudeM",
            "lastSeen",
            "warnings",
        ]:
            self.assertIn(field, drone)

        self.assertEqual(telemetry_response.status_code, 200)
        telemetry = telemetry_response.get_json()
        for field in [
            "activeDroneId",
            "missionState",
            "routeProgressPct",
            "windMph",
            "temperatureF",
            "firePerimeterRisk",
            "linkHealth",
        ]:
            self.assertIn(field, telemetry)

    def test_mission_preview_and_confirm_are_guarded(self):
        payload = {
            "scenarioId": "min-mountains",
            "routePoints": [
                {"lat": 37.2102, "lng": -119.5481},
                {"lat": 37.2188, "lng": -119.5324},
            ],
        }

        preview_response = self.client.post("/api/dji/missions/preview", json=payload)
        self.assertEqual(preview_response.status_code, 200)
        preview = preview_response.get_json()
        self.assertEqual(preview["scenarioId"], "min-mountains")
        self.assertTrue(preview["requiresConfirmation"])
        self.assertGreater(preview["estimatedDurationMin"], 0)
        self.assertGreaterEqual(len(preview["warnings"]), 1)

        confirm_response = self.client.post("/api/dji/missions/confirm", json=preview)
        self.assertEqual(confirm_response.status_code, 403)
        result = confirm_response.get_json()
        self.assertFalse(result["accepted"])
        self.assertIn("ALLOW_DJI_COMMANDS", result["blockedReason"])
        self.assertEqual(result["nextRequiredAction"], "Enable backend command gate")


if __name__ == "__main__":
    unittest.main()
