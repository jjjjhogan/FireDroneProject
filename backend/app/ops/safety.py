from app.dji.state_store import utc_now_iso


def simulate_command(payload):
    payload = payload if isinstance(payload, dict) else {}
    command_type = str(payload.get("commandType") or "").strip() or "Unknown"
    target_drone_id = str(payload.get("targetDroneId") or "simulated-fleet").strip()
    confirmation = bool(payload.get("confirmationProvided"))
    emergency = command_type.lower().replace(" ", "") == "emergencystop"

    if not confirmation and not emergency:
        return {
            "accepted": False,
            "commandType": command_type,
            "targetDroneId": target_drone_id,
            "message": "Operator confirmation is required before simulating this command.",
            "blockedReason": "Operator confirmation required",
            "timestamp": utc_now_iso(),
            "hardwareCommandSent": False,
            "emergencyStopEngaged": False,
        }, 409

    if emergency:
        return {
            "accepted": True,
            "commandType": command_type,
            "targetDroneId": target_drone_id,
            "message": "Emergency Stop simulation lock engaged. No hardware command was sent.",
            "blockedReason": None,
            "timestamp": utc_now_iso(),
            "hardwareCommandSent": False,
            "emergencyStopEngaged": True,
        }, 200

    return {
        "accepted": True,
        "commandType": command_type,
        "targetDroneId": target_drone_id,
        "message": f"Simulated {command_type} accepted. No hardware command was sent.",
        "blockedReason": None,
        "timestamp": utc_now_iso(),
        "hardwareCommandSent": False,
        "emergencyStopEngaged": False,
    }, 200
