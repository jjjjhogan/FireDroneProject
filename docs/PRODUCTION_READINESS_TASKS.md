# Production Readiness Tasks

Last updated: 2026-06-24

This task list tracks the next practical upgrades for AeroScout Command now that the production backend uses Neon Postgres through Render `DATABASE_URL`.

## Current Production Baseline

- Frontend: Render static site `firedrone-command`
- Backend: Render web service `firedrone-api`
- Database: Neon Postgres stored in Render as `DATABASE_URL`
- Database status: live backend reports `persistence.engine=postgresql`
- Google login: configured through the Render backend callback
- DJI commands: disabled by `ALLOW_DJI_COMMANDS=false`
- Connector mode: mock/read-only by default

Secrets must stay in Render or a dedicated secret manager. Do not commit the Neon connection string, Google OAuth secret, or DJI credentials.

## Completed

- Add shared backend database layer with SQLite local fallback and Postgres production support.
- Persist operations alerts, audit entries, missions, safety checklist state, account users, sessions, and OAuth state.
- Configure production `firedrone-api` with Neon Postgres via Render `DATABASE_URL`.
- Redeploy production backend after the database switch.
- Verify production health and PostgreSQL persistence status.

## High Priority

- Add a migration workflow instead of relying only on create-table-on-start behavior.
- Add a database backup and restore runbook for Neon.
- Add environment separation: local, staging, and production databases should not share data.
- Add server-side session expiration, refresh, and logout cleanup for Google login.
- Add production auth enforcement before storing real incident or operator data.
- Move remaining DJI runtime JSON state to durable storage or a managed persistent volume.
- Add a `/api/health/database` check that validates database connectivity without exposing secrets.
- Add secret-rotation notes for Neon, Google OAuth, DJI keys, and map providers.

## Medium Priority

- Add structured audit events for login, logout, database writes, connector state changes, and mission preview actions.
- Add admin-only data export for audit logs and alert reviews.
- Add data retention rules for alerts, sessions, OAuth state, and mission records.
- Add rate limits for auth, map search, ingest, and mission-preview endpoints.
- Add Sentry or similar backend/frontend error reporting with secret redaction.
- Add Render deploy smoke tests that call health, account status, integrations status, map config, alerts, and audit endpoints.
- Add a staging Neon branch for testing migrations before production.

## Product And UX Optimizations

- Make the dashboard distinguish mock data, persisted backend data, and real connector data more visibly.
- Add an operator setup checklist that shows Google login, database, map provider, DJI connector, and command safety status.
- Replace remaining fake-looking UI states with backend-backed empty, waiting, or blocked states.
- Add a mission package review screen with route, risk, checklist, operator identity, and audit trail before confirmation.
- Add a production map-provider path so the current development satellite tiles are not mistaken for an SLA-backed map service.

## Validation Checklist

Run after any production database or auth change:

```bash
curl -fsS https://firedrone-api.onrender.com/health
curl -fsS https://firedrone-api.onrender.com/api/integrations/status
curl -fsS https://firedrone-api.onrender.com/api/accounts/google/status
```

Expected database signal:

```json
{
  "persistence": {
    "enabled": true,
    "engine": "postgresql"
  }
}
```

## Not Yet Production Ready

- No incident-certified storage controls
- No formal migrations
- No backup/restore drill
- No production RBAC enforcement by default
- No real aircraft command dispatch
- No authoritative airspace, Remote ID, or geofence validation
- No durable DJI runtime state beyond the operations/account database
