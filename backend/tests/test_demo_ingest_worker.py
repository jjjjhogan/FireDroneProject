import unittest
from unittest.mock import patch

from app.dji.demo_ingest_worker import DemoIngestConfig, run_demo_ingest_worker
from app.dji.demo_patrol import build_cloud_osd_payload, cloud_osd_topic


class DemoPatrolTest(unittest.TestCase):
    def test_build_cloud_osd_payload_has_device_fields(self):
        payload = build_cloud_osd_payload("demo-aircraft", 1)
        data = payload["data"]
        self.assertEqual(data["device_sn"], "demo-aircraft")
        self.assertAlmostEqual(data["latitude"], 37.2064, places=3)
        self.assertIn("battery", data)

    def test_cloud_osd_topic_format(self):
        self.assertEqual(
            cloud_osd_topic("demo-aircraft"),
            "thing/product/demo-aircraft/osd",
        )


class DemoIngestWorkerTest(unittest.TestCase):
    def test_run_demo_ingest_worker_posts_once(self):
        config = DemoIngestConfig(
            ingest_token="bridge-secret",
            api_base="http://127.0.0.1:5000/api",
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


if __name__ == "__main__":
    unittest.main()
