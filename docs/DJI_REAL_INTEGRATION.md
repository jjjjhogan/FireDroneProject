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
```

Until these values are configured and a Cloud API adapter is connected, the app must show no aircraft.

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

Example payload:

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

The backend persists this payload to `DJI_STATE_FILE` and treats it as live only while it is newer than `DJI_TELEMETRY_TTL_SECONDS`. Stale or missing state falls back to `not-configured` and empty fleet data.

### DJI Mobile SDK Bridge

Use this path for future Android/controller direct aircraft connection. DJI Mobile SDK V5 is Android-first for current enterprise/control workflows, so Flutter web should not pretend to directly connect to an aircraft. A future Android bridge should forward verified aircraft state to the Flask backend.

Official references:

- https://developer.dji.com/mobile-sdk/
- https://developer.dji.com/api-reference-v5/android-api/index.html

## Current Safety Rules

- `ALLOW_DJI_COMMANDS=false` is the default.
- Mission preview is blocked when the connector is not configured.
- Mission confirmation is blocked unless the backend command gate is explicitly enabled.
- UI labels must not say `live`, `online`, or show battery/signal/telemetry values unless they came from a configured connector.

## Development-Only Mock Mode

Mock data is allowed only when explicitly selected:

```env
DRONE_CONNECTOR=mock
ALLOW_DJI_COMMANDS=false
```

Use mock mode only for UI development and screenshots. Do not use it to demonstrate real DJI readiness.
