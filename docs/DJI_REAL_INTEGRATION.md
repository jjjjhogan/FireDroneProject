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
```

Until these values are configured and a Cloud API adapter is connected, the app must show no aircraft.

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
