import unittest
from unittest.mock import patch

from app.dji.demo_ingest_worker import (
    DemoIngestConfig,
    run_demo_ingest_worker,
    validate_demo_config,
)
from app.dji.demo_patrol import build_cloud_osd_payload, cloud_osd_topic
from app.dji.demo_scenarios import DEMO_SCENARIOS, scenario_ids


class DemoPatrolTest(unittest.TestCase):
    def test_build_cloud_osd_payload_has_device_fields(self):
        payload = build_cloud_osd_payload("demo-aircraft", 1)
        data = payload["data"]
        self.assertEqual(data["device_sn"], "demo-aircraft")
        self.assertAlmostEqual(data["latitude"], 37.2064, places=3)
        self.assertEqual(data["scenario_id"], "canyon-ridge")
        self.assertIn("battery", data)

    def test_all_live_simulator_scenarios_have_demo_routes(self):
        self.assertEqual(len(scenario_ids()), 10)
        for scenario_id, scenario in DEMO_SCENARIOS.items():
            with self.subTest(scenario_id=scenario_id):
                self.assertGreaterEqual(len(scenario.waypoints), 5)
                self.assertEqual(scenario.waypoints[0].mode, "takeoff")
                self.assertEqual(scenario.waypoints[-1].mode, "return-to-home")

    def test_scenario_payloads_use_distinct_routes_and_labels(self):
        ridge = build_cloud_osd_payload("demo-aircraft", 1, scenario_id="canyon-ridge")
        fog = build_cloud_osd_payload("demo-aircraft", 1, scenario_id="santa-cruz-fog")

        self.assertNotEqual(ridge["data"]["latitude"], fog["data"]["latitude"])
        self.assertNotEqual(ridge["data"]["longitude"], fog["data"]["longitude"])
        self.assertEqual(fog["data"]["scenario_id"], "santa-cruz-fog")
        self.assertEqual(fog["data"]["device_name"], "Demo Mavic Fog Unit")
        self.assertEqual(fog["data"]["fire_perimeter_risk"], "marine-layer-visibility")

    def test_cloud_osd_topic_format(self):
        self.assertEqual(
            cloud_osd_topic("demo-aircraft"),
            "thing/product/demo-aircraft/osd",
        )


class DemoIngestWorkerTest(unittest.TestCase):
    def test_validate_demo_config_rejects_unknown_scenario(self):
        errors = validate_demo_config(
            DemoIngestConfig(
                ingest_token="bridge-secret",
                scenario_id="not-a-live-simulator-scenario",
            )
        )

        self.assertIn("DJI_DEMO_SCENARIO must be one of:", errors[0])

    def test_run_demo_ingest_worker_posts_once(self):
        config = DemoIngestConfig(
            ingest_token="bridge-secret",
            api_base="http://127.0.0.1:5000/api",
            scenario_id="colorado-plateau",
            once=True,
            verbose=False,
        )
        captured = {}

        class FakeResponse:
            status = 202

            def read(self):
                return b'{"accepted":true,"source":"dji-cloud-api"}'

            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc, tb):
                del exc_type, exc, tb

        def fake_urlopen(request, timeout=8):
            captured["url"] = request.full_url
            captured["body"] = __import__("json").loads(request.data.decode("utf-8"))
            return FakeResponse()

        with patch("urllib.request.urlopen", side_effect=fake_urlopen):
            code = run_demo_ingest_worker(config)

        self.assertEqual(code, 0)
        self.assertIn("/dji/ingest/cloud-api", captured["url"])
        self.assertEqual(
            captured["body"]["topic"],
            "thing/product/demo-aircraft/osd",
        )
        data = captured["body"]["payload"]["data"]
        self.assertEqual(data["scenario_id"], "colorado-plateau")
        self.assertEqual(data["device_name"], "Demo Plateau Watch Unit")


if __name__ == "__main__":
    unittest.main()
