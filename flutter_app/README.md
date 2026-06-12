# AeroScout Command

A Flutter web app for the FireDrone/AeroScout Command project. It provides a DJI-ready command center for wildfire patrol planning, drone fleet monitoring, guarded mission preview, analytics, and live simulation controls.

## Run

```bash
flutter pub get
flutter run -d chrome
```

## Test

```bash
flutter analyze
flutter test
flutter build web
```

Scenario and hero visuals use generated wildfire patrol landscape images stored in `assets/images/`.
They are presentation assets only; aircraft, telemetry, and connector state come from `DroneApiClient`.

## DJI Data Layer

The UI reads drone status, fleet, telemetry, and mission preview data through `DroneApiClient`.
The default client attempts the Flask backend through `HttpDroneApiClient`, then falls back to
a truthful not-configured state if the backend or DJI connector is unavailable. It does not
create fake aircraft, fake batteries, or fake telemetry for local demos.

Live command dispatch is intentionally guarded. Mission confirmation shows the package and
returns a locked state until the backend is explicitly configured with `ALLOW_DJI_COMMANDS=true`.
