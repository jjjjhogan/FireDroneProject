# DJI Cloud API — Render demo worker

Run a **always-on patrol demo** on Render without a laptop or MQTT broker. The `firedrone-cloud-relay` background worker posts synthetic Cloud API telemetry directly to `firedrone-api` every 45 seconds.

```text
firedrone-cloud-relay (Render worker)
        │  HTTP POST /api/dji/ingest/cloud-api
        ▼
firedrone-api (Render web)
        ▼
firedrone-command (Flutter static site)
```

For real DJI MQTT, see [DJI_CLOUD_PRODUCTION.md](DJI_CLOUD_PRODUCTION.md).

## One-time Render setup

### 1. `firedrone-api` environment

In Render → **firedrone-api** → **Environment**, set:

```env
DRONE_CONNECTOR=real
DJI_INGEST_TOKEN=<generate-a-long-random-token>
```

Generate a token locally:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Redeploy **firedrone-api** after saving.

### 2. `firedrone-cloud-relay` worker

The blueprint in [`render.yaml`](../render.yaml) adds a **worker** service. After merging this branch:

1. Render Dashboard → **Blueprints** → sync / apply updated `render.yaml`, **or** create the worker manually with the same settings.
2. On **firedrone-cloud-relay**, set:

```env
DJI_INGEST_TOKEN=<same value as firedrone-api>
```

Other defaults (already in blueprint):

```env
DJI_DEMO_INGEST=true
FIRE_DRONE_API_BASE=https://firedrone-api.onrender.com/api
DJI_DEMO_DEVICE_ID=demo-aircraft
DJI_DEMO_INTERVAL_SECONDS=45
```

3. Deploy the worker. Logs should show:

```text
[demo] HTTP patrol ingest -> https://firedrone-api.onrender.com/api ...
[demo] uptime=45s received=1 ok=1 failed=0 ...
```

### 3. Verify

```bash
curl -fsS https://firedrone-api.onrender.com/api/dji/status
curl -fsS https://firedrone-api.onrender.com/api/dji/fleet
```

Expect `connection: bridge-online`, `liveData: true`, aircraft `demo-aircraft`.

Open **https://firedrone-command.onrender.com** → Live Simulator / fleet map.

## Test from your laptop (before Render)

Point at local Flask:

```powershell
cd backend
$env:DJI_INGEST_TOKEN="your-token"
$env:DJI_DEMO_INGEST="true"
python scripts/dji_render_relay_worker.py --once --verbose
```

Point at production API (same token as Render):

```powershell
cd backend
$env:DJI_INGEST_TOKEN="your-render-token"
$env:DJI_DEMO_INGEST="true"
$env:FIRE_DRONE_API_BASE="https://firedrone-api.onrender.com/api"
python scripts/dji_render_relay_worker.py --verbose
```

## Switch to real DJI MQTT later

On **firedrone-cloud-relay**:

```env
DJI_DEMO_INGEST=false
DJI_FORCE_MQTT_RELAY=true
DJI_CLOUD_API_MQTT_HOST=<dji-broker-host>
DJI_CLOUD_MQTT_PORT=8883
DJI_CLOUD_MQTT_USE_TLS=true
DJI_CLOUD_MQTT_USERNAME=<from-dji-portal>
DJI_CLOUD_MQTT_PASSWORD=<from-dji-portal>
```

Start command stays `python scripts/dji_render_relay_worker.py`.

## Local EMQX path (development)

Still use laptop + EMQX for dev without Render worker:

```powershell
docker compose -f backend/docker-compose.emqx.yml up -d
python backend/run.py
python backend/scripts/dji_cloud_mqtt_worker.py
python backend/scripts/mqtt_test_publisher.py
```

## Notes

- Demo telemetry is **synthetic** — not from a real aircraft.
- DJI state on Render is **ephemeral JSON**; the worker must keep posting for `liveData` to stay true.
- Free Render workers may sleep; wake by visiting the site or upgrade for demos.
- Never commit `DJI_INGEST_TOKEN` or DJI MQTT passwords to git.

## Related

- [DJI_CLOUD_PRODUCTION.md](DJI_CLOUD_PRODUCTION.md) — laptop MQTT relay → Render
- [EMQX_SETUP.md](EMQX_SETUP.md) — local MQTT only
