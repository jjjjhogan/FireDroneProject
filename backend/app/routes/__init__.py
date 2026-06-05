from flask import Blueprint

api_bp = Blueprint("api", __name__)

from app.routes import api  # noqa: E402, F401
