from flask import current_app, request

from app.dji import create_dji_connector
from app.dji.cloud_api import cloud_api_message_to_ingest_payload
from app.dji.ingest import normalize_ingest_payload
from app.dji.mobile_sdk import mobile_sdk_state_to_ingest_payload
from app.dji.state_store import DjiStateStore, utc_now_iso
from app.routes import api_bp


@api_bp.route("/status", methods=["GET"])
def status():
    return {
        "message": "FireDrone API is running",
        "version": "0.1.0",
    }


def _dji_connector():
    return create_dji_connector(current_app.config)


def _authorized_ingest():
    expected = str(current_app.config.get("DJI_INGEST_TOKEN", "")).strip()
    if not expected:
        return False
    header = request.headers.get("Authorization", "")
    return header == f"Bearer {expected}"


def _dji_state_store():
    return DjiStateStore(
        current_app.config.get("DJI_STATE_FILE", "instance/dji_state.json"),
        current_app.config.get("DJI_TELEMETRY_TTL_SECONDS", 300),
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


@api_bp.route("/dji/status", methods=["GET"])
def dji_status():
    return _dji_connector().status()


@api_bp.route("/dji/fleet", methods=["GET"])
def dji_fleet():
    return _dji_connector().fleet()


@api_bp.route("/dji/telemetry", methods=["GET"])
def dji_telemetry():
    return _dji_connector().telemetry()


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
