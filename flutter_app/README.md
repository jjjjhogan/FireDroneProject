# AeroScout Sim

A Flutter web prototype for the FireDrone/AeroScout Command project. It turns the design preview into an interactive DJI-ready command center for wildfire patrol planning, drone fleet monitoring, guarded mission preview, analytics, and live simulation controls.

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

## DJI Data Layer

The UI reads drone status, fleet, telemetry, and mission preview data through `DroneApiClient`.
The default client is a safe mock feed for local demos. `HttpDroneApiClient` is ready to point
at the Flask backend when running `backend/run.py`.

Live command dispatch is intentionally guarded. Mission confirmation shows the package and
returns a locked state until the backend is explicitly configured with `ALLOW_DJI_COMMANDS=true`.
