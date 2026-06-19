import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")


def _env(key: str, default: str = "") -> str:
    value = os.getenv(key)
    if value is None:
        return default
    stripped = value.strip()
    return stripped if stripped else default


def _env_path(key: str, default: Path) -> str:
    return _env(key, str(default))


class Config:
    SECRET_KEY = _env("SECRET_KEY", "dev-secret-key-change-in-production")
    DEBUG = _env("FLASK_DEBUG", "true").lower() == "true"
    HOST = _env("FLASK_HOST", "127.0.0.1")
    PORT = int(_env("FLASK_PORT", "5000"))
    DRONE_CONNECTOR = _env("DRONE_CONNECTOR", "real")
    ALLOW_DJI_COMMANDS = _env("ALLOW_DJI_COMMANDS", "false").lower() == "true"
    DJI_CLOUD_API_APP_ID = _env("DJI_CLOUD_API_APP_ID")
    DJI_CLOUD_API_APP_KEY = _env("DJI_CLOUD_API_APP_KEY")
    DJI_CLOUD_API_APP_LICENSE = _env("DJI_CLOUD_API_APP_LICENSE")
    DJI_CLOUD_API_MQTT_HOST = _env("DJI_CLOUD_API_MQTT_HOST")
    DJI_WORKSPACE_ID = _env("DJI_WORKSPACE_ID")
    DJI_INGEST_TOKEN = _env("DJI_INGEST_TOKEN")
    DJI_STATE_FILE = _env_path(
        "DJI_STATE_FILE",
        BASE_DIR / "instance" / "dji_state.json",
    )
    DJI_RUNTIME_CONFIG_FILE = _env_path(
        "DJI_RUNTIME_CONFIG_FILE",
        BASE_DIR / "instance" / "dji_runtime_config.json",
    )
    DJI_TELEMETRY_TTL_SECONDS = int(_env("DJI_TELEMETRY_TTL_SECONDS", "300"))
    DJI_MAX_INGEST_DRONES = int(_env("DJI_MAX_INGEST_DRONES", "16"))
    DJI_CLOUD_MQTT_PORT = int(_env("DJI_CLOUD_MQTT_PORT", "8883"))
    DJI_CLOUD_MQTT_USE_TLS = _env("DJI_CLOUD_MQTT_USE_TLS", "true").lower() == "true"
    DJI_CLOUD_MQTT_USERNAME = _env("DJI_CLOUD_MQTT_USERNAME")
    DJI_CLOUD_MQTT_PASSWORD = _env("DJI_CLOUD_MQTT_PASSWORD")
    DJI_CLOUD_MQTT_CLIENT_ID = _env(
        "DJI_CLOUD_MQTT_CLIENT_ID",
        "firedrone-cloud-worker",
    )
    DJI_AUTO_START_CLOUD_BRIDGE = (
        _env("DJI_AUTO_START_CLOUD_BRIDGE", "true").lower() == "true"
    )
    APP_DATABASE_FILE = _env_path(
        "APP_DATABASE_FILE",
        BASE_DIR / "instance" / "operations.sqlite3",
    )
    AUTH_REQUIRED = _env("AUTH_REQUIRED", "false").lower() == "true"
    PUBLIC_SAFETY_TOKENS = _env("PUBLIC_SAFETY_TOKENS")
    MAP_PROVIDER = _env("MAP_PROVIDER", "openstreetmap")
    MAP_TILE_URL_TEMPLATE = _env(
        "MAP_TILE_URL_TEMPLATE",
        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    )
    MAP_ATTRIBUTION = _env("MAP_ATTRIBUTION", "OpenStreetMap contributors")
    MAP_API_KEY = _env("MAP_API_KEY")
    MAP_DEFAULT_BASEMAP = _env("MAP_DEFAULT_BASEMAP", "satellite")
    MAP_IMAGERY_PROVIDER = _env("MAP_IMAGERY_PROVIDER", "arcgis-world-imagery")
    MAP_IMAGERY_TILE_URL_TEMPLATE = _env(
        "MAP_IMAGERY_TILE_URL_TEMPLATE",
        "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
    )
    MAP_IMAGERY_ATTRIBUTION = _env(
        "MAP_IMAGERY_ATTRIBUTION",
        "Powered by Esri | Sources: Esri, Maxar, Earthstar Geographics, and the GIS User Community",
    )
    MAP_SEARCH_PROVIDER = _env("MAP_SEARCH_PROVIDER", "nominatim")
    NOMINATIM_SEARCH_URL = _env(
        "NOMINATIM_SEARCH_URL",
        "https://nominatim.openstreetmap.org/search",
    )
    NOMINATIM_USER_AGENT = _env(
        "NOMINATIM_USER_AGENT",
        "FireDroneProject/0.1 public-safety-prototype",
    )
    MAP_SEARCH_LIMIT = int(_env("MAP_SEARCH_LIMIT", "5"))
