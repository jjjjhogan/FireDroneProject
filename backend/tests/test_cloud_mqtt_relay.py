import io
import json
import unittest
from unittest.mock import patch

from app.dji.cloud_mqtt_relay import (
    CloudIngestError,
    RateLimitedLogger,
    RelayConfig,
    RelayStats,
    mqtt_reason_succeeded,
    post_cloud_ingest,
    relay_config_from_env,
    validate_relay_config,
)


class CloudMqttRelayTest(unittest.TestCase):
    def test_validate_relay_config_requires_host_and_token(self):
        errors = validate_relay_config(
            RelayConfig(mqtt_host="", ingest_token="")
        )
        self.assertIn("DJI_CLOUD_API_MQTT_HOST or --mqtt-host is required", errors)
        self.assertIn("DJI_INGEST_TOKEN or --token is required", errors)

    def test_relay_config_from_env_reads_dji_variables(self):
        config = relay_config_from_env(
            {
                "DJI_CLOUD_API_MQTT_HOST": "mqtt.example.com",
                "DJI_INGEST_TOKEN": "bridge-secret",
                "FIRE_DRONE_API_BASE": "https://api.example.com/api",
                "DJI_CLOUD_MQTT_PORT": "8883",
                "DJI_CLOUD_MQTT_USERNAME": "dji-user",
                "DJI_CLOUD_MQTT_PASSWORD": "dji-pass",
                "DJI_CLOUD_MQTT_CLIENT_ID": "worker-1",
                "DJI_CLOUD_MQTT_TOPICS": "thing/product/+/osd,thing/product/+/events",
                "DJI_CLOUD_MQTT_USE_TLS": "true",
            }
        )
        self.assertEqual(config.mqtt_host, "mqtt.example.com")
        self.assertEqual(config.ingest_token, "bridge-secret")
        self.assertEqual(config.api_base, "https://api.example.com/api")
        self.assertEqual(config.mqtt_port, 8883)
        self.assertEqual(config.mqtt_username, "dji-user")
        self.assertEqual(config.topics[1], "thing/product/+/events")
        self.assertTrue(config.use_tls)

    def test_post_cloud_ingest_posts_topic_payload_envelope(self):
        captured = {}

        class FakeResponse:
            status = 202

            def read(self):
                return b'{"accepted":true}'

            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc, tb):
                del exc_type, exc, tb

        def fake_urlopen(request, timeout=8):
            captured["url"] = request.full_url
            captured["headers"] = dict(request.header_items())
            captured["body"] = json.loads(request.data.decode("utf-8"))
            captured["timeout"] = timeout
            return FakeResponse()

        with patch("urllib.request.urlopen", side_effect=fake_urlopen):
            status, body = post_cloud_ingest(
                "http://127.0.0.1:5000/api",
                "bridge-secret",
                "thing/product/demo/osd",
                {"data": {"latitude": 1.0}},
            )

        self.assertEqual(status, 202)
        self.assertEqual(body, '{"accepted":true}')
        self.assertEqual(
            captured["url"],
            "http://127.0.0.1:5000/api/dji/ingest/cloud-api",
        )
        self.assertEqual(
            captured["headers"]["Authorization"],
            "Bearer bridge-secret",
        )
        self.assertEqual(captured["body"]["topic"], "thing/product/demo/osd")
        self.assertEqual(captured["body"]["payload"]["data"]["latitude"], 1.0)

    def test_post_cloud_ingest_raises_on_http_error(self):
        import urllib.error

        payload = io.BytesIO(b'{"accepted":false,"error":"bad token"}')
        http_error = urllib.error.HTTPError(
            url="http://127.0.0.1:5000/api/dji/ingest/cloud-api",
            code=401,
            msg="Unauthorized",
            hdrs={},
            fp=payload,
        )

        with patch("urllib.request.urlopen", side_effect=http_error):
            with self.assertRaises(CloudIngestError) as ctx:
                post_cloud_ingest(
                    "http://127.0.0.1:5000/api",
                    "wrong-token",
                    "thing/product/demo/osd",
                    {"data": {}},
                )

        self.assertEqual(ctx.exception.status_code, 401)
        self.assertIn("bad token", ctx.exception.body)

    def test_mqtt_reason_succeeded_handles_reason_code_objects(self):
        class FakeReasonCode:
            is_success = True

        self.assertTrue(mqtt_reason_succeeded(FakeReasonCode()))
        self.assertTrue(mqtt_reason_succeeded(0))
        self.assertFalse(mqtt_reason_succeeded(1))

    def test_rate_limited_logger_prints_summary_on_interval(self):
        logger = RateLimitedLogger(interval_seconds=10.0, verbose=False)
        stats = RelayStats(
            messages_received=3,
            forwarded_ok=2,
            forward_failed=1,
            started_at=100.0,
        )
        messages = []

        with patch.object(logger, "info", side_effect=lambda msg: messages.append(msg)):
            with patch("app.dji.cloud_mqtt_relay.time.time", return_value=100.0):
                logger.maybe_summary(stats)
            with patch("app.dji.cloud_mqtt_relay.time.time", return_value=105.0):
                logger.maybe_summary(stats)

        self.assertEqual(len(messages), 1)
        self.assertIn("received=3", messages[0])


if __name__ == "__main__":
    unittest.main()
