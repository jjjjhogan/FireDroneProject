# Future Integration Plan

This document lists future integrations for AeroScout Command. The current product remains a simulation-first prototype. Future work should start with read-only data and simulation adapters before any hardware command pathway is considered.

## Phase 1: Simulation Hardening

- Keep Flutter as the official-facing operations UI.
- Keep command attempts simulation-only.
- Persist scenarios, alert reviews, and audit logs in the backend.
- Add incident IDs, operator IDs, and review timestamps.
- Improve map overlays with model-driven route points, alert markers, geofences, and no-fly areas.

Current progress:

- Production persistence uses Neon Postgres through Render `DATABASE_URL`; local development falls back to SQLite.
- Alert, audit, mission, safety checklist, account user, session, and OAuth-state persistence use the shared backend database layer.
- `AUTH_REQUIRED=true` enables bearer-token RBAC for viewer/operator/admin/ingest roles.
- `/api/map/config` exposes tile-provider configuration without leaking secrets.
- `/api/map/geofence` exposes backend GeoJSON incident perimeter, mission geofence, and no-fly buffer layers.
- `/api/map/search` proxies user-triggered OpenStreetMap Nominatim place/address search for free real-world lookup.
- `/api/commands/simulate` records simulation-only command attempts and never sends hardware commands.
- `/api/safety/checklist` persists operator-visible geofence, Remote ID, airspace approval, and emergency stop checklist state.

## Phase 2: PX4 SITL

PX4 SITL should be used as a safe simulation source before real aircraft.

Planned adapter:

```text
PX4 SITL
  -> MAVSDK or MAVLink telemetry reader
  -> backend read-only adapter
  -> normalized telemetry response
  -> Flutter dashboard
```

Initial scope:

- Read position, altitude, battery, GPS, flight mode, and health
- Simulate multiple aircraft where practical
- Keep arm, takeoff, mission upload, offboard, RTL, and payload commands disabled

Current endpoint:

```text
POST /api/integrations/px4-sitl/telemetry
```

This endpoint maps PX4 SITL telemetry into the normalized aircraft feed as read-only bridge data.

## Phase 3: MAVSDK, MAVLink, And ArduPilot

MAVSDK and MAVLink can provide a common telemetry path for PX4 and ArduPilot-style systems.

Rules:

- Backend only, not direct Flutter control
- Read-only telemetry first
- SITL before hardware
- No command plugins enabled in the MVP path
- Message signing and connection security must be reviewed
- Serial, UDP, and TCP endpoints must be restricted and authenticated where possible

Future normalized models should map:

- System identity
- Battery
- GPS
- Position
- Velocity
- Heading
- Flight mode
- Health
- Mission state
- Link quality

Current endpoint:

```text
POST /api/integrations/mavlink/telemetry
```

This endpoint supports MAVLink/ArduPilot-style telemetry payloads as read-only data.

## Phase 4: DJI Cloud API And Mobile SDK

The repo already has a DJI connector boundary. Future hardening should focus on:

- DJI Cloud API worker reliability
- DJI Mobile SDK bridge validation
- Stale data handling
- Redacted secret handling
- Backend-side validation of aircraft state
- Read-only aircraft telemetry first
- Operator setup status in the UI
- Audit events for connection changes

Do not enable DJI command dispatch without a separate authorized hardware review.

## Phase 5: Drone Camera And Thermal Stream

Future camera work should use backend ingest rather than putting computer vision directly in Flutter.

Possible sources:

- DJI camera stream
- RTSP stream
- Thermal camera frame export
- Edge device snapshot upload
- Recorded incident training footage

Security and privacy requirements:

- Treat imagery and location as sensitive incident data
- Require authentication
- Avoid public bucket exposure
- Log access to incident imagery
- Support retention policy and deletion workflow

## Phase 6: YOLO Fire/Smoke API

The Flutter app should consume reviewed detection events, not raw model internals.

Recommended pipeline:

```text
Camera or image source
  -> edge or backend YOLO fire/smoke service
  -> detection event API
  -> operator review queue
  -> audit log
```

Current endpoint:

```text
POST /api/vision/alerts/ingest
```

It accepts visible and thermal frame references, stores alerts as `Unconfirmed`, and requires operator review through:

```text
POST /api/alerts/{event_id}/review
```

Detection event fields:

- Detection type
- Confidence
- Severity
- Source drone
- Frame or image reference
- Location
- Timestamp
- Review status
- Reviewer
- Review notes

All model output must remain unconfirmed until operator review.

## Phase 7: Map Provider And GIS Layers

Current implementation:

- Default satellite imagery basemap through `/api/map/config`
- Switchable OpenStreetMap raster street tile basemap through `/api/map/config`
- Backend GeoJSON layer through `/api/map/geofence`
- Backend mission map layer through `/api/map/mission`
- Backend-proxied Nominatim search through `/api/map/search`
- Tile attribution and usage policy status from `/api/map/config`
- Incident perimeter, mission geofence, and no-fly buffer feature types
- Route, alert, and drone/planned-launch markers sourced from backend map data
- Backend-computed map bounds used by Flutter for initial viewport fitting
- User-entered place/address search that focuses the Flutter map on real-world results
- Layer source and freshness metadata
- Flutter `flutter_map` rendering for backend GIS polygons and mission markers

Future map work should add:

- Terrain and road overlays
- Dedicated production tile provider such as Mapbox, ArcGIS, or an agency tile service
- Dedicated geocoding provider or self-hosted Nominatim before higher-volume production use
- Offline tile packs for field operations
- Drone positions
- Route preview
- Authoritative incident GIS imports
- Airspace/TFR provider integration
- Geofence validation against aircraft/controller limits

## Phase 8: Auth, RBAC, And Secure Deployment

Before any real incident workflow:

- Enforce authentication in production
- Enforce role-based access control in production
- Separate viewer, reviewer, operator, admin, and incident commander roles
- Keep secrets in Render or a dedicated backend secret store
- Require HTTPS
- Add CSRF/session protections where applicable
- Add structured audit logging
- Add deployment environment separation
- Add database migrations, backups, restore drills, and data-retention rules
- Review logs for sensitive data leakage

## Phase 9: Incident Command Workflow

Future official workflows should support:

- Incident selection
- Operational period
- Team assignment
- Mission package review
- Airspace approval checklist
- Remote ID checklist
- Geofence checklist
- Alert escalation
- Exportable audit and mission reports
- Read-only observer view

Current endpoint:

```text
GET /api/safety/checklist
POST /api/safety/checklist
```

This endpoint persists checklist state and review notes. It does not validate regulatory compliance or aircraft hardware state by itself.

## Hardware Gate

Any future hardware command channel requires a separate go/no-go process:

1. Legal and aviation review
2. Agency authorization
3. Security review
4. Aircraft-specific SDK review
5. Field SOPs
6. Controlled test range validation
7. Human-in-the-loop command approval
8. Persistent audit logging
9. Manual pilot/controller fallback

Until those requirements are satisfied, the app must remain simulation-first and real hardware disabled.
