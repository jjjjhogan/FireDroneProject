# DJI Cloud API Production Relay

Use this guide when **DJI Cloud API MQTT credentials live on a field laptop** (or small always-on worker) and the **FireDrone API runs on Render**.

Render hosts the Flask HTTP API and Flutter static site. It does **not** keep a reliable long-lived MQTT subscription on the free tier. The production pattern is:

```text
DJI Cloud MQTT broker (hosted by DJI)
        │
        │ subscribe: thing/product/+/osd, thing/product/+/state
        ▼
Laptop / VM: dji_cloud_mqtt_worker.py
        │
        │ POST /api/dji/ingest/cloud-api
        │ Authorization: Bearer <DJI_INGEST_TOKEN>
        ▼
https://firedrone-api.onrender.com/api
        │
        ▼
https://firedrone-command.onrender.com  (Flutter ops UI)
```

You do **not** run your own MQTT broker for real DJI Cloud API traffic. Local [EMQX](EMQX_SETUP.md) is dev-only.

## Prerequisites

- DJI developer Cloud API credentials in `backend/.env` (never commit this file)
- Matching `DJI_INGEST_TOKEN` on the worker **and** on Render
- `DRONE_CONNECTOR=real` on Render (or local Flask when testing locally first)

Required `.env` keys for the worker:

```env
DJI_CLOUD_API_MQTT_HOST=
DJI_CLOUD_MQTT_PORT=8883
DJI_CLOUD_MQTT_USE_TLS=true
DJI_CLOUD_MQTT_USERNAME=
DJI_CLOUD_MQTT_PASSWORD=
DJI_CLOUD_MQTT_CLIENT_ID=firedrone-cloud-worker
DJI_INGEST_TOKEN=
FIRE_DRONE_API_BASE=http://127.0.0.1:5000/api
```

Optional:

```env
DJI_CLOUD_MQTT_TOPICS=thing/product/+/osd,thing/product/+/state
```

Official DJI references:

- https://developer.dji.com/cloud-api
- https://developer.dji.com/doc/cloud-api-tutorial/en/

## Step 1 — Local proof (recommended first)

Terminal 1 — Flask with the same ingest token as your `.env`:

```bash
cd backend
python run.py
```

Terminal 2 — worker using `.env` defaults (loads `backend/.env` automatically):

```bash
cd backend
python scripts/dji_cloud_mqtt_worker.py
```

You should see:

```text
[relay] connected to <mqtt-host>:8883 topics=...
[relay] uptime=30s received=... ok=... failed=0 ...
```

Verify in another terminal:

```bash
curl http://127.0.0.1:5000/api/dji/status
curl http://127.0.0.1:5000/api/dji/fleet
curl http://127.0.0.1:5000/api/dji/telemetry
```

Expect `connection: bridge-online`, `liveData: true`, and aircraft in fleet when DJI is publishing.

Flutter local (points at `http://127.0.0.1:5000/api` by default):

```bash
cd flutter_app
flutter run -d chrome
```

Open **Live Simulator** and confirm fleet/telemetry update while the worker runs.

## Step 2 — Forward to Render production

1. In Render → **firedrone-api** → **Environment**, add:

```env
DJI_INGEST_TOKEN=<same token as your laptop .env>
DRONE_CONNECTOR=real
```

Redeploy if you changed env vars.

2. On your laptop, point the worker at production:

```bash
cd backend
python scripts/dji_cloud_mqtt_worker.py ^
  --api-base https://firedrone-api.onrender.com/api ^
  --token YOUR_INGEST_TOKEN
```

On macOS/Linux, use `\` instead of `^` for line continuation.

Other `.env` MQTT values are still read from `backend/.env`. Only override API base and token on the command line if needed.

3. Open the production Flutter site:

```text
https://firedrone-command.onrender.com
```

Fleet and telemetry update **while the laptop worker is running**. Stop the worker and data goes stale after `DJI_TELEMETRY_TTL_SECONDS` (default 300s).

## Worker options

```bash
python scripts/dji_cloud_mqtt_worker.py --help
```

| Flag | Purpose |
|------|---------|
| `--verbose` | Log every MQTT → HTTP forward |
| `--log-interval 30` | Summary line every N seconds (default 30) |
| `--no-tls` | Local EMQX only — not for real DJI cloud |
| `--topic thing/product/+/osd` | Repeat to override subscriptions |
| `--env-file path` | Alternate env file |

The worker:

- loads `backend/.env` when present
- auto-reconnects to MQTT with backoff
- keeps running when a single HTTP ingest fails
- logs HTTP 401/400 responses without crashing

## In-process bridge vs standalone worker

| Mode | When to use |
|------|-------------|
| **In-process** (`cloud_bridge.py` inside Flask) | Local dev when Flask stays up on your machine |
| **Standalone worker** (`scripts/dji_cloud_mqtt_worker.py`) | **Production relay** laptop → Render |

Do not rely on Render to run the in-process MQTT bridge for demos. Use the standalone worker.

## Troubleshooting

| Symptom | Check |
|---------|--------|
| `DJI_CLOUD_API_MQTT_HOST ... required` | `.env` missing or not loaded; pass `--mqtt-host` |
| `ConnectionRefusedError` / `connect failed rc=...` | Nothing listening on `mqtt_host:port`. For local dev start EMQX (`docker compose -f docker-compose.emqx.yml up -d`). For real DJI use portal host, port `8883`, and `DJI_CLOUD_MQTT_USE_TLS=true`. |
| HTTP 401 on ingest | `DJI_INGEST_TOKEN` mismatch between worker and Render |
| HTTP 400 on ingest | Payload shape rejected — capture topic JSON and extend `cloud_api.py` mapping |
| `bridge-online` locally but not on Render | Worker not running, wrong `--api-base`, or token mismatch |
| Render shows data then loses it | Expected: DJI state is JSON on Render disk (ephemeral). Worker must repost after redeploy |

Connection states (`GET /api/dji/connection`):

- `not-configured` — no ingest token
- `waiting-for-bridge` — token set, no fresh ingest yet
- `bridge-online` — fresh ingest received
- `bridge-stale` — last ingest older than TTL

## Safety

- `ALLOW_DJI_COMMANDS=false` — telemetry only
- Do not commit `.env`, ingest tokens, or DJI app secrets
- Rotate `DJI_INGEST_TOKEN` if shared outside the team

## Related docs

- [DJI_REAL_INTEGRATION.md](DJI_REAL_INTEGRATION.md) — full connector contract
- [EMQX_SETUP.md](EMQX_SETUP.md) — local fake MQTT only
