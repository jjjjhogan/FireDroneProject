# AeroScout Command

Official-facing wildfire drone operations prototype for simulated mission planning, fire/smoke alert review, fleet telemetry display, and safety-gated command workflows.

This repository is not production-ready public-safety software. The current Flutter web app is a simulation-first prototype for review, planning, and integration design. Real aircraft commands are disabled by default and must remain disabled unless a future authorized hardware program completes legal, operational, security, and field-safety review.

Reference short link from the project brief: https://www.tinyurl.com/xavstev

## Purpose

AeroScout Command explores how an agency-grade wildfire drone dashboard could organize:

- Incident and mission overview
- Simulated drone telemetry
- Fire and smoke detection review
- Scenario-based mission planning
- Safety-gated simulated command attempts
- Operator-visible audit logging
- Future DJI, PX4, MAVSDK, MAVLink, camera, and vision-system integration

The prototype is intended to look serious and operational while staying honest about its limits. It does not claim production readiness, emergency response authority, or certified aircraft control.

## Current Status

- Frontend: Flutter web app in `flutter_app/`
- Backend: Flask API in `backend/`
- Production deployment: Render frontend + Render backend
- Production database: Neon Postgres via Render `DATABASE_URL`
- Local development database: SQLite fallback when `DATABASE_URL` is unset
- Default mode: simulation and read-only connector status
- Real hardware command dispatch: disabled
- Mission commands in the UI: simulated only
- Fire/smoke detections: mock events requiring human review
- Audit log: persisted through the backend store

## Features

### Official Dashboard

- System mode, safety lock, data source, active detections, mission status, and telemetry freshness
- Clear `Simulation Mode`, `Real Hardware Disabled`, and `Not production ready` labels
- Mission overview panel
- Drone telemetry panel
- Operations map with default satellite imagery, switchable OpenStreetMap street tiles, backend GeoJSON geofence, route, drone, and alert overlays
- Fire/smoke alert review workflow
- Safety-gated simulated command panel
- Audit log for alert reviews and command attempts

### Scenario Library

- Credible wildfire scenario cards with region, difficulty, drone count, alert count, tags, and description
- Search and region filtering
- Selected scenario planning panel
- `Open Selected Scenario` and per-card `Open in Simulator` actions
- Mobile-friendly wrapped filters

### Safety Behavior

Every command button is routed through `SafetyGateService`:

1. The operator must confirm the simulated command.
2. A `CommandRequest` is built.
3. `SafetyGateService` returns a `CommandResult`.
4. The command attempt creates an `AuditLogEntry`.
5. No hardware command is sent.

Emergency Stop currently changes local and backend simulation safety state. It is not a physical aircraft kill switch.

### Backend Persistence, Auth, And Integrations

The backend includes a shared persistence layer for public-safety prototype data. Production uses Neon Postgres through `DATABASE_URL`; local development falls back to SQLite when `DATABASE_URL` is unset.

- `GET /api/auth/session`
- `GET /api/integrations/status`
- `GET /api/map/config`
- `GET /api/map/geofence`
- `GET /api/map/mission`
- `GET /api/map/search?q=<place-or-address>`
- `GET /api/safety/checklist`
- `POST /api/safety/checklist`
- `GET /api/alerts`
- `POST /api/vision/alerts/ingest`
- `POST /api/alerts/<event_id>/review`
- `GET /api/audit`
- `POST /api/commands/simulate`
- `POST /api/integrations/px4-sitl/telemetry`
- `POST /api/integrations/mavlink/telemetry`

The persisted data includes operations alerts, audit entries, safety checklist state, missions, account users, sessions, and Google OAuth state. See [docs/NEON_POSTGRES.md](docs/NEON_POSTGRES.md) for deployment and verification details.

`AUTH_REQUIRED=true` enables bearer-token RBAC. Prototype roles are `viewer`, `operator`, `admin`, and `ingest`. Flutter can pass a token with:

```bash
/Users/xavier/development/flutter/bin/flutter run -d chrome \
  --dart-define=PUBLIC_SAFETY_TOKEN=operator-token
```

The original DJI connection channel remains available in `Live Simulator`. The official dashboard also exposes `Connect DJI Drone`, which opens the same Cloud API / Mobile SDK bridge setup dialog.

### About & Safety Screen

The Flutter app includes an `About & Safety` tab with:

- Official/public-safety prototype status
- Simulation mode disclaimer
- Real hardware disabled disclaimer
- GitHub integration references
- Future integration roadmap
- Safety rules and limitations

## Architecture

```text
FireDroneProject/
├── backend/
│   ├── app/dji/                 # DJI connector boundary, ingest, state store
│   ├── app/routes/api.py        # REST endpoints consumed by Flutter
│   ├── scripts/                 # DJI Cloud MQTT and Mobile SDK helper scripts
│   └── tests/test_dji_api.py    # Backend connector and safety tests
├── flutter_app/
│   ├── lib/app/                 # Material app and tab shell
│   ├── lib/models/              # Mission, scenario, alert, telemetry, safety, audit models
│   ├── lib/services/            # API clients and mock simulation services
│   ├── lib/screens/             # Dashboard, simulator, scenario library, fleet, analytics, docs
│   ├── lib/safety/              # SafetyGateService
│   ├── lib/mock/                # Simulation fixtures
│   └── test/                    # Widget and service/model tests
└── docs/
    ├── DJI_REAL_INTEGRATION.md
    ├── GITHUB_INTEGRATION_REVIEW.md
    ├── SAFETY.md
    └── FUTURE_INTEGRATION.md
```

The Flutter app reads current DJI connector status through `DroneApiClient`. When the backend is unavailable or not configured, the UI shows unavailable or not-configured states rather than pretending aircraft are connected.

## Mocked Parts

The current MVP uses mocked or placeholder data for:

- Drone telemetry cards in the official dashboard
- Fire/smoke alert events
- Mission overview fixture
- Operations map route and alert overlays layered over backend GIS data
- User-triggered real place search through backend-proxied OpenStreetMap Nominatim
- Scenario catalog
- Geofence validation, Remote ID hardware proof, airspace authority verification, and emergency stop hardware behavior

The backend persists alerts, audit entries, account sessions, Google OAuth state, and an operator safety checklist through SQLite locally or Neon Postgres in production. It can ingest read-only PX4 SITL / MAVLink telemetry plus YOLO/thermal alert events. It exposes tile-provider config with attribution and tile usage policy at `/api/map/config`, GeoJSON geofence layers at `/api/map/geofence`, mission route / alert / drone map markers plus computed bounds at `/api/map/mission`, and user-triggered place/address search at `/api/map/search`. The planning map defaults to a satellite imagery basemap so the incident surface looks like a real-world map, while OpenStreetMap street tiles remain available as a switchable layer. The default search provider is OpenStreetMap Nominatim, proxied through Flask so the app can set an identifying User-Agent and later swap providers without changing Flutter. The Flutter map fits its initial viewport to backend bounds and can focus on a searched real-world place. Geofence, Remote ID, airspace approval, and emergency stop are represented as auditable checklist/simulation state, not validated aircraft or regulatory compliance. The Flutter app remains simulation-first and does not dispatch real aircraft commands.

## Run Locally

### Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python run.py
```

The API runs at `http://127.0.0.1:5000`.

Important defaults:

```env
DRONE_CONNECTOR=real
ALLOW_DJI_COMMANDS=false
AUTH_REQUIRED=false
PUBLIC_SAFETY_TOKENS=viewer-token:viewer,operator-token:operator,admin-token:admin,ingest-token:ingest
APP_DATABASE_FILE=
MAP_PROVIDER=openstreetmap
MAP_TILE_URL_TEMPLATE=https://tile.openstreetmap.org/{z}/{x}/{y}.png
MAP_ATTRIBUTION=OpenStreetMap contributors
MAP_API_KEY=
MAP_DEFAULT_BASEMAP=satellite
MAP_IMAGERY_PROVIDER=arcgis-world-imagery
MAP_IMAGERY_TILE_URL_TEMPLATE=https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}
MAP_IMAGERY_ATTRIBUTION=Powered by Esri | Sources: Esri, Maxar, Earthstar Geographics, and the GIS User Community
MAP_SEARCH_PROVIDER=nominatim
NOMINATIM_SEARCH_URL=https://nominatim.openstreetmap.org/search
NOMINATIM_USER_AGENT=FireDroneProject/0.1 public-safety-prototype
MAP_SEARCH_LIMIT=5
```

The public Nominatim endpoint is a limited free service. Keep searches user-triggered, avoid autocomplete or bulk geocoding, cache repeated queries before higher-volume use, and stay under the OpenStreetMap Foundation usage policy.

Use `DRONE_CONNECTOR=mock` only for explicit development demos.

### Local EMQX (Docker)

For DJI Cloud API MQTT development:

```bash
cd backend
docker compose -f docker-compose.emqx.yml up -d
```

See [docs/EMQX_SETUP.md](docs/EMQX_SETUP.md) for `.env` values and verification steps.

### Flutter Web

```bash
cd flutter_app
/Users/xavier/development/flutter/bin/flutter pub get
/Users/xavier/development/flutter/bin/flutter run -d chrome
```

For a static web build:

```bash
cd flutter_app
/Users/xavier/development/flutter/bin/flutter build web
python3 -m http.server 8146 --bind 127.0.0.1 -d build/web
```

Then open `http://127.0.0.1:8146/`.

To test the same API-base wiring used by Render:

```bash
cd flutter_app
/Users/xavier/development/flutter/bin/flutter build web \
  --dart-define=FIRE_DRONE_API_BASE=http://127.0.0.1:5000/api
```

## Deploy On Render

The repository includes a root `render.yaml` Blueprint for two Render services:

- `firedrone-api`: Flask backend Web Service
- `firedrone-command`: Flutter web Static Site

Render will read `render.yaml` from the repository root. The backend uses:

```bash
pip install -r requirements.txt
gunicorn --bind 0.0.0.0:$PORT wsgi:app
```

The frontend uses `flutter_app/render-build.sh`, which downloads Flutter `3.44.1` in Render's build environment and runs:

```bash
flutter build web --release --dart-define=FIRE_DRONE_API_BASE=https://firedrone-api.onrender.com/api
```

Production environment values to verify in Render:

```env
DRONE_CONNECTOR=mock
ALLOW_DJI_COMMANDS=false
AUTH_REQUIRED=false
DATABASE_URL=<Neon pooled Postgres connection string stored as a Render secret>
GOOGLE_OAUTH_RUNTIME_CONFIG_ALLOWED=false
GOOGLE_OAUTH_CLIENT_ID=<Google OAuth web client id>
GOOGLE_OAUTH_CLIENT_SECRET=<Google OAuth web client secret>
GOOGLE_OAUTH_REDIRECT_URI=https://firedrone-api.onrender.com/api/accounts/google/callback
FRONTEND_APP_URL=https://firedrone-command.onrender.com/
FIRE_DRONE_API_BASE=https://firedrone-api.onrender.com/api
```

If Render assigns different service URLs, update `FRONTEND_APP_URL`,
`FIRE_DRONE_API_BASE`, and `GOOGLE_OAUTH_REDIRECT_URI` in Render. Also add the
final callback URL to Google Cloud Console under the OAuth web client's
authorized redirect URIs.

The current production backend is configured to use Neon Postgres. Do not commit the Neon connection string. Store it only in Render as `DATABASE_URL`.

## Verification

From `flutter_app/`:

```bash
/Users/xavier/development/flutter/bin/flutter analyze
/Users/xavier/development/flutter/bin/flutter test
```

Backend tests:

```bash
backend/.venv/bin/python -m unittest discover -s backend/tests
```

## GitHub References

The project architecture was influenced by:

- ADOSMissionControl: command-center layout, telemetry grouping, mission planning, and adapter separation
- wildfire-detection: fire/smoke detection confidence, frame, and review concepts
- Real-Time-Fire-Smoke-Detection-Drone: future edge inference and geotagged alert ingest concepts
- PX4, MAVSDK, MAVLink, and ArduPilot: future simulation and read-only telemetry adapter direction

These projects are references only. Their source code was not copied into this Flutter app.

See [docs/GITHUB_INTEGRATION_REVIEW.md](docs/GITHUB_INTEGRATION_REVIEW.md).

## Safety Note

Do not use this app to fly drones in real wildfire areas. Wildfire response airspace is safety-critical and often restricted. Real operations require authorization, trained pilots, compliant aircraft, Remote ID and airspace review, agency procedures, incident command coordination, and local law compliance.

See [docs/SAFETY.md](docs/SAFETY.md).

## Future Plan

Future work should proceed in simulation and read-only phases first:

- PX4 SITL and MAVSDK/MAVLink telemetry adapters
- ArduPilot compatibility through backend adapters
- Drone camera stream and thermal camera ingest
- YOLO fire/smoke detection API
- Production GIS sources, terrain overlays, and authoritative airspace layers
- Authentication, RBAC, secure deployment, and incident command workflow
- Database migrations, backups, and data-retention policies for Neon Postgres
- Persistent DJI runtime state beyond the current JSON-backed bridge files

See [docs/FUTURE_INTEGRATION.md](docs/FUTURE_INTEGRATION.md).
See [docs/PRODUCTION_READINESS_TASKS.md](docs/PRODUCTION_READINESS_TASKS.md) for the current optimization task list.

## Limitations

- Not production-ready
- Not certified for emergency response
- Not a ground control station
- No real aircraft command dispatch
- Neon Postgres persistence is enabled in production, but migrations, backups, retention, and incident-certified storage controls are still future work
- Satellite and OpenStreetMap basemaps plus backend GeoJSON geofence layers exist, but authoritative incident GIS and regulatory validation are still future work
- Nominatim search is a free public lookup path for development and moderate manual use, not a production geocoding SLA
- Safety checklist state is auditable, but does not prove regulatory or aircraft compliance
- RBAC is bearer-token prototype auth, not enterprise identity management
- No validated fire detection model in the Flutter app
- No legal, aviation, or agency approval implied
