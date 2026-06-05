# FireDrone Project

A fire drone monitoring system with a **Flask** backend API and a **Flutter** mobile app.

## Project Structure

```
FireDroneProject/
├── backend/          # Flask REST API
│   ├── app/          # Application package
│   │   └── routes/   # API route blueprints
│   ├── config.py     # Configuration
│   ├── run.py        # Entry point
│   └── requirements.txt
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

## Development Notes

- The Flask API has CORS enabled so the Flutter app can call it during development.
- Copy `backend/.env.example` to `backend/.env` and adjust values as needed.
- Point the Flutter app at `http://127.0.0.1:5000` (or your machine's LAN IP for physical devices).
