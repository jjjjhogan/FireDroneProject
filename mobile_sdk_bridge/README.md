# FireDrone Mobile SDK Android Bridge

Minimal Android field bridge that forwards DJI aircraft telemetry to the FireDrone Flask backend.

- **Phase A (implemented):** stub bridge — no DJI hardware required; posts the same sample payload as `backend/scripts/post_mobile_sdk_state.py`.
- **Phase B (planned):** integrate DJI Mobile SDK V5 and map live SDK callbacks to the ingest JSON shape.

## Architecture

```text
Android bridge app  --HTTP POST-->  Flask API (/api/dji/ingest/mobile-sdk)
                                           |
                                           v
                                   Flutter web (fleet / telemetry / status)
```

This bridge is **telemetry-only**. It never sends takeoff, waypoint, RTL, or other flight commands. Keep `ALLOW_DJI_COMMANDS=false` on the backend.

## Prerequisites

- Android Studio Hedgehog (2023.1.1) or newer
- JDK 17
- FireDrone backend running locally or on Render
- `DJI_INGEST_TOKEN` matching the backend (from `.env`, Connect DJI dialog, or `POST /api/dji/connection/token`)

## Quick start (Phase A stub)

### 1. Start the backend

```bash
cd backend
# .env must include DJI_INGEST_TOKEN=your-token
python run.py
```

### 2. Smoke test without Android (optional)

```bash
cd backend
DJI_INGEST_TOKEN=your-token python scripts/post_mobile_sdk_state.py --sample \
  --api-base http://127.0.0.1:5000/api
```

Expect HTTP `202`. Then open Flutter web and confirm `GET /api/dji/status` shows `bridge-online` and `liveData: true`.

### 3. Open the Android project

```bash
cd mobile_sdk_bridge/android
```

Open this folder in Android Studio. Sync Gradle, then run on an emulator or device.

### 4. Configure the app

| Field | Local dev | Production |
|-------|-----------|------------|
| API base URL | `http://10.0.2.2:5000/api` (emulator → host) or `http://<LAN-IP>:5000/api` (physical device) | `https://firedrone-api.onrender.com/api` |
| Ingest token | Same as backend `DJI_INGEST_TOKEN` | Same token configured on Render |

Tap **Save settings**, then **Start posting**. Status should show HTTP `202` and a JSON body with `source: mobile-sdk-bridge`.

Physical devices cannot reach `127.0.0.1` on your laptop — use your machine's LAN IP.

## Secrets (never commit)

| Secret | Where it goes |
|--------|----------------|
| `DJI_INGEST_TOKEN` | Enter in app UI (stored in DataStore on device) |
| DJI app key / license (Phase B) | `local.properties` as `dji.app.key=` — file is gitignored |

Example `local.properties` (create locally, not in git):

```properties
sdk.dir=C\:\\Users\\You\\AppData\\Local\\Android\\Sdk
dji.app.key=your-dji-developer-app-key
```

## Phase B — DJI Mobile SDK V5 (not yet wired)

When you have a DJI developer account, app key, and supported aircraft/controller:

1. Register at [DJI Developer](https://developer.dji.com/mobile-sdk/).
2. Add the Mobile SDK V5 dependency per [Android API reference](https://developer.dji.com/api-reference-v5/android-api/index.html).
3. Put `dji.app.key` in `local.properties`.
4. Replace stub payload assembly in `TelemetryPoster` with SDK listener callbacks mapped to fields in `backend/app/dji/mobile_sdk.py`.

Supported enterprise aircraft vary by SDK version; confirm against DJI docs before field deployment.

## Project layout

```text
mobile_sdk_bridge/
  README.md
  android/
    app/src/main/java/com/firedrone/mobilesdkbridge/
      data/SamplePayload.kt      # stub JSON (matches post_mobile_sdk_state.py)
      data/SettingsRepository.kt # API base + token persistence
      network/IngestClient.kt      # POST /dji/ingest/mobile-sdk
      telemetry/TelemetryPoster.kt
      ui/BridgeApp.kt
```

## Verification checklist

- [ ] Backend returns `202` for ingest POST
- [ ] `GET /api/dji/status` → `connection: bridge-online`, `bridge.adapter: mobile-sdk`, `liveData: true`
- [ ] Flutter fleet shows `msdk-m3t-01` while bridge is running
- [ ] App survives API offline (shows error, retries on next interval, no crash)

See also [docs/MOBILE_SDK_BRIDGE.md](../docs/MOBILE_SDK_BRIDGE.md).
