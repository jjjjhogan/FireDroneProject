# Local EMQX (Docker)

Use this for DJI Cloud API MQTT development before Pilot 2 or Dock are on the network.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running on Windows

## Start EMQX

```bash
cd backend
docker compose -f docker-compose.emqx.yml up -d
```

Check status:

```bash
docker compose -f docker-compose.emqx.yml ps
docker logs firedrone-emqx --tail 20
```

## Endpoints

| Service | URL / port |
|---------|------------|
| MQTT (plain) | `127.0.0.1:1883` |
| MQTT (TLS) | `127.0.0.1:8883` |
| Dashboard | http://localhost:18083 (default login often `admin` / `public` on first boot) |

The compose file sets `EMQX_ALLOW_ANONYMOUS=true` for local dev only. Do not expose this broker to the public internet.

## Backend `.env` (local Docker)

Match these values in `backend/.env` when testing the Cloud MQTT bridge:

```env
DRONE_CONNECTOR=real
DJI_CLOUD_API_MQTT_HOST=127.0.0.1
DJI_CLOUD_MQTT_PORT=1883
DJI_CLOUD_MQTT_USE_TLS=false
DJI_INGEST_TOKEN=<your-secret-ingest-token>
```

Generate a token:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Production / TLS brokers use `DJI_CLOUD_MQTT_PORT=8883` and `DJI_CLOUD_MQTT_USE_TLS=true`.

## Verify MQTT publish (optional)

With the broker running:

```bash
python -m pip install paho-mqtt
python -c "
import json, time
import paho.mqtt.client as mqtt
c = mqtt.Client()
c.connect('127.0.0.1', 1883, 60)
c.loop_start()
payload = {'data': {'latitude': 37.21, 'longitude': -119.54, 'height': 120, 'battery': {'capacity_percent': 82}}}
c.publish('thing/product/demo-aircraft/osd', json.dumps(payload))
time.sleep(1)
c.loop_stop()
print('published test OSD message')
"
```

## Start the in-app Cloud MQTT bridge

1. Run Flask: `python run.py`
2. POST connection config (or use the Flutter **Connect DJI** dialog):

```bash
curl -X POST http://127.0.0.1:5000/api/dji/connection \
  -H "Content-Type: application/json" \
  -d "{\"mode\":\"cloud-api\",\"ingestToken\":\"YOUR_TOKEN\",\"cloudMqttHost\":\"127.0.0.1\",\"cloudMqttPort\":1883,\"autoStartCloudBridge\":true}"
```

Check bridge status:

```bash
curl http://127.0.0.1:5000/api/dji/connection
```

## Alternative: standalone worker script

```bash
python scripts/dji_cloud_mqtt_worker.py --no-tls --mqtt-host 127.0.0.1 --mqtt-port 1883 --token YOUR_TOKEN
```

## Stop EMQX

```bash
docker compose -f docker-compose.emqx.yml down
```

To remove data volume as well:

```bash
docker compose -f docker-compose.emqx.yml down -v
```

## Field / controller access

When DJI Pilot 2 or hardware must connect from another device, replace `127.0.0.1` with your PC **LAN IP** (for example `192.168.1.50`) and ensure Docker published ports are reachable on that interface.
