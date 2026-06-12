import unittest
import tempfile
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import create_app


class TestConfig:
    TESTING = True
    SECRET_KEY = "test"
    DRONE_CONNECTOR = "mock"
    ALLOW_DJI_COMMANDS = False


class RealDataDefaultConfig:
    TESTING = True
    SECRET_KEY = "test"
    DRONE_CONNECTOR = "real"
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


class DjiRealDataModeTest(unittest.TestCase):
    def setUp(self):
        self.app = create_app(RealDataDefaultConfig)
        self.client = self.app.test_client()

    def test_real_mode_reports_not_configured_without_fake_fleet(self):
        status_response = self.client.get("/api/dji/status")
        fleet_response = self.client.get("/api/dji/fleet")
        telemetry_response = self.client.get("/api/dji/telemetry")

        self.assertEqual(status_response.status_code, 200)
        status = status_response.get_json()
        self.assertEqual(status["connector"], "real")
        self.assertEqual(status["connection"], "not-configured")
        self.assertFalse(status["commandEnabled"])
        self.assertFalse(status["liveData"])
        self.assertIn("missingConfiguration", status)

        self.assertEqual(fleet_response.status_code, 200)
        self.assertEqual(fleet_response.get_json()["drones"], [])

        self.assertEqual(telemetry_response.status_code, 200)
        telemetry = telemetry_response.get_json()
        self.assertIsNone(telemetry["activeDroneId"])
        self.assertEqual(telemetry["missionState"], "not-configured")
        self.assertEqual(telemetry["linkHealth"], "not-configured")

    def test_real_mode_blocks_mission_preview_without_connector(self):
        response = self.client.post(
            "/api/dji/missions/preview",
            json={"scenarioId": "canyon-ridge", "routePoints": []},
        )

        self.assertEqual(response.status_code, 409)
        data = response.get_json()
        self.assertFalse(data["available"])
        self.assertEqual(data["riskLevel"], "unknown")
        self.assertIn("DJI connector is not configured", data["warnings"][0])


class DjiRealIngestTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.state_file = Path(self.temp_dir.name) / "dji-state.json"
        config = type(
            "RealIngestConfig",
            (),
            {
                "TESTING": True,
                "SECRET_KEY": "test",
                "DRONE_CONNECTOR": "real",
                "ALLOW_DJI_COMMANDS": False,
                "DJI_INGEST_TOKEN": "bridge-secret",
                "DJI_STATE_FILE": str(self.state_file),
                "DJI_TELEMETRY_TTL_SECONDS": 300,
            },
        )
        self.app = create_app(config)
        self.client = self.app.test_client()

    def test_status_waits_for_bridge_when_ingest_token_is_configured(self):
        status = self.client.get("/api/dji/status").get_json()

        self.assertEqual(status["connection"], "waiting-for-bridge")
        self.assertTrue(status["ingestConfigured"])
        self.assertFalse(status["liveData"])
        self.assertEqual(status["aircraftCount"], 0)

        telemetry = self.client.get("/api/dji/telemetry").get_json()
        self.assertEqual(telemetry["missionState"], "waiting-for-bridge")
        self.assertEqual(telemetry["linkHealth"], "waiting-for-bridge")

    def test_authorized_heartbeat_marks_bridge_online_without_fake_aircraft(self):
        response = self.client.post(
            "/api/dji/ingest/state",
            headers={"Authorization": "Bearer bridge-secret"},
            json={
                "source": "mobile-sdk-bridge",
                "bridge": {
                    "adapter": "android-msdk",
                    "deviceId": "rc-pro-001",
                    "appVersion": "0.1.0",
                },
            },
        )

        self.assertEqual(response.status_code, 202)
        body = response.get_json()
        self.assertTrue(body["accepted"])
        self.assertEqual(body["drones"], 0)
        self.assertEqual(body["warnings"], ["No aircraft telemetry in ingest payload"])

        status = self.client.get("/api/dji/status").get_json()
        self.assertEqual(status["connection"], "bridge-online")
        self.assertEqual(status["source"], "mobile-sdk-bridge")
        self.assertFalse(status["liveData"])
        self.assertEqual(status["aircraftCount"], 0)
        self.assertEqual(status["bridge"]["adapter"], "android-msdk")
        self.assertEqual(status["bridge"]["deviceId"], "rc-pro-001")

        self.assertEqual(self.client.get("/api/dji/fleet").get_json()["drones"], [])
        telemetry = self.client.get("/api/dji/telemetry").get_json()
        self.assertEqual(telemetry["missionState"], "bridge-online")
        self.assertEqual(telemetry["linkHealth"], "bridge-online")

    def test_ingest_rejects_missing_token(self):
        response = self.client.post(
            "/api/dji/ingest/state",
            json={
                "drones": [
                    {
                        "id": "real-m3e-01",
                        "name": "Matrice Field Unit",
                        "model": "DJI enterprise aircraft",
                        "connection": "online",
                        "batteryPct": 91,
                        "signalPct": 88,
                        "lat": 34.62,
                        "lng": -119.72,
                        "altitudeM": 122,
                        "lastSeen": "2026-06-11T17:55:00+00:00",
                        "warnings": [],
                    }
                ],
                "telemetry": {
                    "activeDroneId": "real-m3e-01",
                    "missionState": "device-online",
                    "routeProgressPct": 12,
                    "windMph": 9,
                    "temperatureF": 81,
                    "firePerimeterRisk": "operator-feed",
                    "linkHealth": "stable",
                },
            },
        )

        self.assertEqual(response.status_code, 401)
        self.assertEqual(self.client.get("/api/dji/fleet").get_json()["drones"], [])

    def test_authorized_ingest_populates_real_fleet_and_telemetry(self):
        response = self.client.post(
            "/api/dji/ingest/state",
            headers={"Authorization": "Bearer bridge-secret"},
            json={
                "source": "mobile-sdk-bridge",
                "drones": [
                    {
                        "id": "real-m3e-01",
                        "name": "Matrice Field Unit",
                        "model": "DJI Matrice 30T",
                        "connection": "online",
                        "batteryPct": 91,
                        "signalPct": 88,
                        "lat": 34.62,
                        "lng": -119.72,
                        "altitudeM": 122,
                        "lastSeen": "2026-06-11T17:55:00+00:00",
                        "warnings": ["Operator telemetry feed"],
                    }
                ],
                "telemetry": {
                    "activeDroneId": "real-m3e-01",
                    "missionState": "device-online",
                    "routeProgressPct": 12,
                    "windMph": 9,
                    "temperatureF": 81,
                    "firePerimeterRisk": "operator-feed",
                    "linkHealth": "stable",
                },
            },
        )

        self.assertEqual(response.status_code, 202)
        self.assertTrue(response.get_json()["accepted"])

        status = self.client.get("/api/dji/status").get_json()
        self.assertEqual(status["connection"], "bridge-online")
        self.assertTrue(status["liveData"])
        self.assertEqual(status["source"], "mobile-sdk-bridge")

        fleet = self.client.get("/api/dji/fleet").get_json()
        self.assertEqual(len(fleet["drones"]), 1)
        self.assertEqual(fleet["drones"][0]["id"], "real-m3e-01")
        self.assertEqual(fleet["drones"][0]["batteryPct"], 91)

        telemetry = self.client.get("/api/dji/telemetry").get_json()
        self.assertEqual(telemetry["activeDroneId"], "real-m3e-01")
        self.assertEqual(telemetry["missionState"], "device-online")
        self.assertEqual(telemetry["linkHealth"], "stable")

    def test_cloud_api_ingest_maps_mqtt_device_properties(self):
        response = self.client.post(
            "/api/dji/ingest/cloud-api",
            headers={"Authorization": "Bearer bridge-secret"},
            json={
                "topic": "thing/product/gateway-001/osd",
                "payload": {
                    "timestamp": 1781200500000,
                    "data": {
                        "device_sn": "cloud-m3t-01",
                        "device_name": "Cloud Matrice",
                        "model": "DJI Matrice 30T",
                        "latitude": 34.62,
                        "longitude": -119.72,
                        "height": 118.5,
                        "battery": {"capacity_percent": 86},
                        "wireless_link": {"link_quality": 91},
                        "mode_code": "gps-normal",
                    },
                },
            },
        )

        self.assertEqual(response.status_code, 202)
        self.assertEqual(response.get_json()["source"], "dji-cloud-api")

        status = self.client.get("/api/dji/status").get_json()
        self.assertEqual(status["connection"], "bridge-online")
        self.assertEqual(status["bridge"]["adapter"], "cloud-api-mqtt")
        self.assertEqual(status["bridge"]["deviceId"], "gateway-001")
        self.assertTrue(status["liveData"])

        fleet = self.client.get("/api/dji/fleet").get_json()
        self.assertEqual(fleet["drones"][0]["id"], "cloud-m3t-01")
        self.assertEqual(fleet["drones"][0]["batteryPct"], 86)
        self.assertEqual(fleet["drones"][0]["signalPct"], 91)
        self.assertEqual(fleet["drones"][0]["altitudeM"], 118)

        telemetry = self.client.get("/api/dji/telemetry").get_json()
        self.assertEqual(telemetry["activeDroneId"], "cloud-m3t-01")
        self.assertEqual(telemetry["missionState"], "gps-normal")
        self.assertEqual(telemetry["linkHealth"], "stable")

    def test_mobile_sdk_ingest_maps_aircraft_and_flight_state(self):
        response = self.client.post(
            "/api/dji/ingest/mobile-sdk",
            headers={"Authorization": "Bearer bridge-secret"},
            json={
                "controller": {
                    "serialNumber": "rc-pro-001",
                    "appVersion": "0.1.0",
                },
                "aircraft": {
                    "serialNumber": "msdk-m3t-01",
                    "name": "MSDK Field Unit",
                    "model": "DJI Matrice 30T",
                    "batteryPercent": 89,
                    "signalPercent": 93,
                    "latitude": 34.621,
                    "longitude": -119.721,
                    "altitudeMeters": 124.2,
                    "connection": "connected",
                },
                "flight": {
                    "state": "device-online",
                    "routeProgressPercent": 17,
                    "windMph": 8,
                    "temperatureF": 79,
                    "firePerimeterRisk": "operator-feed",
                    "linkHealth": "stable",
                },
            },
        )

        self.assertEqual(response.status_code, 202)
        self.assertEqual(response.get_json()["source"], "mobile-sdk-bridge")

        status = self.client.get("/api/dji/status").get_json()
        self.assertEqual(status["connection"], "bridge-online")
        self.assertEqual(status["bridge"]["adapter"], "mobile-sdk")
        self.assertEqual(status["bridge"]["deviceId"], "rc-pro-001")
        self.assertTrue(status["liveData"])

        fleet = self.client.get("/api/dji/fleet").get_json()
        self.assertEqual(fleet["drones"][0]["id"], "msdk-m3t-01")
        self.assertEqual(fleet["drones"][0]["connection"], "online")
        self.assertEqual(fleet["drones"][0]["altitudeM"], 124)

        telemetry = self.client.get("/api/dji/telemetry").get_json()
        self.assertEqual(telemetry["activeDroneId"], "msdk-m3t-01")
        self.assertEqual(telemetry["routeProgressPct"], 17)
        self.assertEqual(telemetry["windMph"], 8)

    def test_invalid_ingest_payload_does_not_overwrite_previous_state(self):
        valid_response = self.client.post(
            "/api/dji/ingest/state",
            headers={"Authorization": "Bearer bridge-secret"},
            json={
                "source": "mobile-sdk-bridge",
                "drones": [
                    {
                        "id": "real-m3e-01",
                        "name": "Matrice Field Unit",
                        "model": "DJI Matrice 30T",
                        "connection": "online",
                        "batteryPct": 91,
                        "signalPct": 88,
                        "lat": 34.62,
                        "lng": -119.72,
                        "altitudeM": 122,
                        "lastSeen": "2026-06-11T17:55:00+00:00",
                        "warnings": [],
                    }
                ],
                "telemetry": {
                    "activeDroneId": "real-m3e-01",
                    "missionState": "device-online",
                    "routeProgressPct": 12,
                    "windMph": 9,
                    "temperatureF": 81,
                    "firePerimeterRisk": "operator-feed",
                    "linkHealth": "stable",
                },
            },
        )
        self.assertEqual(valid_response.status_code, 202)

        invalid_response = self.client.post(
            "/api/dji/ingest/state",
            headers={"Authorization": "Bearer bridge-secret"},
            json={
                "source": "mobile-sdk-bridge",
                "drones": [
                    {
                        "id": "bad-aircraft",
                        "name": "Bad Unit",
                        "model": "DJI Matrice",
                        "connection": "online",
                        "batteryPct": 151,
                        "signalPct": 88,
                        "lat": 94.1,
                        "lng": -119.72,
                        "altitudeM": 122,
                        "lastSeen": "2026-06-11T17:55:00+00:00",
                        "warnings": [],
                    }
                ],
            },
        )

        self.assertEqual(invalid_response.status_code, 400)
        error_body = invalid_response.get_json()
        self.assertFalse(error_body["accepted"])
        self.assertIn("drones[0].batteryPct must be between 0 and 100", error_body["errors"])
        self.assertIn("drones[0].lat must be between -90 and 90", error_body["errors"])

        fleet = self.client.get("/api/dji/fleet").get_json()
        self.assertEqual(len(fleet["drones"]), 1)
        self.assertEqual(fleet["drones"][0]["id"], "real-m3e-01")

    def test_stale_ingest_state_reports_bridge_stale(self):
        response = self.client.post(
            "/api/dji/ingest/state",
            headers={"Authorization": "Bearer bridge-secret"},
            json={
                "source": "mobile-sdk-bridge",
                "drones": [
                    {
                        "id": "real-m3e-01",
                        "name": "Matrice Field Unit",
                        "model": "DJI Matrice 30T",
                        "connection": "online",
                        "batteryPct": 91,
                        "signalPct": 88,
                        "lat": 34.62,
                        "lng": -119.72,
                        "altitudeM": 122,
                        "lastSeen": "2026-06-11T17:55:00+00:00",
                        "warnings": [],
                    }
                ],
            },
        )
        self.assertEqual(response.status_code, 202)

        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        state["receivedAt"] = "2026-06-11T17:00:00+00:00"
        self.state_file.write_text(json.dumps(state), encoding="utf-8")

        status = self.client.get("/api/dji/status").get_json()
        self.assertEqual(status["connection"], "bridge-stale")
        self.assertFalse(status["liveData"])
        self.assertEqual(status["lastSync"], "2026-06-11T17:00:00+00:00")
        self.assertIn("staleReason", status)

        self.assertEqual(self.client.get("/api/dji/fleet").get_json()["drones"], [])
        telemetry = self.client.get("/api/dji/telemetry").get_json()
        self.assertEqual(telemetry["missionState"], "bridge-stale")
        self.assertEqual(telemetry["linkHealth"], "stale")


class DjiRuntimeConnectionConfigTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.state_file = Path(self.temp_dir.name) / "dji-state.json"
        self.config_file = Path(self.temp_dir.name) / "dji-runtime-config.json"
        config = type(
            "RuntimeConnectionConfig",
            (),
            {
                "TESTING": True,
                "SECRET_KEY": "test",
                "DRONE_CONNECTOR": "real",
                "ALLOW_DJI_COMMANDS": False,
                "DJI_STATE_FILE": str(self.state_file),
                "DJI_RUNTIME_CONFIG_FILE": str(self.config_file),
                "DJI_TELEMETRY_TTL_SECONDS": 300,
                "DJI_MAX_INGEST_DRONES": 16,
            },
        )
        self.app = create_app(config)
        self.client = self.app.test_client()

    def test_connection_config_starts_empty_and_redacts_secrets(self):
        response = self.client.get("/api/dji/connection")

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertFalse(data["configured"])
        self.assertEqual(data["mode"], "not-configured")
        self.assertFalse(data["ingestTokenConfigured"])
        self.assertNotIn("ingestToken", data)
        self.assertNotIn("cloudMqttPassword", data)

    def test_connection_token_generator_returns_unique_redacted_tokens(self):
        first = self.client.post("/api/dji/connection/token")
        second = self.client.post("/api/dji/connection/token")

        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200)
        first_token = first.get_json()["token"]
        second_token = second.get_json()["token"]
        self.assertIsInstance(first_token, str)
        self.assertGreaterEqual(len(first_token), 32)
        self.assertNotEqual(first_token, second_token)

        config = self.client.get("/api/dji/connection").get_json()
        self.assertFalse(config["ingestTokenConfigured"])
        self.assertNotIn(first_token, json.dumps(config))

    def test_saving_cloud_connection_config_updates_status_without_exposing_secret(self):
        response = self.client.post(
            "/api/dji/connection",
            json={
                "mode": "cloud-api",
                "ingestToken": "operator-secret",
                "cloudMqttHost": "mqtt.example.test",
                "cloudMqttPort": 8883,
                "cloudMqttUsername": "pilot-user",
                "cloudMqttPassword": "pilot-password",
                "cloudMqttClientId": "fire-drone-web",
                "workspaceId": "workspace-123",
                "autoStartCloudBridge": False,
            },
        )

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data["accepted"])
        self.assertTrue(data["config"]["configured"])
        self.assertEqual(data["config"]["mode"], "cloud-api")
        self.assertTrue(data["config"]["ingestTokenConfigured"])
        self.assertTrue(data["config"]["cloudMqttHostConfigured"])
        self.assertEqual(data["config"]["cloudMqttClientId"], "fire-drone-web")
        self.assertNotIn("operator-secret", json.dumps(data))
        self.assertNotIn("pilot-password", json.dumps(data))

        status = self.client.get("/api/dji/status").get_json()
        self.assertEqual(status["connection"], "waiting-for-bridge")
        self.assertTrue(status["ingestConfigured"])

        ingest = self.client.post(
            "/api/dji/ingest/state",
            headers={"Authorization": "Bearer operator-secret"},
            json={"source": "operator-web", "bridge": {"adapter": "manual"}},
        )
        self.assertEqual(ingest.status_code, 202)

    def test_saving_mobile_connection_returns_bridge_endpoint(self):
        response = self.client.post(
            "/api/dji/connection",
            json={
                "mode": "mobile-sdk",
                "ingestToken": "mobile-secret",
                "operatorLabel": "Xavier RC",
            },
        )

        self.assertEqual(response.status_code, 200)
        config = response.get_json()["config"]
        self.assertEqual(config["mode"], "mobile-sdk")
        self.assertTrue(config["configured"])
        self.assertIn("/api/dji/ingest/mobile-sdk", config["mobileBridgeEndpoint"])
        self.assertNotIn("mobile-secret", json.dumps(config))


if __name__ == "__main__":
    unittest.main()
