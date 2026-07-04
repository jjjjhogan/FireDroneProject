# Production Verification

Last updated: 2026-06-25

This log records the Neon Postgres and Render production-readiness checks for `firedrone-api`. Do not include database URLs, OAuth secrets, account tokens, or DJI credentials in this file.

## Environment

- Render service: `firedrone-api`
- Render source branch: `codex/account-data-login`
- Production code verified after deploy: `15f63c2 Fix Postgres executemany fallback`
- `DATABASE_URL`: configured in Render as a secret
- Database provider: Neon Postgres
- `APP_DATABASE_FILE`: not present in the Render environment
- `render.yaml`: keeps `DATABASE_URL` as `sync: false`

## Live API Checks

Commands:

```bash
curl -fsS https://firedrone-api.onrender.com/health
curl -fsS https://firedrone-api.onrender.com/api/integrations/status \
  -H "Authorization: Bearer viewer-token"
curl -fsS https://firedrone-api.onrender.com/api/accounts/google/status
```

Results:

- `/health`: `{"service":"FireDrone API","status":"ok"}`
- `/api/integrations/status`: `persistence.enabled=true`, `persistence.engine=postgresql`
- `/api/accounts/google/status`: `configured=true`, client ID configured, client secret configured, setup disabled in production

## Persistence Smoke

Test account:

- Email: `neon-smoke-20260625-183111@example.com`
- Account ID: `acct-1b33a1e4189a`

Durable write:

- Endpoint: `POST /api/safety/checklist`
- Field: `geofence.notes`
- Smoke note: unique Neon persistence marker tied to the test account ID

Restart verification:

- Render service was restarted after the write.
- `GET /api/safety/checklist` still returned the smoke note after restart.
- The original `geofence` checklist value was restored after verification.

## Postgres Bug Found And Fixed

The first production smoke attempt returned `500` for `POST /api/safety/checklist`.

Root cause:

- `OperationsStore.update_safety_checklist()` uses `_ConnectionProxy.executemany()`.
- SQLite connections support `executemany()`.
- psycopg3 Postgres connections do not expose `Connection.executemany()`.

Fix:

- `_ConnectionProxy.executemany()` now uses the native `executemany()` path when available.
- For psycopg3 connections, it falls back to repeated `execute()` calls with adapted Postgres placeholders.

Regression coverage:

- Added `ConnectionProxyTest.test_postgres_executemany_uses_execute_when_driver_lacks_executemany`.
- This is a targeted Postgres compatibility unit test; the integration suite still uses tempfile SQLite by design.

## Test Results

Command:

```bash
backend/.venv/bin/python -m unittest discover -s backend/tests -v
```

Result:

- `Ran 49 tests`
- `OK`

## Google OAuth Status

Verified:

- Production Google OAuth config endpoint reports `configured=true`.
- Real OAuth start reaches the Google account chooser for `firedrone-api.onrender.com`.

Pending manual step:

- Full login -> logout -> login verification is blocked on the Google account chooser because the browser automation layer could not activate the visible Google account row.
- The visible account row is `Xavier / biaobiao1115@gmail.com`.
- Continue verification by selecting the visible account manually, then completing `POST /api/accounts/session/complete`, `POST /api/accounts/logout`, and a second OAuth login.

## Secret Check

- No Neon connection string was added to git.
- No Google OAuth secret was added to git.
- No account token was added to git.
