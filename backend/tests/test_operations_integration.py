import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import create_app


class OpsIntegrationTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.db_file = Path(self.temp_dir.name) / "ops.sqlite3"
        self.dji_state_file = Path(self.temp_dir.name) / "aircraft-state.json"
        config = type(
            "OpsIntegrationConfig",
            (),
            {
                "TESTING": True,
                "SECRET_KEY": "test",
                "DRONE_CONNECTOR": "real",
                "ALLOW_DJI_COMMANDS": False,
                "DJI_INGEST_TOKEN": "bridge-secret",
                "DJI_STATE_FILE": str(self.dji_state_file),
                "DJI_TELEMETRY_TTL_SECONDS": 300,
                "APP_DATABASE_FILE": str(self.db_file),
                "AUTH_REQUIRED": True,
                "PUBLIC_SAFETY_TOKENS": {
                    "viewer-token": "viewer",
                    "operator-token": "operator",
                    "admin-token": "admin",
                    "ingest-token": "ingest",
                },
                "MAP_PROVIDER": "openstreetmap",
                "MAP_TILE_URL_TEMPLATE": "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                "MAP_ATTRIBUTION": "OpenStreetMap contributors",
                "MAP_API_KEY": "",
            },
        )
        self.app = create_app(config)
        self.client = self.app.test_client()

    def auth(self, token):
        return {"Authorization": f"Bearer {token}"}

    def test_auth_session_and_rbac_protect_write_endpoints(self):
        missing = self.client.post("/api/vision/alerts/ingest", json={})
        self.assertEqual(missing.status_code, 401)

        viewer = self.client.post(
            "/api/vision/alerts/ingest",
            headers=self.auth("viewer-token"),
            json={},
        )
        self.assertEqual(viewer.status_code, 403)

        session = self.client.get("/api/auth/session", headers=self.auth("operator-token"))
        self.assertEqual(session.status_code, 200)
        self.assertEqual(session.get_json()["role"], "operator")

    def test_map_config_exposes_provider_without_secret(self):
        response = self.client.get("/api/map/config", headers=self.auth("viewer-token"))

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["provider"], "openstreetmap")
        self.assertIn("{z}", data["tileUrlTemplate"])
        self.assertEqual(data["attribution"], "OpenStreetMap contributors")
        self.assertFalse(data["requiresApiKey"])
        self.assertNotIn("MAP_API_KEY", json.dumps(data))

    def test_integration_status_lists_persistence_adapters_and_safety(self):
        response = self.client.get(
            "/api/integrations/status",
            headers=self.auth("viewer-token"),
        )

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data["persistence"]["enabled"])
        self.assertEqual(data["map"]["provider"], "openstreetmap")
        self.assertEqual(data["auth"]["rbacEnabled"], True)
        self.assertEqual(data["adapters"]["px4Sitl"], "read-only")
        self.assertEqual(data["adapters"]["mavlink"], "read-only")
        self.assertEqual(data["adapters"]["yoloThermal"], "ingest-review")
        self.assertFalse(data["safety"]["hardwareCommandsEnabled"])

    def test_yolo_thermal_alert_ingest_persists_and_review_audits(self):
        ingest = self.client.post(
            "/api/vision/alerts/ingest",
            headers=self.auth("ingest-token"),
            json={
                "source": "edge-yolo-thermal",
                "detections": [
                    {
                        "eventId": "alert-thermal-001",
                        "detectionType": "fire",
                        "confidence": 0.91,
                        "severity": "critical",
                        "lat": 34.621,
                        "lon": -119.721,
                        "sourceDroneId": "px4-sitl-1",
                        "imageUri": "s3://incident/frame-visible.jpg",
                        "thermalUri": "s3://incident/frame-thermal.tiff",
                        "timestamp": "2026-06-12T18:00:00+00:00",
                        "notes": "Thermal hotspot above threshold",
                    }
                ],
            },
        )

        self.assertEqual(ingest.status_code, 202)
        self.assertTrue(ingest.get_json()["accepted"])

        alerts = self.client.get("/api/alerts", headers=self.auth("viewer-token")).get_json()
        self.assertEqual(len(alerts["alerts"]), 1)
        alert = alerts["alerts"][0]
        self.assertEqual(alert["eventId"], "alert-thermal-001")
        self.assertEqual(alert["status"], "Unconfirmed")
        self.assertEqual(alert["thermalUri"], "s3://incident/frame-thermal.tiff")

        review = self.client.post(
            "/api/alerts/alert-thermal-001/review",
            headers=self.auth("operator-token"),
            json={"status": "Confirmed", "notes": "Confirmed by duty officer"},
        )
        self.assertEqual(review.status_code, 200)
        self.assertEqual(review.get_json()["alert"]["status"], "Confirmed")

        with sqlite3.connect(self.db_file) as connection:
            audit_count = connection.execute("select count(*) from audit_entries").fetchone()[0]
        self.assertGreaterEqual(audit_count, 1)

        audit = self.client.get("/api/audit", headers=self.auth("viewer-token")).get_json()
        self.assertIn("Confirmed alert", json.dumps(audit))

    def test_px4_sitl_read_only_ingest_updates_aircraft_without_commands(self):
        ingest = self.client.post(
            "/api/integrations/px4-sitl/telemetry",
            headers=self.auth("ingest-token"),
            json={
                "systemId": "px4-sitl-1",
                "vehicleName": "PX4 SITL Survey 1",
                "lat": 34.624,
                "lon": -119.719,
                "altitudeMeters": 132.5,
                "batteryPercent": 78,
                "gpsStatus": "3D fix",
                "flightMode": "Hold",
                "armed": False,
                "timestamp": "2026-06-12T18:04:00+00:00",
            },
        )

        self.assertEqual(ingest.status_code, 202)
        body = ingest.get_json()
        self.assertTrue(body["accepted"])
        self.assertEqual(body["source"], "px4-sitl-readonly")
        self.assertEqual(body["mode"], "read-only")

        status = self.client.get("/api/dji/status").get_json()
        self.assertEqual(status["connection"], "bridge-online")
        self.assertEqual(status["source"], "px4-sitl-readonly")
        self.assertFalse(status["commandEnabled"])

        fleet = self.client.get("/api/dji/fleet").get_json()
        self.assertEqual(fleet["drones"][0]["id"], "px4-sitl-1")
        self.assertEqual(fleet["drones"][0]["model"], "PX4 SITL")

    def test_mavlink_read_only_ingest_supports_ardupilot_shape(self):
        ingest = self.client.post(
            "/api/integrations/mavlink/telemetry",
            headers=self.auth("ingest-token"),
            json={
                "source": "ardupilot-sitl",
                "system_id": "ap-sitl-2",
                "vehicle_name": "ArduPilot Ridge Watch",
                "latitude": 34.628,
                "longitude": -119.725,
                "relative_altitude_m": 96,
                "battery_remaining": 66,
                "gps_fix_type": "3D",
                "custom_mode": "GUIDED",
            },
        )

        self.assertEqual(ingest.status_code, 202)
        fleet = self.client.get("/api/dji/fleet").get_json()
        self.assertEqual(fleet["drones"][0]["id"], "ap-sitl-2")
        self.assertEqual(fleet["drones"][0]["model"], "MAVLink read-only")

    def test_simulated_command_endpoint_requires_confirmation_and_audits(self):
        blocked = self.client.post(
            "/api/commands/simulate",
            headers=self.auth("operator-token"),
            json={
                "commandType": "Takeoff",
                "targetDroneId": "px4-sitl-1",
                "confirmationProvided": False,
            },
        )
        self.assertEqual(blocked.status_code, 409)
        self.assertFalse(blocked.get_json()["accepted"])

        accepted = self.client.post(
            "/api/commands/simulate",
            headers=self.auth("operator-token"),
            json={
                "commandType": "Emergency Stop",
                "targetDroneId": "px4-sitl-1",
                "confirmationProvided": True,
            },
        )
        self.assertEqual(accepted.status_code, 200)
        result = accepted.get_json()
        self.assertTrue(result["accepted"])
        self.assertIn("simulation", result["message"].lower())
        self.assertFalse(result["hardwareCommandSent"])

        audit = self.client.get("/api/audit", headers=self.auth("viewer-token")).get_json()
        self.assertIn("Emergency Stop", json.dumps(audit))

        checklist = self.client.get(
            "/api/safety/checklist",
            headers=self.auth("viewer-token"),
        ).get_json()
        self.assertTrue(checklist["emergencyStop"]["engaged"])

    def test_safety_checklist_persists_geofence_remote_id_and_airspace(self):
        update = self.client.post(
            "/api/safety/checklist",
            headers=self.auth("operator-token"),
            json={
                "geofence": {
                    "status": "verified",
                    "notes": "Incident perimeter imported from GIS review.",
                },
                "remoteId": {
                    "status": "verified",
                    "notes": "Broadcast module serial recorded.",
                },
                "airspaceApproval": {
                    "status": "pending",
                    "notes": "Awaiting operations-section approval.",
                },
            },
        )

        self.assertEqual(update.status_code, 200)
        data = update.get_json()
        self.assertEqual(data["geofence"]["status"], "verified")
        self.assertEqual(data["remoteId"]["status"], "verified")
        self.assertEqual(data["airspaceApproval"]["status"], "pending")

        reloaded = self.client.get(
            "/api/safety/checklist",
            headers=self.auth("viewer-token"),
        ).get_json()
        self.assertEqual(reloaded["geofence"]["status"], "verified")
        self.assertIn("GIS", reloaded["geofence"]["notes"])


if __name__ == "__main__":
    unittest.main()
