from functools import wraps

from flask import current_app, request


ROLE_LEVELS = {
    "viewer": 10,
    "operator": 20,
    "admin": 30,
}


def _token_map():
    configured = current_app.config.get("PUBLIC_SAFETY_TOKENS", {})
    if isinstance(configured, dict):
        return {str(token): str(role) for token, role in configured.items()}
    mapping = {}
    for item in str(configured or "").split(","):
        if ":" not in item:
            continue
        token, role = item.split(":", 1)
        token = token.strip()
        role = role.strip()
        if token and role:
            mapping[token] = role
    return mapping


def _identity_from_request():
    if not bool(current_app.config.get("AUTH_REQUIRED", False)):
        return {"actor": "local-dev", "role": "admin", "authenticated": False}, None

    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        return None, ({"error": "Missing bearer token"}, 401)

    token = header.removeprefix("Bearer ").strip()
    role = _token_map().get(token)
    if not role:
        account_identity = _account_identity_from_token(token)
        if account_identity is not None:
            return account_identity, None
        return None, ({"error": "Invalid bearer token"}, 401)

    return {
        "actor": role,
        "role": role,
        "authenticated": True,
    }, None


def _account_identity_from_token(token):
    try:
        from app.accounts import AccountStore

        account = AccountStore(
            current_app.config.get(
                "APP_DATABASE_FILE",
                "instance/operations.sqlite3",
            )
        ).account_for_token(token)
    except Exception:
        return None
    if account is None:
        return None
    return {
        "actor": account["email"],
        "role": account["role"],
        "authenticated": True,
        "accountId": account["accountId"],
    }


def _role_allowed(actual, allowed):
    if actual == "admin":
        return True
    if actual == "ingest":
        return "ingest" in allowed
    actual_level = ROLE_LEVELS.get(actual, 0)
    return any(actual_level >= ROLE_LEVELS.get(role, 999) for role in allowed)


def require_roles(*allowed_roles):
    def decorator(handler):
        @wraps(handler)
        def wrapper(*args, **kwargs):
            identity, error = _identity_from_request()
            if error is not None:
                return error
            if allowed_roles and not _role_allowed(identity["role"], set(allowed_roles)):
                return {
                    "error": "Forbidden",
                    "requiredRoles": list(allowed_roles),
                    "role": identity["role"],
                }, 403
            return handler(identity, *args, **kwargs)

        return wrapper

    return decorator


def current_identity():
    identity, error = _identity_from_request()
    if error is not None:
        return None
    return identity
