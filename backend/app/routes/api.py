import secrets

from flask import current_app, request

from app.dji import create_dji_connector
from app.dji.cloud_api import cloud_api_message_to_ingest_payload
from app.dji.cloud_bridge import cloud_bridge_manager
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
from app.routes import api_bp
from app.security import require_roles


@api_bp.route("/status", methods=["GET"])
def status():
    return {
        "message": "FireDrone API is running",
        "version": "0.1.0",
    }


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


def _operations_store():
    return OperationsStore(
        current_app.config.get(
            "APP_DATABASE_FILE",
            "instance/operations.sqlite3",
        )
    )


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
        bridge_status = cloud_bridge_manager.start(
            _runtime_config_store().effective_config(current_app.config)
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
        return result
    return result


@api_bp.route("/dji/missions/confirm", methods=["POST"])
def dji_mission_confirm():
    payload = request.get_json(silent=True) or {}
    response, status_code = _dji_connector().confirm_mission(payload)
    return response, status_code


@api_bp.route("/auth/session", methods=["GET"])
@require_roles("viewer")
def auth_session(identity):
    return {
        "authenticated": identity["authenticated"],
        "actor": identity["actor"],
        "role": identity["role"],
        "rbacEnabled": bool(current_app.config.get("AUTH_REQUIRED", False)),
    }


@api_bp.route("/map/config", methods=["GET"])
@require_roles("viewer")
def map_config(identity):
    return _public_map_config()


def _public_map_config():
    tile_url = str(current_app.config.get("MAP_TILE_URL_TEMPLATE", "")).strip()
    provider = str(current_app.config.get("MAP_PROVIDER", "openstreetmap")).strip()
    return {
        "provider": provider,
        "tileUrlTemplate": tile_url,
        "attribution": str(current_app.config.get("MAP_ATTRIBUTION", "")).strip(),
        "configured": bool(tile_url),
        "requiresApiKey": bool(str(current_app.config.get("MAP_API_KEY", "")).strip()),
        "incidentLayerStatus": "placeholder",
        "geofenceLayerStatus": "placeholder",
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
            "engine": "sqlite",
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
