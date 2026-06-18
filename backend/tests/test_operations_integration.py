import json
import sqlite3
import sys
import tempfile
import unittest
import gc
from contextlib import closing
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import create_app


class FakeUrlopenResponse:
    def __init__(self, payload):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, traceback):
        return False

    def read(self):
        return json.dumps(self.payload).encode("utf-8")


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
                "MAP_DEFAULT_BASEMAP": "satellite",
                "MAP_IMAGERY_PROVIDER": "arcgis-world-imagery",
                "MAP_IMAGERY_TILE_URL_TEMPLATE": (
                    "https://services.arcgisonline.com/ArcGIS/rest/services/"
                    "World_Imagery/MapServer/tile/{z}/{y}/{x}"
                ),
                "MAP_IMAGERY_ATTRIBUTION": (
                    "Powered by Esri | Sources: Esri, Maxar, Earthstar "
                    "Geographics, and the GIS User Community"
                ),
                "MAP_SEARCH_PROVIDER": "nominatim",
                "NOMINATIM_SEARCH_URL": "https://nominatim.openstreetmap.org/search",
                "NOMINATIM_USER_AGENT": "FireDroneProject Tests",
                "MAP_SEARCH_LIMIT": 4,
            },
        )
        self.app = create_app(config)
        self.client = self.app.test_client()

    def tearDown(self):
        gc.collect()

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
        self.assertEqual(data["defaultBasemap"], "satellite")
        self.assertEqual(len(data["basemaps"]), 2)
        satellite = next(
            basemap for basemap in data["basemaps"] if basemap["id"] == "satellite"
        )
        self.assertEqual(satellite["provider"], "arcgis-world-imagery")
        self.assertIn("World_Imagery", satellite["tileUrlTemplate"])
        self.assertIn("Powered by Esri", satellite["attribution"])
        self.assertEqual(satellite["policy"]["status"], "development-imagery")
        streets = next(
            basemap for basemap in data["basemaps"] if basemap["id"] == "streets"
        )
        self.assertEqual(streets["provider"], "openstreetmap")
        self.assertNotIn("MAP_API_KEY", json.dumps(data))
        self.assertEqual(data["tilePolicy"]["status"], "development-only")
        self.assertFalse(data["tilePolicy"]["productionReady"])
        self.assertIn("production", data["tilePolicy"]["message"].lower())
        self.assertEqual(data["incidentLayerStatus"], "geojson")
        self.assertEqual(data["geofenceLayerStatus"], "geojson")
        self.assertEqual(data["geofenceLayerEndpoint"], "/api/map/geofence")
        self.assertEqual(data["missionLayerEndpoint"], "/api/map/mission")

    def test_map_search_requires_query(self):
        response = self.client.get(
            "/api/map/search",
            headers=self.auth("viewer-token"),
        )

        self.assertEqual(response.status_code, 400)
        data = response.get_json()
        self.assertFalse(data["accepted"])
        self.assertIn("q", data["error"])

    @patch("urllib.request.urlopen")
    def test_map_search_proxies_nominatim_and_returns_real_place_results(self, urlopen):
        urlopen.return_value = FakeUrlopenResponse(
            [
                {
                    "osm_type": "relation",
                    "osm_id": 396488,
                    "display_name": "Los Padres National Forest, California, United States",
                    "lat": "34.6761",
                    "lon": "-119.9028",
                    "category": "boundary",
                    "type": "protected_area",
                    "boundingbox": [
                        "33.9432",
                        "35.8027",
                        "-121.7906",
                        "-118.4982",
                    ],
                }
            ]
        )

        response = self.client.get(
            "/api/map/search?q=Los%20Padres%20National%20Forest",
            headers=self.auth("viewer-token"),
        )

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["provider"], "nominatim")
        self.assertEqual(data["query"], "Los Padres National Forest")
        self.assertEqual(data["usagePolicy"]["status"], "limited-free-public-service")
        self.assertIn("1 request per second", data["usagePolicy"]["message"])
        self.assertEqual(len(data["results"]), 1)

        result = data["results"][0]
        self.assertEqual(result["id"], "relation/396488")
        self.assertEqual(
            result["displayName"],
            "Los Padres National Forest, California, United States",
        )
        self.assertEqual(result["lat"], 34.6761)
        self.assertEqual(result["lng"], -119.9028)
        self.assertEqual(result["category"], "boundary")
        self.assertEqual(result["type"], "protected_area")
        self.assertEqual(result["boundingBox"]["south"], 33.9432)
        self.assertEqual(result["boundingBox"]["north"], 35.8027)
        self.assertEqual(result["boundingBox"]["west"], -121.7906)
        self.assertEqual(result["boundingBox"]["east"], -118.4982)
        self.assertNotIn("MAP_API_KEY", json.dumps(data))

        request = urlopen.call_args.args[0]
        self.assertIn("q=Los+Padres+National+Forest", request.full_url)
        self.assertIn("format=jsonv2", request.full_url)
        self.assertEqual(
            request.headers["User-agent"],
            "FireDroneProject Tests",
        )

    def test_map_geofence_layer_returns_geojson_features(self):
        response = self.client.get(
            "/api/map/geofence",
            headers=self.auth("viewer-token"),
        )

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["type"], "FeatureCollection")
        self.assertEqual(data["source"], "backend-gis")
        self.assertGreaterEqual(len(data["features"]), 2)

        layer_types = {
            feature["properties"]["layerType"] for feature in data["features"]
        }
        self.assertIn("incident_perimeter", layer_types)
        self.assertIn("mission_geofence", layer_types)

        geofence = next(
            feature
            for feature in data["features"]
            if feature["properties"]["layerType"] == "mission_geofence"
        )
        self.assertEqual(geofence["geometry"]["type"], "Polygon")
        first_coord = geofence["geometry"]["coordinates"][0][0]
        self.assertEqual(len(first_coord), 2)
        self.assertLess(first_coord[0], 0)
        self.assertGreater(first_coord[1], 0)

    def test_map_mission_layer_returns_route_alerts_and_drone_markers(self):
        response = self.client.get(
            "/api/map/mission",
            headers=self.auth("viewer-token"),
        )

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["source"], "backend-mission-gis")
        self.assertEqual(data["route"]["id"], "canyon-ridge-route")
        self.assertGreaterEqual(len(data["route"]["points"]), 4)
        self.assertGreaterEqual(len(data["alerts"]), 2)
        self.assertGreaterEqual(len(data["drones"]), 1)
        self.assertEqual(data["bounds"]["source"], "computed-from-map-layers")
        self.assertLess(data["bounds"]["west"], data["bounds"]["east"])
        self.assertLess(data["bounds"]["south"], data["bounds"]["north"])

        first_route_point = data["route"]["points"][0]
        self.assertIn("lat", first_route_point)
        self.assertIn("lng", first_route_point)
        self.assertLess(first_route_point["lng"], 0)
        self.assertGreater(first_route_point["lat"], 0)
        self.assertIn("altitudeM", first_route_point)

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

        with closing(sqlite3.connect(self.db_file)) as connection:
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
