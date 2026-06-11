from flask import current_app, request

from app.dji import create_dji_connector
from app.routes import api_bp


@api_bp.route("/status", methods=["GET"])
def status():
    return {
        "message": "FireDrone API is running",
        "version": "0.1.0",
    }


def _dji_connector():
    return create_dji_connector(current_app.config)


@api_bp.route("/dji/status", methods=["GET"])
def dji_status():
    return _dji_connector().status()


@api_bp.route("/dji/fleet", methods=["GET"])
def dji_fleet():
    return _dji_connector().fleet()


@api_bp.route("/dji/telemetry", methods=["GET"])
def dji_telemetry():
    return _dji_connector().telemetry()


@api_bp.route("/dji/missions/preview", methods=["POST"])
def dji_mission_preview():
    payload = request.get_json(silent=True) or {}
    return _dji_connector().preview_mission(payload)


@api_bp.route("/dji/missions/confirm", methods=["POST"])
def dji_mission_confirm():
    payload = request.get_json(silent=True) or {}
    response, status_code = _dji_connector().confirm_mission(payload)
    return response, status_code
