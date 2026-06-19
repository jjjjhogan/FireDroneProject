import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.parse import parse_qs, urlparse

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import create_app


class FakeGoogleResponse:
    def __init__(self, payload):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, traceback):
        return False

    def read(self):
        return json.dumps(self.payload).encode("utf-8")


class AccountsApiTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.db_file = Path(self.temp_dir.name) / "accounts.sqlite3"
        config = type(
            "AccountsConfig",
            (),
            {
                "TESTING": True,
                "SECRET_KEY": "test",
                "DRONE_CONNECTOR": "real",
                "ALLOW_DJI_COMMANDS": False,
                "APP_DATABASE_FILE": str(self.db_file),
                "AUTH_REQUIRED": True,
                "PUBLIC_SAFETY_TOKENS": {},
                "DJI_AUTO_START_CLOUD_BRIDGE": False,
                "GOOGLE_OAUTH_RUNTIME_CONFIG_FILE": str(
                    Path(self.temp_dir.name) / "google_oauth_config.json"
                ),
            },
        )
        self.app = create_app(config)
        self.client = self.app.test_client()

    def auth(self, token):
        return {"Authorization": f"Bearer {token}"}

    def register(self, email="pilot@example.com", display_name="Incident Pilot"):
        return self.client.post(
            "/api/accounts/register",
            json={
                "email": email,
                "password": "strong-password-123",
                "displayName": display_name,
                "organization": "AeroScout Ops",
            },
        )

    def assert_registered(self, email="pilot@example.com", display_name="Incident Pilot"):
        response = self.register(email=email, display_name=display_name)
        self.assertEqual(response.status_code, 201)
        data = response.get_json()
        self.assertIsNotNone(data)
        return data

    def test_register_creates_account_session_and_default_bound_data(self):
        response = self.register()

        self.assertEqual(response.status_code, 201)
        data = response.get_json()
        self.assertTrue(data["accepted"])
        self.assertGreater(len(data["token"]), 30)
        self.assertEqual(data["account"]["email"], "pilot@example.com")
        self.assertEqual(data["account"]["displayName"], "Incident Pilot")
        self.assertEqual(data["account"]["organization"], "AeroScout Ops")
        self.assertEqual(data["account"]["role"], "operator")
        self.assertIn("accountId", data["account"])
        self.assertNotIn("password", data["account"])
        self.assertEqual(
            data["account"]["data"]["djiConnection"]["mode"],
            "not-configured",
        )
        self.assertTrue(
            data["account"]["data"]["missionPreferences"][
                "safetyChecklistRequired"
            ]
        )

        session = self.client.get("/api/accounts/me", headers=self.auth(data["token"]))
        self.assertEqual(session.status_code, 200)
        self.assertEqual(
            session.get_json()["account"]["accountId"],
            data["account"]["accountId"],
        )

    def test_rejects_duplicate_email_and_bad_login(self):
        self.assertEqual(self.register().status_code, 201)

        duplicate = self.register(display_name="Other Pilot")
        self.assertEqual(duplicate.status_code, 409)
        self.assertIn("already exists", duplicate.get_json()["error"])

        bad_password = self.client.post(
            "/api/accounts/login",
            json={"email": "pilot@example.com", "password": "wrong-password"},
        )
        self.assertEqual(bad_password.status_code, 401)

    def test_login_and_account_data_are_bound_to_the_authenticated_account(self):
        first = self.assert_registered()
        second = self.assert_registered("airboss@example.com", "Air Boss")

        update = self.client.put(
            "/api/accounts/data",
            headers=self.auth(first["token"]),
            json={
                "profile": {
                    "organization": "AeroScout Ops",
                    "roleLabel": "Mission commander",
                },
                "djiConnection": {
                    "mode": "cloud-api",
                    "operatorLabel": "Canyon Ridge Team",
                    "workspaceId": "workspace-alpha",
                },
                "missionPreferences": {
                    "defaultScenario": "Canyon Ridge Fire",
                    "mapBasemap": "satellite",
                    "safetyChecklistRequired": True,
                },
                "savedMissions": [
                    {
                        "missionId": "mission-canyon-ridge-preview",
                        "scenarioId": "canyon-ridge-fire",
                    }
                ],
            },
        )

        self.assertEqual(update.status_code, 200)
        self.assertEqual(update.get_json()["data"]["djiConnection"]["mode"], "cloud-api")

        login = self.client.post(
            "/api/accounts/login",
            json={
                "email": "pilot@example.com",
                "password": "strong-password-123",
            },
        )
        self.assertEqual(login.status_code, 200)
        token = login.get_json()["token"]

        first_data = self.client.get("/api/accounts/data", headers=self.auth(token))
        self.assertEqual(first_data.status_code, 200)
        self.assertEqual(
            first_data.get_json()["data"]["djiConnection"]["workspaceId"],
            "workspace-alpha",
        )
        self.assertEqual(len(first_data.get_json()["data"]["savedMissions"]), 1)

        second_data = self.client.get(
            "/api/accounts/data",
            headers=self.auth(second["token"]),
        )
        self.assertEqual(second_data.status_code, 200)
        self.assertEqual(
            second_data.get_json()["data"]["djiConnection"]["mode"],
            "not-configured",
        )
        self.assertEqual(second_data.get_json()["data"]["savedMissions"], [])

    def test_account_session_token_can_authorize_existing_rbac_routes(self):
        account = self.assert_registered()

        response = self.client.get(
            "/api/auth/session",
            headers=self.auth(account["token"]),
        )

        self.assertEqual(response.status_code, 200)
        session = response.get_json()
        self.assertTrue(session["authenticated"])
        self.assertEqual(session["actor"], "pilot@example.com")
        self.assertEqual(session["role"], "operator")

    def test_logout_revokes_account_session(self):
        account = self.assert_registered()

        logout = self.client.post(
            "/api/accounts/logout",
            headers=self.auth(account["token"]),
        )

        self.assertEqual(logout.status_code, 200)
        self.assertTrue(logout.get_json()["accepted"])

        session = self.client.get(
            "/api/accounts/me",
            headers=self.auth(account["token"]),
        )
        self.assertEqual(session.status_code, 401)

    def test_google_oauth_status_reports_not_configured(self):
        response = self.client.get("/api/accounts/google/status")

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["provider"], "google")
        self.assertFalse(data["configured"])
        self.assertIn("GOOGLE_OAUTH_CLIENT_ID", data["missingConfiguration"])
        self.assertIn("GOOGLE_OAUTH_CLIENT_SECRET", data["missingConfiguration"])
        self.assertTrue(data["setupAllowed"])

    def test_google_oauth_config_can_be_saved_at_runtime(self):
        response = self.client.put(
            "/api/accounts/google/config",
            json={
                "clientId": "runtime-client-id.apps.googleusercontent.com",
                "clientSecret": "runtime-client-secret",
                "redirectUri": "http://127.0.0.1:5000/api/accounts/google/callback",
            },
        )

        self.assertEqual(response.status_code, 200)
        saved = response.get_json()
        self.assertTrue(saved["accepted"])
        self.assertTrue(saved["configured"])
        self.assertTrue(saved["clientIdConfigured"])
        self.assertTrue(saved["clientSecretConfigured"])
        self.assertNotIn("runtime-client-secret", json.dumps(saved))

        status = self.client.get("/api/accounts/google/status")
        self.assertEqual(status.status_code, 200)
        status_data = status.get_json()
        self.assertTrue(status_data["configured"])
        self.assertEqual(status_data["missingConfiguration"], [])
        self.assertTrue(status_data["setupAllowed"])

        start = self.client.get(
            "/api/accounts/google/start?returnUrl=http://127.0.0.1:8151/"
        )
        self.assertEqual(start.status_code, 200)
        parsed = urlparse(start.get_json()["authorizationUrl"])
        params = parse_qs(parsed.query)
        self.assertEqual(
            params["client_id"],
            ["runtime-client-id.apps.googleusercontent.com"],
        )

    def test_google_oauth_runtime_config_is_localhost_only(self):
        response = self.client.put(
            "/api/accounts/google/config",
            json={
                "clientId": "runtime-client-id.apps.googleusercontent.com",
                "clientSecret": "runtime-client-secret",
                "redirectUri": "http://127.0.0.1:5000/api/accounts/google/callback",
            },
            environ_base={"REMOTE_ADDR": "203.0.113.10"},
        )

        self.assertEqual(response.status_code, 403)
        self.assertIn("localhost", response.get_json()["error"])

        status = self.client.get(
            "/api/accounts/google/status",
            environ_base={"REMOTE_ADDR": "203.0.113.10"},
        )
        self.assertFalse(status.get_json()["setupAllowed"])

    def google_client(self):
        config = type(
            "GoogleOAuthConfig",
            (),
            {
                "TESTING": True,
                "SECRET_KEY": "test",
                "DRONE_CONNECTOR": "real",
                "ALLOW_DJI_COMMANDS": False,
                "APP_DATABASE_FILE": str(self.db_file),
                "AUTH_REQUIRED": True,
                "PUBLIC_SAFETY_TOKENS": {},
                "DJI_AUTO_START_CLOUD_BRIDGE": False,
                "GOOGLE_OAUTH_CLIENT_ID": "google-client-id",
                "GOOGLE_OAUTH_CLIENT_SECRET": "google-client-secret",
                "GOOGLE_OAUTH_REDIRECT_URI": (
                    "http://127.0.0.1:5000/api/accounts/google/callback"
                ),
                "GOOGLE_OAUTH_AUTH_URL": "https://accounts.google.com/o/oauth2/v2/auth",
                "GOOGLE_OAUTH_TOKEN_URL": "https://oauth2.googleapis.com/token",
                "GOOGLE_OAUTH_USERINFO_URL": (
                    "https://openidconnect.googleapis.com/v1/userinfo"
                ),
                "FRONTEND_APP_URL": "http://127.0.0.1:8151/",
                "GOOGLE_OAUTH_RUNTIME_CONFIG_FILE": str(
                    Path(self.temp_dir.name) / "google_oauth_config.json"
                ),
            },
        )
        return create_app(config).test_client()

    def test_google_oauth_start_builds_real_google_authorization_url(self):
        client = self.google_client()

        response = client.get(
            "/api/accounts/google/start?returnUrl=http://127.0.0.1:8151/"
        )

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data["configured"])
        self.assertEqual(data["provider"], "google")

        parsed = urlparse(data["authorizationUrl"])
        params = parse_qs(parsed.query)
        self.assertEqual(parsed.netloc, "accounts.google.com")
        self.assertEqual(params["client_id"], ["google-client-id"])
        self.assertEqual(
            params["redirect_uri"],
            ["http://127.0.0.1:5000/api/accounts/google/callback"],
        )
        self.assertEqual(params["response_type"], ["code"])
        self.assertIn("openid", params["scope"][0])
        self.assertIn("email", params["scope"][0])
        self.assertIn("profile", params["scope"][0])
        self.assertEqual(len(params["state"][0]), 43)

    @patch("urllib.request.urlopen")
    def test_google_callback_creates_account_and_login_code_session(self, urlopen):
        client = self.google_client()
        start_response = client.get(
            "/api/accounts/google/start?returnUrl=http://127.0.0.1:8151/"
        )
        self.assertEqual(start_response.status_code, 200)
        start = start_response.get_json()
        state = parse_qs(urlparse(start["authorizationUrl"]).query)["state"][0]

        def fake_urlopen(request, timeout=None):
            url = request.full_url
            if "oauth2.googleapis.com/token" in url:
                body = request.data.decode("utf-8")
                self.assertIn("grant_type=authorization_code", body)
                self.assertIn("client_id=google-client-id", body)
                self.assertIn("client_secret=google-client-secret", body)
                self.assertIn("code=google-code", body)
                return FakeGoogleResponse(
                    {
                        "access_token": "google-access-token",
                        "token_type": "Bearer",
                        "expires_in": 3600,
                    }
                )
            if "openidconnect.googleapis.com/v1/userinfo" in url:
                self.assertEqual(
                    request.headers["Authorization"],
                    "Bearer google-access-token",
                )
                return FakeGoogleResponse(
                    {
                        "sub": "google-subject-001",
                        "email": "googlepilot@example.com",
                        "name": "Google Pilot",
                        "picture": "https://example.com/pilot.png",
                    }
                )
            raise AssertionError(f"Unexpected Google URL: {url}")

        urlopen.side_effect = fake_urlopen

        callback = client.get(
            f"/api/accounts/google/callback?code=google-code&state={state}",
            follow_redirects=False,
        )

        self.assertEqual(callback.status_code, 302)
        redirect = urlparse(callback.headers["Location"])
        self.assertEqual(f"{redirect.scheme}://{redirect.netloc}/", "http://127.0.0.1:8151/")
        params = parse_qs(redirect.query)
        self.assertEqual(params["provider"], ["google"])
        login_code = params["accountLoginCode"][0]
        self.assertGreater(len(login_code), 30)

        complete = client.post(
            "/api/accounts/session/complete",
            json={"loginCode": login_code},
        )
        self.assertEqual(complete.status_code, 200)
        session = complete.get_json()
        self.assertTrue(session["accepted"])
        self.assertGreater(len(session["token"]), 30)
        self.assertEqual(session["account"]["email"], "googlepilot@example.com")
        self.assertEqual(session["account"]["displayName"], "Google Pilot")
        self.assertEqual(session["account"]["authProvider"], "google")

        reused = client.post(
            "/api/accounts/session/complete",
            json={"loginCode": login_code},
        )
        self.assertEqual(reused.status_code, 401)


if __name__ == "__main__":
    unittest.main()
