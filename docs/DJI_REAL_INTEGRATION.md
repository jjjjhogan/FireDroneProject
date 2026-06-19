# DJI Real Integration

This branch no longer treats simulated DJI aircraft as the default product state.
If real DJI data is not configured, the backend and Flutter app intentionally show:

- `connection: not-configured`
- `liveData: false`
- empty fleet
- telemetry link health `not-configured`
- blocked mission preview and command confirmation

## Supported Paths

### DJI Cloud API

Use this path for DJI Pilot 2 or DJI Dock workflows. DJI Cloud API is designed so DJI Pilot 2 or DJI Dock connects the aircraft ecosystem to a third-party cloud platform through DJI-supported cloud protocols.

Official references:

- https://developer.dji.com/cloud-api
- https://developer.dji.com/doc/cloud-api-tutorial/en/

Required backend environment contract:

```env
DRONE_CONNECTOR=real
ALLOW_DJI_COMMANDS=false
DJI_CLOUD_API_APP_ID=
DJI_CLOUD_API_APP_KEY=
DJI_CLOUD_API_APP_LICENSE=
DJI_CLOUD_API_MQTT_HOST=
DJI_WORKSPACE_ID=
DJI_INGEST_TOKEN=
DJI_STATE_FILE=
DJI_TELEMETRY_TTL_SECONDS=300
DJI_MAX_INGEST_DRONES=16
DJI_CLOUD_MQTT_PORT=8883
DJI_CLOUD_MQTT_USE_TLS=true
DJI_CLOUD_MQTT_USERNAME=
DJI_CLOUD_MQTT_PASSWORD=
DJI_CLOUD_MQTT_CLIENT_ID=firedrone-cloud-worker
DJI_AUTO_START_CLOUD_BRIDGE=true
FIRE_DRONE_API_BASE=http://127.0.0.1:5000/api
```

For local MQTT development with Docker EMQX, see [EMQX_SETUP.md](EMQX_SETUP.md). Typical local values: `DJI_CLOUD_API_MQTT_HOST=127.0.0.1`, `DJI_CLOUD_MQTT_PORT=1883`, `DJI_CLOUD_MQTT_USE_TLS=false`.

Until these values are configured and a Cloud API adapter is connected, the app must show no aircraft.

## Connection States

The backend now reports distinct states so a real DJI setup is easier to debug:

- `not-configured`: no DJI ingest token and no complete Cloud API configuration.
- `waiting-for-bridge`: `DJI_INGEST_TOKEN` is configured, but no bridge has posted data yet.
- `bridge-online`: a Cloud API or Mobile SDK bridge has posted a fresh heartbeat or aircraft state.
- `bridge-stale`: the last bridge update is older than `DJI_TELEMETRY_TTL_SECONDS`.

`liveData` is `true` only when the fresh bridge state includes at least one aircraft. A bridge heartbeat with zero aircraft keeps the connection online but does not invent fleet or telemetry values.

## Website Connection Setup

Operators can configure the local backend from the Flutter web app:

1. Open `Live Simulator`.
2. Click `Connect DJI` in the mission map area or `Connect DJI Drone` in the official dashboard header.
3. Choose `Cloud API` or `Mobile SDK`.
4. Click `Generate token` to create the backend ingest token, or paste an existing token.
5. Enter only the required connection fields.
6. Open `Advanced settings` only when you need port, client ID, workspace, app key, or license overrides.
7. Save the connection.

The browser sends the secret fields to the local Flask backend. The backend stores them in `DJI_RUNTIME_CONFIG_FILE`, which defaults to `backend/instance/dji_runtime_config.json`. The app never returns saved token, password, app key, or license values back to the browser; it only returns redacted `...Configured` booleans.

The runtime config file is ignored by git through `backend/instance/`.

Backend endpoints used by the setup dialog:

```text
GET /api/dji/connection
POST /api/dji/connection
POST /api/dji/connection/token
```

When Cloud API mode is saved with a valid MQTT host and ingest token, the backend attempts to start an in-process MQTT listener for:

```text
thing/product/+/osd
thing/product/+/state
```

When `DJI_AUTO_START_CLOUD_BRIDGE=true` (default), the same listener also starts on Flask boot if `.env` (and optional runtime config overrides) already provide `DJI_CLOUD_API_MQTT_HOST` and `DJI_INGEST_TOKEN`. Set the flag to `false` to require an explicit save or POST first.

For production deployment, run the Flask backend behind HTTPS before accepting real operator secrets in a browser form.

## Real Bridge Ingest API

The production UI reads only these backend DJI connector endpoints:

```text
GET /api/dji/status
GET /api/dji/fleet
GET /api/dji/telemetry
POST /api/dji/missions/preview
POST /api/dji/missions/confirm
```

To feed real data into those endpoints, connect a DJI Cloud API worker or DJI Mobile SDK Android bridge to:

```text
POST /api/dji/ingest/state
Authorization: Bearer <DJI_INGEST_TOKEN>
Content-Type: application/json
```

Canonical payload:

```json
{
  "source": "mobile-sdk-bridge",
  "drones": [
    {
      "id": "real-m3e-01",
      "name": "Matrice Field Unit",
      "model": "DJI Matrice 30T",
      "connection": "online",
      "batteryPct": 91,
      "signalPct": 88,
      "lat": 34.62,
      "lng": -119.72,
      "altitudeM": 122,
      "lastSeen": "2026-06-11T17:55:00+00:00",
      "warnings": []
    }
  ],
  "telemetry": {
    "activeDroneId": "real-m3e-01",
    "missionState": "device-online",
    "routeProgressPct": 12,
    "windMph": 9,
    "temperatureF": 81,
    "firePerimeterRisk": "operator-feed",
    "linkHealth": "stable"
  }
}
```

The backend persists this payload to `DJI_STATE_FILE` and treats it as live only while it is newer than `DJI_TELEMETRY_TTL_SECONDS`. Stale state reports `bridge-stale`; missing bridge state reports `waiting-for-bridge` when `DJI_INGEST_TOKEN` is configured, otherwise `not-configured`.

Bad payloads are rejected with HTTP `400` and do not overwrite the last known valid bridge state. The backend validates:

- aircraft count limit
- required aircraft `id`
- battery/signal percentages
- latitude/longitude bounds
- altitude bounds
- ISO-8601 `lastSeen`
- telemetry numeric ranges where configured

### DJI Cloud API MQTT Worker

Use this path when DJI Pilot 2, DJI Dock, or a Cloud API worker can receive MQTT device-property topics. The website connection dialog can start the backend listener automatically. You can also run the worker manually:

```bash
cd backend
source .venv/bin/activate
python scripts/dji_cloud_mqtt_worker.py \
  --mqtt-host "$DJI_CLOUD_API_MQTT_HOST" \
  --mqtt-username "$DJI_CLOUD_MQTT_USERNAME" \
  --mqtt-password "$DJI_CLOUD_MQTT_PASSWORD" \
  --api-base "$FIRE_DRONE_API_BASE" \
  --token "$DJI_INGEST_TOKEN"
```

Default subscribed topics:

```text
thing/product/+/osd
thing/product/+/state
```

The worker forwards to:

```text
POST /api/dji/ingest/cloud-api
```

The backend maps common Cloud API device-property fields such as serial number, latitude, longitude, height, battery capacity, wireless link quality, and flight mode into `DroneSummary` and `TelemetrySnapshot`.

### DJI Mobile SDK Bridge

Use this path for future Android/controller direct aircraft connection. DJI Mobile SDK V5 is Android-first for current enterprise/control workflows, so Flutter web should not pretend to directly connect to an aircraft. A future Android bridge should forward verified aircraft state to the Flask backend.

Official references:

- https://developer.dji.com/mobile-sdk/
- https://developer.dji.com/api-reference-v5/android-api/index.html

Implemented bridge targets:

```text
POST /api/dji/ingest/mobile-sdk
backend/scripts/post_mobile_sdk_state.py
```

For local smoke testing without an Android build:

```bash
cd backend
DJI_INGEST_TOKEN=bridge-secret \
python scripts/post_mobile_sdk_state.py --sample \
  --api-base http://127.0.0.1:5000/api
```

In a real DJI Mobile SDK app, read aircraft state from SDK callbacks and POST the normalized payload to `/api/dji/ingest/mobile-sdk` every 1-5 seconds while monitoring.

## Current Safety Rules

- `ALLOW_DJI_COMMANDS=false` is the default.
- Mission preview is blocked when the connector is not configured.
- Mission confirmation is blocked unless the backend command gate is explicitly enabled.
- UI labels must not say `live`, `online`, or show battery/signal/telemetry values unless they came from a configured connector.
- Cloud API and Mobile SDK ingest update monitoring state only. They do not dispatch takeoff, waypoint, virtual-stick, return-to-home, or payload commands.

## Development-Only Mock Mode

Mock data is allowed only when explicitly selected:

```env
DRONE_CONNECTOR=mock
ALLOW_DJI_COMMANDS=false
```

Use mock mode only for UI development and screenshots. Do not use it to demonstrate real DJI readiness.
