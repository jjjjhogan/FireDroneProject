from app.routes import api_bp


@api_bp.route("/status", methods=["GET"])
def status():
    return {
        "message": "FireDrone API is running",
        "version": "0.1.0",
    }
