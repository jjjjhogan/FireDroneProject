import secrets
import json
import urllib.parse
import urllib.request

from flask import current_app, redirect, request

from app.accounts.google_oauth_config import GoogleOAuthRuntimeConfigStore
from app.accounts.store import (
    AccountError,
    AccountStore,
    AuthenticationError,
    OAuthStateError,
)
from app.db import create_database
from app.dji import create_dji_connector
from app.dji.cloud_api import cloud_api_message_to_ingest_payload
from app.dji.cloud_bridge import cloud_bridge_manager, try_start_cloud_bridge
from app.dji.ingest import normalize_ingest_payload
from app.dji.mobile_sdk import mobile_sdk_state_to_ingest_payload
from app.dji.runtime_config import DjiRuntimeConfigStore
from app.dji.state_store import DjiStateStore, utc_now_iso
from app.ops import (
    OperationsStore,
    mavlink_payload_to_ingest_payload,
    normalize_detection_payload,
    simulate_command,
)
from app.ops.analytics import ANALYTICS_SUMMARY, analytics_graphs_payload
from app.ops.map_layers import (
    active_scenario_id_from_state,
    geofence_map_layer,
    map_center_for_scenario,
    mission_map_layer,
)
from app.ops.map_search import MapSearchError, search_nominatim_places
from app.routes import api_bp
from app.security import require_roles


@api_bp.route("/status", methods=["GET"])
def status():
    return {
        "message": "FireDrone API is running",
        "version": "0.1.0",
    }


@api_bp.route("/analytics/summary", methods=["GET"])
def analytics_summary():
    return ANALYTICS_SUMMARY


@api_bp.route("/analytics/graphs", methods=["GET"])
def analytics_graphs():
    return analytics_graphs_payload()


def _dji_connector():
    return create_dji_connector(_runtime_config_store().effective_config(current_app.config))


def _runtime_config_store():
    return DjiRuntimeConfigStore(
        current_app.config.get(
            "DJI_RUNTIME_CONFIG_FILE",
            "instance/dji_runtime_config.json",
        )
    )


def _authorized_ingest():
    effective_config = _runtime_config_store().effective_config(current_app.config)
    expected = str(effective_config.get("DJI_INGEST_TOKEN", "")).strip()
    if not expected:
        return False
    header = request.headers.get("Authorization", "")
    return header == f"Bearer {expected}"


def _dji_state_store():
    return DjiStateStore(
        current_app.config.get("DJI_STATE_FILE", "instance/dji_state.json"),
        current_app.config.get("DJI_TELEMETRY_TTL_SECONDS", 300),
    )


def _active_map_scenario_id():
    state_store = _dji_state_store()
    state = state_store.read()
    if not state_store.is_fresh(state):
        return None
    return active_scenario_id_from_state(state)


def _database():
    return create_database(current_app.config)


def _operations_store():
    return OperationsStore(database=_database())


def _account_store():
    return AccountStore(database=_database())


def _google_oauth_runtime_config_store():
    return GoogleOAuthRuntimeConfigStore(
        current_app.config.get(
            "GOOGLE_OAUTH_RUNTIME_CONFIG_FILE",
            "instance/google_oauth_config.json",
        )
    )


def _google_oauth_runtime_setup_allowed():
    if not current_app.config.get("GOOGLE_OAUTH_RUNTIME_CONFIG_ALLOWED", True):
        return False
    return request.remote_addr in {"127.0.0.1", "::1", "localhost"}


def _account_from_bearer():
    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        return None, ({"error": "Missing account bearer token"}, 401)
    token = header.removeprefix("Bearer ").strip()
    account = _account_store().account_for_token(token)
    if account is None:
        return None, ({"error": "Invalid account bearer token"}, 401)
    return account, None


def _bearer_token():
    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        return ""
    return header.removeprefix("Bearer ").strip()


def _account_response(token, account, status_code=200):
    return {
        "accepted": True,
        "tokenType": "Bearer",
        "token": token,
        "account": account,
    }, status_code


def _account_error(error):
    status_code = getattr(error, "status_code", 400)
    return {"accepted": False, "error": str(error)}, status_code


def _google_oauth_config():
    effective_config = _google_oauth_runtime_config_store().effective_config(
        current_app.config
    )
    client_id = str(effective_config.get("GOOGLE_OAUTH_CLIENT_ID", "")).strip()
    client_secret = str(
        effective_config.get("GOOGLE_OAUTH_CLIENT_SECRET", "")
    ).strip()
    host_url = request.host_url.rstrip("/")
    redirect_uri = str(
        effective_config.get("GOOGLE_OAUTH_REDIRECT_URI", "")
        or f"{host_url}/api/accounts/google/callback"
    ).strip()
    return {
        "clientId": client_id,
        "clientSecret": client_secret,
        "redirectUri": redirect_uri,
        "authUrl": str(
            effective_config.get(
                "GOOGLE_OAUTH_AUTH_URL",
                "https://accounts.google.com/o/oauth2/v2/auth",
            )
        ).strip(),
        "tokenUrl": str(
            effective_config.get(
                "GOOGLE_OAUTH_TOKEN_URL",
                "https://oauth2.googleapis.com/token",
            )
        ).strip(),
        "userinfoUrl": str(
            effective_config.get(
                "GOOGLE_OAUTH_USERINFO_URL",
                "https://openidconnect.googleapis.com/v1/userinfo",
            )
        ).strip(),
    }


def _missing_google_config(config):
    missing = []
    if not config["clientId"]:
        missing.append("GOOGLE_OAUTH_CLIENT_ID")
    if not config["clientSecret"]:
        missing.append("GOOGLE_OAUTH_CLIENT_SECRET")
    return missing


def _frontend_url():
    return str(
        current_app.config.get("FRONTEND_APP_URL", "http://127.0.0.1:8151/")
    ).strip()


def _safe_return_url(value):
    fallback = _frontend_url()
    candidate = str(value or fallback).strip() or fallback
    fallback_parts = urllib.parse.urlparse(fallback)
    candidate_parts = urllib.parse.urlparse(candidate)
    if (
        candidate_parts.scheme in {"http", "https"}
        and candidate_parts.netloc == fallback_parts.netloc
    ):
        return candidate
    return fallback


def _append_query(url, params):
    parts = urllib.parse.urlparse(url)
    query = dict(urllib.parse.parse_qsl(parts.query, keep_blank_values=True))
    query.update(params)
    return urllib.parse.urlunparse(
        parts._replace(query=urllib.parse.urlencode(query))
    )


def _json_post(url, payload):
    data = urllib.parse.urlencode(payload).encode("utf-8")
    request_obj = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(request_obj, timeout=15) as response:
        return json.loads(response.read().decode("utf-8"))


def _json_get(url, token):
    request_obj = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
        method="GET",
    )
    with urllib.request.urlopen(request_obj, timeout=15) as response:
        return json.loads(response.read().decode("utf-8"))


def _write_ingest(payload):
    store = _dji_state_store()

    normalized = normalize_ingest_payload(
        payload,
        received_at=utc_now_iso(),
        max_drones=current_app.config.get("DJI_MAX_INGEST_DRONES", 16),
    )
    if not normalized["accepted"]:
        return (
            {
                "accepted": False,
                "errors": normalized["errors"],
                "warnings": normalized["warnings"],
            },
            400,
        )
    state = store.write_state(normalized["state"])
    return (
        {
            "accepted": True,
            "source": state["source"],
            "receivedAt": state["receivedAt"],
            "drones": len(state["drones"]),
            "warnings": state.get("warnings") or [],
        },
        202,
    )


def _write_readonly_aircraft_ingest(payload, identity):
    response, status_code = _write_ingest(payload)
    if status_code < 400:
        _operations_store().record_audit(
            actor=identity["actor"],
            role=identity["role"],
            action="Read-only telemetry ingest",
            target_id=payload.get("bridge", {}).get("deviceId", "unknown"),
            details=f"{payload.get('source', 'unknown')} accepted as read-only telemetry",
        )
        response = {
            **response,
            "mode": "read-only",
            "bridge": payload.get("bridge", {}),
        }
    return response, status_code


@api_bp.route("/dji/status", methods=["GET"])
def dji_status():
    return _dji_connector().status()


@api_bp.route("/dji/fleet", methods=["GET"])
def dji_fleet():
    return _dji_connector().fleet()


@api_bp.route("/dji/telemetry", methods=["GET"])
def dji_telemetry():
    return _dji_connector().telemetry()


@api_bp.route("/dji/connection", methods=["GET"])
def dji_connection():
    return {
        **_runtime_config_store().public_config(request.host_url.rstrip("/")),
        "cloudBridge": cloud_bridge_manager.status(),
    }


@api_bp.route("/dji/connection", methods=["POST"])
def dji_save_connection():
    payload = request.get_json(silent=True) or {}
    try:
        _runtime_config_store().write_from_payload(payload)
    except ValueError as error:
        return {"accepted": False, "error": str(error)}, 400
    config = _runtime_config_store().public_config(request.host_url.rstrip("/"))
    bridge_status = cloud_bridge_manager.status()
    auto_start = bool(payload.get("autoStartCloudBridge", True))
    if auto_start and config["mode"] == "cloud-api" and config["configured"]:
        bridge_status = try_start_cloud_bridge(
            current_app.config,
            _runtime_config_store(),
        )
    return {
        "accepted": True,
        "config": {**config, "cloudBridge": bridge_status},
    }


@api_bp.route("/dji/connection/token", methods=["POST"])
def dji_generate_connection_token():
    return {"token": secrets.token_urlsafe(32)}


@api_bp.route("/dji/ingest/state", methods=["POST"])
def dji_ingest_state():
    if not _authorized_ingest():
        return {"accepted": False, "error": "Unauthorized DJI ingest"}, 401

    payload = request.get_json(silent=True) or {}
    return _write_ingest(payload)


@api_bp.route("/dji/ingest/cloud-api", methods=["POST"])
def dji_ingest_cloud_api():
    if not _authorized_ingest():
        return {"accepted": False, "error": "Unauthorized DJI ingest"}, 401

    payload = request.get_json(silent=True) or {}
    return _write_ingest(cloud_api_message_to_ingest_payload(payload))


@api_bp.route("/dji/ingest/mobile-sdk", methods=["POST"])
def dji_ingest_mobile_sdk():
    if not _authorized_ingest():
        return {"accepted": False, "error": "Unauthorized DJI ingest"}, 401

    payload = request.get_json(silent=True) or {}
    return _write_ingest(mobile_sdk_state_to_ingest_payload(payload))


@api_bp.route("/dji/missions/preview", methods=["POST"])
def dji_mission_preview():
    payload = request.get_json(silent=True) or {}
    result = _dji_connector().preview_mission(payload)
    if isinstance(result, tuple):
        preview, status_code = result
    else:
        preview, status_code = result, 200

    active = _operations_store().get_active_mission()
    if active:
        try:
            _operations_store().apply_preview(active["missionId"], preview)
        except ValueError:
            pass
    return preview, status_code


@api_bp.route("/dji/missions/confirm", methods=["POST"])
def dji_mission_confirm():
    payload = request.get_json(silent=True) or {}
    response, status_code = _dji_connector().confirm_mission(payload)
    active = _operations_store().get_active_mission()
    if active:
        try:
            updated = _operations_store().confirm_mission_record(
                active["missionId"],
                response,
            )
            if response.get("accepted"):
                response = {**response, "missionId": updated["missionId"]}
        except ValueError:
            pass
    return response, status_code


@api_bp.route("/missions/active", methods=["GET"])
@require_roles("viewer")
def missions_active(identity):
    mission = _operations_store().get_active_mission()
    return {"mission": mission}


@api_bp.route("/missions", methods=["GET"])
@require_roles("viewer")
def missions_list(identity):
    limit = request.args.get("limit", 20)
    return {"missions": _operations_store().list_missions(limit=limit)}


@api_bp.route("/missions/plan", methods=["POST"])
@require_roles("operator")
def missions_plan(identity):
    payload = request.get_json(silent=True) or {}
    mission = _operations_store().plan_mission(payload)
    _operations_store().record_audit(
        actor=identity["actor"],
        role=identity["role"],
        action="Planned mission",
        target_id=mission["missionId"],
        details=f"{mission['scenarioName']} · {mission['status']}",
    )
    return {"mission": mission}


@api_bp.route("/missions/<mission_id>/transition", methods=["POST"])
@require_roles("operator")
def missions_transition(identity, mission_id):
    payload = request.get_json(silent=True) or {}
    status = str(payload.get("status", "")).strip()
    notes = payload.get("notes")
    progress_pct = payload.get("progressPct")
    store = _operations_store()
    try:
        mission = store.transition_mission(
            mission_id,
            status,
            notes=notes,
            progress_pct=progress_pct,
        )
    except ValueError as error:
        return {"accepted": False, "error": str(error)}, 400

    store.record_audit(
        actor=identity["actor"],
        role=identity["role"],
        action=f"Mission {status}",
        target_id=mission_id,
        details=mission["notes"],
    )
    return {"accepted": True, "mission": mission}


@api_bp.route("/auth/session", methods=["GET"])
@require_roles("viewer")
def auth_session(identity):
    return {
        "authenticated": identity["authenticated"],
        "actor": identity["actor"],
        "role": identity["role"],
        "rbacEnabled": bool(current_app.config.get("AUTH_REQUIRED", False)),
    }


@api_bp.route("/accounts/register", methods=["POST"])
def register_account():
    payload = request.get_json(silent=True) or {}
    try:
        token, account = _account_store().register(payload)
    except AccountError as error:
        return _account_error(error)
    return _account_response(token, account, 201)


@api_bp.route("/accounts/login", methods=["POST"])
def login_account():
    payload = request.get_json(silent=True) or {}
    try:
        token, account = _account_store().login(payload)
    except AuthenticationError as error:
        return _account_error(error)
    except AccountError as error:
        return _account_error(error)
    return _account_response(token, account)


@api_bp.route("/accounts/session/complete", methods=["POST"])
def complete_account_login_code():
    payload = request.get_json(silent=True) or {}
    try:
        token, account = _account_store().complete_login_code(payload.get("loginCode"))
    except AuthenticationError as error:
        return _account_error(error)
    return _account_response(token, account)


@api_bp.route("/accounts/google/status", methods=["GET"])
def google_oauth_status():
    config = _google_oauth_config()
    missing = _missing_google_config(config)
    public_config = _google_oauth_runtime_config_store().public_config(
        current_app.config,
        config["redirectUri"],
    )
    return {
        "provider": "google",
        "configured": not missing,
        "missingConfiguration": missing,
        "redirectUri": config["redirectUri"],
        "scope": "openid email profile",
        "clientIdConfigured": public_config["clientIdConfigured"],
        "clientSecretConfigured": public_config["clientSecretConfigured"],
        "setupAllowed": _google_oauth_runtime_setup_allowed(),
        "updatedAt": public_config["updatedAt"],
    }


@api_bp.route("/accounts/google/config", methods=["PUT"])
def save_google_oauth_config():
    if not _google_oauth_runtime_setup_allowed():
        return {
            "accepted": False,
            "error": "Google OAuth runtime setup is only available from localhost",
        }, 403
    config = _google_oauth_config()
    payload = request.get_json(silent=True) or {}
    try:
        _google_oauth_runtime_config_store().write_from_payload(
            payload,
            config["redirectUri"],
        )
    except ValueError as error:
        return {"accepted": False, "error": str(error)}, 400
    updated = _google_oauth_config()
    public_config = _google_oauth_runtime_config_store().public_config(
        current_app.config,
        updated["redirectUri"],
    )
    return {
        "accepted": True,
        "provider": "google",
        "configured": public_config["configured"],
        "missingConfiguration": _missing_google_config(updated),
        "redirectUri": updated["redirectUri"],
        "scope": "openid email profile",
        "clientIdConfigured": public_config["clientIdConfigured"],
        "clientSecretConfigured": public_config["clientSecretConfigured"],
        "setupAllowed": _google_oauth_runtime_setup_allowed(),
        "updatedAt": public_config["updatedAt"],
    }


@api_bp.route("/accounts/google/start", methods=["GET"])
def start_google_oauth():
    config = _google_oauth_config()
    missing = _missing_google_config(config)
    if missing:
        return {
            "provider": "google",
            "configured": False,
            "missingConfiguration": missing,
            "error": "Google OAuth is not configured",
        }, 409

    return_url = _safe_return_url(request.args.get("returnUrl"))
    state = _account_store().create_oauth_state("google", return_url)
    params = {
        "client_id": config["clientId"],
        "redirect_uri": config["redirectUri"],
        "response_type": "code",
        "scope": "openid email profile",
        "state": state,
        "access_type": "offline",
        "prompt": "select_account",
        "include_granted_scopes": "true",
    }
    return {
        "provider": "google",
        "configured": True,
        "authorizationUrl": f"{config['authUrl']}?{urllib.parse.urlencode(params)}",
    }


@api_bp.route("/accounts/google/callback", methods=["GET"])
def google_oauth_callback():
    config = _google_oauth_config()
    code = request.args.get("code", "").strip()
    state = request.args.get("state", "").strip()
    try:
        return_url = _account_store().consume_oauth_state("google", state)
        if not code:
            raise AccountError("Missing Google authorization code")
        token_response = _json_post(
            config["tokenUrl"],
            {
                "code": code,
                "client_id": config["clientId"],
                "client_secret": config["clientSecret"],
                "redirect_uri": config["redirectUri"],
                "grant_type": "authorization_code",
            },
        )
        access_token = str(token_response.get("access_token") or "").strip()
        if not access_token:
            raise AccountError("Google token response did not include access token")
        profile = _json_get(config["userinfoUrl"], access_token)
        account = _account_store().upsert_google_account(profile)
        login_code = _account_store().create_login_code(account["accountId"])
        return redirect(
            _append_query(
                return_url,
                {"provider": "google", "accountLoginCode": login_code},
            )
        )
    except (AccountError, OAuthStateError) as error:
        return redirect(
            _append_query(
                _frontend_url(),
                {"provider": "google", "accountError": str(error)},
            )
        )


@api_bp.route("/accounts/me", methods=["GET"])
def current_account():
    account, error = _account_from_bearer()
    if error is not None:
        return error
    return {"authenticated": True, "account": account}


@api_bp.route("/accounts/logout", methods=["POST"])
def logout_account():
    account, error = _account_from_bearer()
    if error is not None:
        return error
    revoked = _account_store().revoke_session(_bearer_token())
    return {
        "accepted": True,
        "revoked": revoked,
        "accountId": account["accountId"],
    }


@api_bp.route("/accounts/data", methods=["GET"])
def account_data():
    account, error = _account_from_bearer()
    if error is not None:
        return error
    return {"accountId": account["accountId"], "data": account["data"]}


@api_bp.route("/accounts/data", methods=["PUT"])
def update_account_data():
    account, error = _account_from_bearer()
    if error is not None:
        return error
    payload = request.get_json(silent=True) or {}
    try:
        data = _account_store().update_account_data(account["accountId"], payload)
    except AccountError as error:
        return _account_error(error)
    if data is None:
        return {"accepted": False, "error": "Account not found"}, 404
    return {"accepted": True, "accountId": account["accountId"], "data": data}


@api_bp.route("/map/config", methods=["GET"])
@require_roles("viewer")
def map_config(identity):
    return _public_map_config()


@api_bp.route("/map/geofence", methods=["GET"])
@require_roles("viewer")
def map_geofence(identity):
    return geofence_map_layer(scenario_id=_active_map_scenario_id())


@api_bp.route("/map/mission", methods=["GET"])
@require_roles("viewer")
def map_mission(identity):
    state_store = _dji_state_store()
    state = state_store.read()
    drones = state.get("drones") if state_store.is_fresh(state) else []
    return mission_map_layer(
        alerts=_operations_store().list_alerts(),
        drones=drones,
        scenario_id=_active_map_scenario_id(),
    )


@api_bp.route("/map/search", methods=["GET"])
@require_roles("viewer")
def map_search(identity):
    query = request.args.get("q", "").strip()
    if not query:
        return {"accepted": False, "error": "q query parameter is required"}, 400

    provider = str(current_app.config.get("MAP_SEARCH_PROVIDER", "nominatim")).strip().lower()
    if provider != "nominatim":
        return {
            "accepted": False,
            "error": f"Unsupported map search provider: {provider}",
        }, 501

    try:
        return search_nominatim_places(
            query,
            current_app.config.get(
                "NOMINATIM_SEARCH_URL",
                "https://nominatim.openstreetmap.org/search",
            ),
            current_app.config.get(
                "NOMINATIM_USER_AGENT",
                "FireDroneProject/0.1 public-safety-prototype",
            ),
            limit=current_app.config.get("MAP_SEARCH_LIMIT", 5),
        )
    except ValueError as error:
        return {"accepted": False, "error": str(error)}, 400
    except MapSearchError as error:
        return {"accepted": False, "error": str(error)}, 502


def _public_map_config():
    tile_url = str(current_app.config.get("MAP_TILE_URL_TEMPLATE", "")).strip()
    provider = str(current_app.config.get("MAP_PROVIDER", "openstreetmap")).strip()
    requires_api_key = bool(str(current_app.config.get("MAP_API_KEY", "")).strip())
    imagery_tile_url = str(
        current_app.config.get("MAP_IMAGERY_TILE_URL_TEMPLATE", "")
    ).strip()
    imagery_provider = str(
        current_app.config.get("MAP_IMAGERY_PROVIDER", "arcgis-world-imagery")
    ).strip()
    imagery_attribution = str(
        current_app.config.get("MAP_IMAGERY_ATTRIBUTION", "")
    ).strip()
    default_basemap = str(
        current_app.config.get("MAP_DEFAULT_BASEMAP", "satellite")
    ).strip()
    basemaps = [
        {
            "id": "satellite",
            "label": "Satellite imagery",
            "provider": imagery_provider,
            "tileUrlTemplate": imagery_tile_url,
            "attribution": imagery_attribution,
            "configured": bool(imagery_tile_url),
            "requiresApiKey": False,
            "policy": _imagery_policy(imagery_provider, imagery_tile_url),
        },
        {
            "id": "streets",
            "label": "Street map",
            "provider": provider,
            "tileUrlTemplate": tile_url,
            "attribution": str(current_app.config.get("MAP_ATTRIBUTION", "")).strip(),
            "configured": bool(tile_url),
            "requiresApiKey": requires_api_key,
            "policy": _tile_policy(provider, tile_url, requires_api_key),
        },
    ]
    return {
        "provider": provider,
        "tileUrlTemplate": tile_url,
        "attribution": str(current_app.config.get("MAP_ATTRIBUTION", "")).strip(),
        "configured": bool(tile_url),
        "requiresApiKey": requires_api_key,
        "tilePolicy": _tile_policy(provider, tile_url, requires_api_key),
        "defaultBasemap": default_basemap,
        "basemaps": basemaps,
        "center": map_center_for_scenario(_active_map_scenario_id()),
        "incidentLayerStatus": "geojson",
        "geofenceLayerStatus": "geojson",
        "geofenceLayerEndpoint": "/api/map/geofence",
        "missionLayerEndpoint": "/api/map/mission",
        "searchProvider": str(
            current_app.config.get("MAP_SEARCH_PROVIDER", "nominatim")
        ).strip(),
        "searchEndpoint": "/api/map/search",
    }


def _imagery_policy(provider, tile_url):
    normalized_provider = provider.strip().lower()
    normalized_tile_url = tile_url.strip().lower()
    if not normalized_tile_url:
        return {
            "status": "not-configured",
            "productionReady": False,
            "message": "No satellite imagery tile provider URL is configured.",
        }
    if (
        normalized_provider == "arcgis-world-imagery"
        or "world_imagery" in normalized_tile_url
    ):
        return {
            "status": "development-imagery",
            "productionReady": False,
            "message": (
                "ArcGIS World Imagery gives a realistic satellite basemap for "
                "development previews. Confirm Esri licensing, attribution, "
                "rate limits, and token requirements before production."
            ),
        }
    return {
        "status": "operator-configured",
        "productionReady": True,
        "message": (
            "A dedicated imagery provider is configured. Confirm licensing, "
            "rate limits, attribution, and offline-area policy before field use."
        ),
    }


def _tile_policy(provider, tile_url, requires_api_key):
    normalized_provider = provider.strip().lower()
    normalized_tile_url = tile_url.strip().lower()
    if not normalized_tile_url:
        return {
            "status": "not-configured",
            "productionReady": False,
            "message": "No map tile provider URL is configured.",
        }
    if (
        normalized_provider == "openstreetmap"
        and "tile.openstreetmap.org" in normalized_tile_url
    ):
        return {
            "status": "development-only",
            "productionReady": False,
            "message": (
                "Public OpenStreetMap tile servers are for development previews; "
                "use a dedicated provider for production."
            ),
        }
    return {
        "status": "operator-configured",
        "productionReady": True,
        "message": (
            "A dedicated map tile provider is configured. Confirm licensing, "
            "rate limits, attribution, and offline-area policy before field use."
        ),
    }


@api_bp.route("/integrations/status", methods=["GET"])
@require_roles("viewer")
def integrations_status(identity):
    return {
        "auth": {
            "rbacEnabled": bool(current_app.config.get("AUTH_REQUIRED", False)),
            "role": identity["role"],
            "availableRoles": ["viewer", "operator", "admin", "ingest"],
        },
        "persistence": {
            "enabled": True,
            "engine": _database().engine,
            "audit": "persistent",
            "alerts": "persistent",
        },
        "map": _public_map_config(),
        "adapters": {
            "djiCloudApi": "configured-through-dji-connector",
            "djiMobileSdk": "configured-through-dji-connector",
            "px4Sitl": "read-only",
            "mavlink": "read-only",
            "arduPilot": "read-only-through-mavlink",
            "yoloThermal": "ingest-review",
        },
        "safety": {
            "simulationDefault": True,
            "hardwareCommandsEnabled": False,
            "allowDjiCommands": bool(current_app.config.get("ALLOW_DJI_COMMANDS", False)),
            "commandEndpoint": "/api/commands/simulate",
            "checklistEndpoint": "/api/safety/checklist",
        },
    }


@api_bp.route("/audit", methods=["GET"])
@require_roles("viewer")
def audit_entries(identity):
    limit = request.args.get("limit", 100)
    return {"entries": _operations_store().list_audit(limit=limit)}


@api_bp.route("/safety/checklist", methods=["GET"])
@require_roles("viewer")
def safety_checklist(identity):
    return _operations_store().safety_checklist()


@api_bp.route("/safety/checklist", methods=["POST"])
@require_roles("operator")
def update_safety_checklist(identity):
    payload = request.get_json(silent=True) or {}
    store = _operations_store()
    try:
        checklist = store.update_safety_checklist(payload, actor=identity["actor"])
    except ValueError as error:
        return {"accepted": False, "error": str(error)}, 400

    updated_keys = ", ".join(sorted(payload.keys())) if payload else "none"
    store.record_audit(
        actor=identity["actor"],
        role=identity["role"],
        action="Updated safety checklist",
        target_id="safety-checklist",
        details=f"Updated items: {updated_keys}",
    )
    return checklist


@api_bp.route("/alerts", methods=["GET"])
@require_roles("viewer")
def alerts(identity):
    return {"alerts": _operations_store().list_alerts()}


@api_bp.route("/vision/alerts/ingest", methods=["POST"])
@require_roles("ingest", "operator")
def vision_alert_ingest(identity):
    payload = request.get_json(silent=True) or {}
    normalized = normalize_detection_payload(payload)
    if not normalized["accepted"]:
        return {
            "accepted": False,
            "errors": normalized["errors"],
        }, 400

    store = _operations_store()
    alerts = [store.upsert_alert(alert) for alert in normalized["alerts"]]
    for alert in alerts:
        store.record_audit(
            actor=identity["actor"],
            role=identity["role"],
            action="Ingested vision alert",
            target_id=alert["eventId"],
            details=(
                f"{alert['detectionType']} {round(alert['confidence'] * 100)}% "
                f"{alert['severity']} from {alert['sourceDroneId']}"
            ),
        )
    return {
        "accepted": True,
        "alerts": alerts,
        "count": len(alerts),
    }, 202


@api_bp.route("/alerts/<event_id>/review", methods=["POST"])
@require_roles("operator")
def review_alert(identity, event_id):
    payload = request.get_json(silent=True) or {}
    status = str(payload.get("status", "")).strip()
    allowed_status = {
        "Confirmed",
        "False Positive",
        "Resolved",
        "Unconfirmed",
    }
    if status not in allowed_status:
        return {
            "accepted": False,
            "error": "status must be Confirmed, False Positive, Resolved, or Unconfirmed",
        }, 400

    store = _operations_store()
    alert = store.review_alert(
        event_id,
        status=status,
        reviewer=identity["actor"],
        notes=str(payload.get("notes", "")).strip(),
    )
    if alert is None:
        return {"accepted": False, "error": "Alert not found"}, 404

    action = {
        "Confirmed": "Confirmed alert",
        "False Positive": "Marked false positive",
        "Resolved": "Resolved alert",
        "Unconfirmed": "Reset alert review",
    }[status]
    store.record_audit(
        actor=identity["actor"],
        role=identity["role"],
        action=action,
        target_id=event_id,
        details=str(payload.get("notes", "")).strip(),
    )
    return {"accepted": True, "alert": alert}


@api_bp.route("/integrations/px4-sitl/telemetry", methods=["POST"])
@require_roles("ingest", "operator")
def px4_sitl_telemetry(identity):
    payload = request.get_json(silent=True) or {}
    ingest_payload = mavlink_payload_to_ingest_payload(
        payload,
        adapter="px4-sitl-readonly",
        model="PX4 SITL",
    )
    return _write_readonly_aircraft_ingest(ingest_payload, identity)


@api_bp.route("/integrations/mavlink/telemetry", methods=["POST"])
@require_roles("ingest", "operator")
def mavlink_telemetry(identity):
    payload = request.get_json(silent=True) or {}
    ingest_payload = mavlink_payload_to_ingest_payload(
        payload,
        adapter="mavlink-readonly",
        model="MAVLink read-only",
    )
    return _write_readonly_aircraft_ingest(ingest_payload, identity)


@api_bp.route("/commands/simulate", methods=["POST"])
@require_roles("operator")
def command_simulate(identity):
    payload = request.get_json(silent=True) or {}
    result, status_code = simulate_command(payload)
    store = _operations_store()
    if result["accepted"] and result.get("commandType") == "Emergency Stop":
        store.set_emergency_stop(True, actor=identity["actor"], notes=result["message"])
    action = (
        "Blocked simulated command"
        if not result["accepted"]
        else f"Simulated command {result['commandType']}"
    )
    store.record_audit(
        actor=identity["actor"],
        role=identity["role"],
        action=action,
        target_id=result["targetDroneId"],
        details=result["message"],
    )
    return result, status_code
