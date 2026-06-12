import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key-change-in-production")
    DEBUG = os.getenv("FLASK_DEBUG", "true").lower() == "true"
    HOST = os.getenv("FLASK_HOST", "127.0.0.1")
    PORT = int(os.getenv("FLASK_PORT", "5000"))
    DRONE_CONNECTOR = os.getenv("DRONE_CONNECTOR", "real")
    ALLOW_DJI_COMMANDS = os.getenv("ALLOW_DJI_COMMANDS", "false").lower() == "true"
    DJI_CLOUD_API_APP_ID = os.getenv("DJI_CLOUD_API_APP_ID", "")
    DJI_CLOUD_API_APP_KEY = os.getenv("DJI_CLOUD_API_APP_KEY", "")
    DJI_CLOUD_API_APP_LICENSE = os.getenv("DJI_CLOUD_API_APP_LICENSE", "")
    DJI_CLOUD_API_MQTT_HOST = os.getenv("DJI_CLOUD_API_MQTT_HOST", "")
    DJI_WORKSPACE_ID = os.getenv("DJI_WORKSPACE_ID", "")
    DJI_INGEST_TOKEN = os.getenv("DJI_INGEST_TOKEN", "")
    DJI_STATE_FILE = os.getenv("DJI_STATE_FILE", str(BASE_DIR / "instance" / "dji_state.json"))
    DJI_TELEMETRY_TTL_SECONDS = int(os.getenv("DJI_TELEMETRY_TTL_SECONDS", "300"))
