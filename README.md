# FireDrone Project

https://www.tinyurl.com/xavstev

A fire drone monitoring system with a **Flask** backend API, the original **Flutter** mobile app, and a new **AeroScout Sim** Flutter web prototype based on the project design slides.

## Project Structure

```
FireDroneProject/
├── backend/          # Flask REST API
│   ├── app/          # Application package
│   │   └── routes/   # API route blueprints
│   ├── config.py     # Configuration
│   ├── run.py        # Entry point
│   └── requirements.txt
├── flutter_app/      # AeroScout Sim Flutter web prototype
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

### AeroScout Sim Flutter Web Prototype

```bash
cd flutter_app
flutter pub get
flutter run
```

The new Flutter prototype includes dashboards for analytics, drone fleet status, scenario planning, and a live simulator view. Scenario and hero decorations use generated wildfire patrol landscape images in `flutter_app/assets/images/`.

## Development Notes

- The Flask API has CORS enabled so the Flutter app can call it during development.
- Copy `backend/.env.example` to `backend/.env` and adjust values as needed.
- Point the Flutter app at `http://127.0.0.1:5000` (or your machine's LAN IP for physical devices).
