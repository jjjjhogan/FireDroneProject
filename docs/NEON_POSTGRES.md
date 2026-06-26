# Neon Postgres on Render

Production deployments use **Neon Postgres** instead of SQLite. Render's web service filesystem is ephemeral, so SQLite files are lost on redeploy.

## Current production status

- Render backend service: `firedrone-api`
- Render frontend service: `firedrone-command`
- Database provider: Neon Postgres
- Render secret: `DATABASE_URL`
- Verified: 2026-06-24 production backend returned `"persistence": { "engine": "postgresql", ... }`

The Neon connection string is a secret. Keep it in Render or a secret manager, never in git, screenshots, or public logs.

## How it works

When `DATABASE_URL` is set, the backend uses **PostgreSQL** for:

- Operations data (`OperationsStore`): alerts, audit log, safety checklist, missions
- Account data (`AccountStore`): users, sessions, OAuth state

When `DATABASE_URL` is unset, local dev falls back to `APP_DATABASE_FILE` (SQLite).

Both stores share one database URL.

## Render setup

1. Create a [Neon](https://neon.tech) project.
2. Copy the connection string (`postgresql://...` or `postgres://...`).
3. In Render → **firedrone-api** → **Environment**, add:

```env
DATABASE_URL=postgresql://USER:PASSWORD@HOST/DBNAME?sslmode=require
```

4. Redeploy the web service. Tables are created automatically on first request.

You can remove reliance on `APP_DATABASE_FILE` in production once `DATABASE_URL` is set.

## Local dev

Keep using SQLite (no Neon required):

```env
# Do not set DATABASE_URL locally
APP_DATABASE_FILE=instance/operations.sqlite3
```

Optional: point local `.env` at a Neon **branch** for shared staging data:

```env
DATABASE_URL=postgresql://...@ep-....neon.tech/neondb?sslmode=require
```

## Verify

```bash
curl https://firedrone-api.onrender.com/api/integrations/status \
  -H "Authorization: Bearer viewer-token"
```

Look for `"persistence": { "engine": "postgresql", ... }`.

## Blueprint

[`render.yaml`](../render.yaml) includes `DATABASE_URL` with `sync: false` so you paste the Neon secret in the Render dashboard (not committed to git).

## Follow-up tasks

- Add schema migrations before the data model grows further.
- Add a Neon backup and restore runbook.
- Add separate local/staging/production database environments.
- Move remaining JSON-backed DJI runtime state to durable storage or a persistent volume.
- Add a database-specific health endpoint that checks connectivity without exposing connection details.

## Notes

- DJI state files (`DJI_STATE_FILE`, runtime config) remain JSON on disk — only ops/account tables moved to Postgres.
- For durable DJI state on Render, use a persistent disk or external storage in a follow-up task.
