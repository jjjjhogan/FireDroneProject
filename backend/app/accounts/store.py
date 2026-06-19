import hashlib
import hmac
import json
import re
import secrets
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

from app.dji.state_store import utc_now_iso


EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PASSWORD_ITERATIONS = 210_000
SESSION_DAYS = 30


class AccountError(ValueError):
    status_code = 400


class DuplicateAccountError(AccountError):
    status_code = 409


class AuthenticationError(AccountError):
    status_code = 401


class OAuthStateError(AccountError):
    status_code = 401


def default_account_data(organization=""):
    return {
        "profile": {
            "organization": organization or "",
            "roleLabel": "Mission operator",
        },
        "djiConnection": {
            "mode": "not-configured",
            "operatorLabel": "",
            "workspaceId": "",
        },
        "missionPreferences": {
            "defaultScenario": "Canyon Ridge Fire",
            "mapBasemap": "satellite",
            "safetyChecklistRequired": True,
        },
        "savedMissions": [],
    }


def _now():
    return datetime.now(timezone.utc)


def _iso(dt):
    return dt.isoformat().replace("+00:00", "Z")


def _normalize_email(email):
    return str(email or "").strip().lower()


def _hash_token(token):
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _hash_password(password):
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        PASSWORD_ITERATIONS,
    )
    return (
        f"pbkdf2_sha256${PASSWORD_ITERATIONS}$"
        f"{salt.hex()}${digest.hex()}"
    )


def _verify_password(password, encoded):
    try:
        algorithm, iterations, salt_hex, digest_hex = encoded.split("$", 3)
        if algorithm != "pbkdf2_sha256":
            return False
        digest = hashlib.pbkdf2_hmac(
            "sha256",
            password.encode("utf-8"),
            bytes.fromhex(salt_hex),
            int(iterations),
        )
        return hmac.compare_digest(digest.hex(), digest_hex)
    except (TypeError, ValueError):
        return False


class AccountStore:
    def __init__(self, path):
        self.path = Path(path)

    def _connect(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(self.path)
        connection.row_factory = sqlite3.Row
        self._ensure_schema(connection)
        return connection

    @contextmanager
    def _session(self):
        connection = self._connect()
        try:
            yield connection
        finally:
            connection.close()

    def _ensure_schema(self, connection):
        connection.executescript(
            """
            create table if not exists accounts (
              account_id text primary key,
              email text not null unique,
              display_name text not null,
              organization text not null,
              role text not null,
              password_hash text not null,
              data_json text not null,
              created_at text not null,
              updated_at text not null
            );

            create table if not exists account_sessions (
              token_hash text primary key,
              account_id text not null,
              created_at text not null,
              expires_at text not null,
              revoked_at text,
              foreign key(account_id) references accounts(account_id)
            );

            create table if not exists oauth_states (
              state_hash text primary key,
              provider text not null,
              return_url text not null,
              created_at text not null,
              expires_at text not null,
              consumed_at text
            );

            create table if not exists account_login_codes (
              code_hash text primary key,
              account_id text not null,
              created_at text not null,
              expires_at text not null,
              consumed_at text,
              foreign key(account_id) references accounts(account_id)
            );
            """
        )
        self._ensure_account_columns(connection)
        connection.commit()

    def _ensure_account_columns(self, connection):
        rows = connection.execute("pragma table_info(accounts)").fetchall()
        existing = {row["name"] for row in rows}
        columns = {
            "google_subject": "text",
            "avatar_url": "text",
            "auth_provider": "text not null default 'password'",
        }
        for name, definition in columns.items():
            if name not in existing:
                connection.execute(
                    f"alter table accounts add column {name} {definition}"
                )

    def register(self, payload):
        email = _normalize_email(payload.get("email"))
        password = str(payload.get("password") or "")
        display_name = str(payload.get("displayName") or "").strip()
        organization = str(payload.get("organization") or "").strip()

        if not EMAIL_PATTERN.match(email):
            raise AccountError("A valid email is required")
        if len(password) < 8:
            raise AccountError("Password must be at least 8 characters")
        if not display_name:
            display_name = email.split("@", 1)[0]

        timestamp = utc_now_iso()
        account = {
            "account_id": f"acct-{uuid4().hex[:12]}",
            "email": email,
            "display_name": display_name,
            "organization": organization,
            "role": "operator",
            "password_hash": _hash_password(password),
            "data_json": json.dumps(
                default_account_data(organization),
                sort_keys=True,
            ),
            "created_at": timestamp,
            "updated_at": timestamp,
        }

        try:
            with self._session() as connection:
                connection.execute(
                    """
                    insert into accounts
                    (account_id, email, display_name, organization, role,
                     password_hash, data_json, created_at, updated_at,
                     auth_provider, google_subject, avatar_url)
                    values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, null, null)
                    """,
                    (
                        account["account_id"],
                        account["email"],
                        account["display_name"],
                        account["organization"],
                        account["role"],
                        account["password_hash"],
                        account["data_json"],
                        account["created_at"],
                        account["updated_at"],
                        "password",
                    ),
                )
                connection.commit()
        except sqlite3.IntegrityError as error:
            if "unique" in str(error).lower():
                raise DuplicateAccountError("Account already exists") from error
            raise

        token = self.create_session(account["account_id"])
        return token, self.get_account_by_id(account["account_id"])

    def login(self, payload):
        email = _normalize_email(payload.get("email"))
        password = str(payload.get("password") or "")
        row = self._get_account_row_by_email(email)
        if row is None or not _verify_password(password, row["password_hash"]):
            raise AuthenticationError("Invalid email or password")
        token = self.create_session(row["account_id"])
        return token, self._account_from_row(row)

    def create_oauth_state(self, provider, return_url):
        state = secrets.token_urlsafe(32)
        now = _now()
        with self._session() as connection:
            connection.execute(
                """
                insert into oauth_states
                (state_hash, provider, return_url, created_at, expires_at,
                 consumed_at)
                values (?, ?, ?, ?, ?, null)
                """,
                (
                    _hash_token(state),
                    provider,
                    return_url,
                    _iso(now),
                    _iso(now + timedelta(minutes=10)),
                ),
            )
            connection.commit()
        return state

    def consume_oauth_state(self, provider, state):
        state = str(state or "").strip()
        if not state:
            raise OAuthStateError("Missing OAuth state")
        now = _now()
        with self._session() as connection:
            row = connection.execute(
                """
                select return_url
                from oauth_states
                where state_hash=?
                  and provider=?
                  and consumed_at is null
                  and expires_at > ?
                """,
                (_hash_token(state), provider, _iso(now)),
            ).fetchone()
            if row is None:
                raise OAuthStateError("Invalid or expired OAuth state")
            connection.execute(
                """
                update oauth_states
                set consumed_at=?
                where state_hash=?
                """,
                (_iso(now), _hash_token(state)),
            )
            connection.commit()
        return row["return_url"]

    def upsert_google_account(self, profile):
        google_subject = str(profile.get("sub") or "").strip()
        email = _normalize_email(profile.get("email"))
        display_name = str(profile.get("name") or "").strip()
        avatar_url = str(profile.get("picture") or "").strip()
        if not google_subject:
            raise AccountError("Google profile is missing subject")
        if not EMAIL_PATTERN.match(email):
            raise AccountError("Google profile is missing a valid email")
        if not display_name:
            display_name = email.split("@", 1)[0]

        timestamp = utc_now_iso()
        with self._session() as connection:
            existing = connection.execute(
                """
                select *
                from accounts
                where google_subject=?
                """,
                (google_subject,),
            ).fetchone()
            if existing is None:
                existing = connection.execute(
                    """
                    select *
                    from accounts
                    where email=?
                    """,
                    (email,),
                ).fetchone()

            if existing is None:
                account_id = f"acct-{uuid4().hex[:12]}"
                connection.execute(
                    """
                    insert into accounts
                    (account_id, email, display_name, organization, role,
                     password_hash, data_json, created_at, updated_at,
                     auth_provider, google_subject, avatar_url)
                    values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        account_id,
                        email,
                        display_name,
                        "",
                        "operator",
                        _hash_password(secrets.token_urlsafe(32)),
                        json.dumps(default_account_data(), sort_keys=True),
                        timestamp,
                        timestamp,
                        "google",
                        google_subject,
                        avatar_url,
                    ),
                )
            else:
                account_id = existing["account_id"]
                connection.execute(
                    """
                    update accounts
                    set display_name=?,
                        google_subject=?,
                        avatar_url=?,
                        auth_provider='google',
                        updated_at=?
                    where account_id=?
                    """,
                    (
                        display_name,
                        google_subject,
                        avatar_url,
                        timestamp,
                        account_id,
                    ),
                )
            connection.commit()
        return self.get_account_by_id(account_id)

    def create_login_code(self, account_id):
        code = f"login_{secrets.token_urlsafe(32)}"
        now = _now()
        with self._session() as connection:
            connection.execute(
                """
                insert into account_login_codes
                (code_hash, account_id, created_at, expires_at, consumed_at)
                values (?, ?, ?, ?, null)
                """,
                (
                    _hash_token(code),
                    account_id,
                    _iso(now),
                    _iso(now + timedelta(minutes=5)),
                ),
            )
            connection.commit()
        return code

    def complete_login_code(self, code):
        code = str(code or "").strip()
        if not code:
            raise AuthenticationError("Missing login code")
        now = _now()
        with self._session() as connection:
            row = connection.execute(
                """
                select account_id
                from account_login_codes
                where code_hash=?
                  and consumed_at is null
                  and expires_at > ?
                """,
                (_hash_token(code), _iso(now)),
            ).fetchone()
            if row is None:
                raise AuthenticationError("Invalid or expired login code")
            connection.execute(
                """
                update account_login_codes
                set consumed_at=?
                where code_hash=?
                """,
                (_iso(now), _hash_token(code)),
            )
            connection.commit()
        token = self.create_session(row["account_id"])
        return token, self.get_account_by_id(row["account_id"])

    def create_session(self, account_id):
        token = f"acct_{secrets.token_urlsafe(32)}"
        now = _now()
        with self._session() as connection:
            connection.execute(
                """
                insert into account_sessions
                (token_hash, account_id, created_at, expires_at, revoked_at)
                values (?, ?, ?, ?, null)
                """,
                (
                    _hash_token(token),
                    account_id,
                    _iso(now),
                    _iso(now + timedelta(days=SESSION_DAYS)),
                ),
            )
            connection.commit()
        return token

    def account_for_token(self, token):
        token = str(token or "").strip()
        if not token:
            return None
        with self._session() as connection:
            row = connection.execute(
                """
                select a.*
                from account_sessions s
                join accounts a on a.account_id=s.account_id
                where s.token_hash=?
                  and s.revoked_at is null
                  and s.expires_at > ?
                """,
                (_hash_token(token), _iso(_now())),
            ).fetchone()
        if row is None:
            return None
        return self._account_from_row(row)

    def revoke_session(self, token):
        token = str(token or "").strip()
        if not token:
            return False
        with self._session() as connection:
            cursor = connection.execute(
                """
                update account_sessions
                set revoked_at=?
                where token_hash=?
                  and revoked_at is null
                """,
                (_iso(_now()), _hash_token(token)),
            )
            connection.commit()
        return cursor.rowcount > 0

    def get_account_by_id(self, account_id):
        with self._session() as connection:
            row = connection.execute(
                """
                select *
                from accounts
                where account_id=?
                """,
                (account_id,),
            ).fetchone()
        if row is None:
            return None
        return self._account_from_row(row)

    def account_data(self, account_id):
        account = self.get_account_by_id(account_id)
        if account is None:
            return None
        return account["data"]

    def update_account_data(self, account_id, data):
        if not isinstance(data, dict):
            raise AccountError("Account data must be a JSON object")
        normalized = {
            **default_account_data(),
            **data,
        }
        timestamp = utc_now_iso()
        with self._session() as connection:
            cursor = connection.execute(
                """
                update accounts
                set data_json=?, updated_at=?
                where account_id=?
                """,
                (json.dumps(normalized, sort_keys=True), timestamp, account_id),
            )
            connection.commit()
        if cursor.rowcount == 0:
            return None
        return self.account_data(account_id)

    def _get_account_row_by_email(self, email):
        with self._session() as connection:
            return connection.execute(
                """
                select *
                from accounts
                where email=?
                """,
                (email,),
            ).fetchone()

    def _account_from_row(self, row):
        try:
            data = json.loads(row["data_json"])
        except (TypeError, json.JSONDecodeError):
            data = default_account_data(row["organization"])
        return {
            "accountId": row["account_id"],
            "email": row["email"],
            "displayName": row["display_name"],
            "organization": row["organization"],
            "role": row["role"],
            "authProvider": row["auth_provider"] or "password",
            "avatarUrl": row["avatar_url"] or "",
            "data": data,
            "createdAt": row["created_at"],
            "updatedAt": row["updated_at"],
        }
