# FireDrone Project

https://www.tinyurl.com/xavstev

A fire drone monitoring system with a **Flask** backend API, the original **Flutter** mobile app, and a new **AeroScout Command** Flutter web app for DJI-ready wildfire mission control.

## Project Structure

```
FireDroneProject/
├── backend/          # Flask REST API
│   ├── app/          # Application package
│   │   └── routes/   # API route blueprints
│   ├── config.py     # Configuration
│   ├── run.py        # Entry point
│   └── requirements.txt
├── flutter_app/      # AeroScout Command Flutter web app
├── mobile/           # Flutter mobile app
│   └── lib/          # Dart source code
└── README.md
```

## Backend (Flask)

### Setup

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

pip install -r requirements.txt
copy .env.example .env
```

### Run

```bash
python run.py
```

The API will be available at `http://127.0.0.1:5000`.

| Endpoint        | Description        |
|-----------------|--------------------|
| `GET /health`   | Health check       |
| `GET /api/status` | API status info  |
| `GET /api/dji/status` | DJI connector status and command gate |
| `GET /api/dji/fleet` | Real DJI aircraft feed, empty until configured |
| `GET /api/dji/telemetry` | Real DJI telemetry state, not-configured until connected |
| `POST /api/dji/ingest/state` | Authenticated real DJI bridge ingest endpoint |
| `POST /api/dji/missions/preview` | Build a guarded mission preview; blocked until DJI connector is configured |
| `POST /api/dji/missions/confirm` | Confirm mission package; blocked unless `ALLOW_DJI_COMMANDS=true` |

DJI integration defaults to `DRONE_CONNECTOR=real` and `ALLOW_DJI_COMMANDS=false`.
Without DJI Cloud API credentials or a future Mobile SDK bridge, the API intentionally returns
`not-configured`, empty fleet data, and no live telemetry instead of fake aircraft.
See `docs/DJI_REAL_INTEGRATION.md` for the real connection contract.

## Mobile (Flutter)

### Setup

```bash
cd mobile
flutter pub get
```

### Run

```bash
flutter run
```

### AeroScout Command Flutter Web

```bash
cd flutter_app
flutter pub get
flutter run
```

The Flutter web app includes a DJI-ready mission-control dashboard for analytics, drone fleet status, scenario planning, guarded mission preview, and live simulator controls. By default it shows real connector status or a clear not-configured state; it does not invent aircraft when no DJI data source is connected.

## Development Notes

- The Flask API has CORS enabled so the Flutter app can call it during development.
- Copy `backend/.env.example` to `backend/.env` and adjust values as needed.
- Point the Flutter app at `http://127.0.0.1:5000` (or your machine's LAN IP for physical devices).
