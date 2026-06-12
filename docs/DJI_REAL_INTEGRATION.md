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
DJI_CLOUD_MQTT_USERNAME=
DJI_CLOUD_MQTT_PASSWORD=
DJI_CLOUD_MQTT_CLIENT_ID=firedrone-cloud-worker
FIRE_DRONE_API_BASE=http://127.0.0.1:5000/api
```

Until these values are configured and a Cloud API adapter is connected, the app must show no aircraft.

## Connection States

The backend now reports distinct states so a real DJI setup is easier to debug:

- `not-configured`: no DJI ingest token and no complete Cloud API configuration.
- `waiting-for-bridge`: `DJI_INGEST_TOKEN` is configured, but no bridge has posted data yet.
- `bridge-online`: a Cloud API or Mobile SDK bridge has posted a fresh heartbeat or aircraft state.
- `bridge-stale`: the last bridge update is older than `DJI_TELEMETRY_TTL_SECONDS`.

`liveData` is `true` only when the fresh bridge state includes at least one aircraft. A bridge heartbeat with zero aircraft keeps the connection online but does not invent fleet or telemetry values.

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

Use this path when DJI Pilot 2, DJI Dock, or a Cloud API worker can receive MQTT device-property topics. The worker subscribes to DJI Cloud API `osd` and `state` topics and forwards each message to the backend:

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
mobile/android_bridge/MobileSdkBridgeClient.kt
backend/scripts/post_mobile_sdk_state.py
```

The Android bridge client accepts controller, aircraft, and flight snapshots and posts them to the backend. For local smoke testing without an Android build:

```bash
cd backend
DJI_INGEST_TOKEN=bridge-secret \
python scripts/post_mobile_sdk_state.py --sample \
  --api-base http://127.0.0.1:5000/api
```

In a real DJI Mobile SDK app, read aircraft state from SDK callbacks, build a `MobileSdkAircraftSnapshot` and `MobileSdkFlightSnapshot`, then call `MobileSdkBridgeClient.postSnapshot(...)` every 1-5 seconds while monitoring.

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
