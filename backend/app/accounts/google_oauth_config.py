import json
from pathlib import Path
from urllib.parse import urlparse

from app.dji.state_store import utc_now_iso


def _clean_string(value, default="", max_length=1024):
    if value is None:
        return default
    text = str(value).strip()
    if not text:
        return default
    return text[:max_length]


class GoogleOAuthRuntimeConfigStore:
    def __init__(self, path):
        self.path = Path(path)

    def read(self):
        if not self.path.exists():
            return {}
        try:
            with self.path.open("r", encoding="utf-8") as file:
                data = json.load(file)
        except (OSError, json.JSONDecodeError):
            return {}
        return data if isinstance(data, dict) else {}

    def write_from_payload(self, payload, default_redirect_uri):
        payload = payload if isinstance(payload, dict) else {}
        existing = self.read()
        client_id = _clean_string(
            payload.get("clientId"),
            existing.get("GOOGLE_OAUTH_CLIENT_ID", ""),
        )
        client_secret = _clean_string(
            payload.get("clientSecret"),
            existing.get("GOOGLE_OAUTH_CLIENT_SECRET", ""),
        )
        redirect_uri = _clean_string(
            payload.get("redirectUri"),
            existing.get("GOOGLE_OAUTH_REDIRECT_URI") or default_redirect_uri,
        )
        if not client_id:
            raise ValueError("clientId is required")
        if not client_secret:
            raise ValueError("clientSecret is required")
        parsed_redirect = urlparse(redirect_uri)
        if parsed_redirect.scheme not in {"http", "https"} or not parsed_redirect.netloc:
            raise ValueError("redirectUri must be an http or https URL")

        updated = {
            **existing,
            "GOOGLE_OAUTH_CLIENT_ID": client_id,
            "GOOGLE_OAUTH_CLIENT_SECRET": client_secret,
            "GOOGLE_OAUTH_REDIRECT_URI": redirect_uri,
            "updatedAt": utc_now_iso(),
        }
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temp_path = self.path.with_suffix(f"{self.path.suffix}.tmp")
        with temp_path.open("w", encoding="utf-8") as file:
            json.dump(updated, file, indent=2, sort_keys=True)
        temp_path.replace(self.path)
        return updated

    def effective_config(self, base_config):
        effective = dict(base_config)
        for key, value in self.read().items():
            if key == "updatedAt":
                continue
            if value not in (None, ""):
                effective[key] = value
        return effective

    def public_config(self, base_config, default_redirect_uri):
        config = self.effective_config(base_config)
        client_id = str(config.get("GOOGLE_OAUTH_CLIENT_ID", "")).strip()
        client_secret = str(config.get("GOOGLE_OAUTH_CLIENT_SECRET", "")).strip()
        redirect_uri = str(
            config.get("GOOGLE_OAUTH_REDIRECT_URI", "") or default_redirect_uri
        ).strip()
        return {
            "clientIdConfigured": bool(client_id),
            "clientSecretConfigured": bool(client_secret),
            "configured": bool(client_id and client_secret),
            "redirectUri": redirect_uri,
            "updatedAt": self.read().get("updatedAt"),
        }
