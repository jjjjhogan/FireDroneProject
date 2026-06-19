import atexit

from flask import Flask
from flask_cors import CORS

from config import Config


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    CORS(app)

    from app.routes import api_bp

    app.register_blueprint(api_bp, url_prefix="/api")

    @app.route("/health")
    def health():
        return {"status": "ok", "service": "FireDrone API"}

    from app.dji.cloud_bridge import cloud_bridge_manager, init_auto_start_cloud_bridge

    init_auto_start_cloud_bridge(app)
    atexit.register(cloud_bridge_manager.stop)

    return app
