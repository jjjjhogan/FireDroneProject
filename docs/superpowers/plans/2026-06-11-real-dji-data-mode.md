# Real DJI Data Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the DJI mission control branch from a simulated prototype into a truthful production-ready website that shows only real DJI connector data, or clearly shows that real DJI data is not configured.

**Architecture:** Backend defaults to a real-data-safe connector instead of mock data. The connector returns an explicit `not-configured` state and empty fleet unless DJI Cloud API or Mobile SDK bridge input has been configured. Flutter consumes those states directly and removes mock fallbacks from production screens.

**Tech Stack:** Flask, Python unittest, Flutter web, OpenStreetMap raster tiles, DJI Cloud API / Mobile SDK integration boundaries.

---

### Task 1: Backend Truthful Connector Tests

**Files:**
- Modify: `backend/tests/test_dji_api.py`
- Modify: `backend/app/dji/connectors.py`
- Modify: `backend/config.py`

- [ ] **Step 1: Write failing tests for real-data-safe defaults**

Add tests proving that default production behavior does not return fake drones:

```python
class RealDataDefaultConfig:
    TESTING = True
    SECRET_KEY = "test"
    DRONE_CONNECTOR = "real"
    ALLOW_DJI_COMMANDS = False


class DjiRealDataModeTest(unittest.TestCase):
    def setUp(self):
        self.app = create_app(RealDataDefaultConfig)
        self.client = self.app.test_client()

    def test_real_mode_reports_not_configured_without_fake_fleet(self):
        status_response = self.client.get("/api/dji/status")
        fleet_response = self.client.get("/api/dji/fleet")
        telemetry_response = self.client.get("/api/dji/telemetry")

        self.assertEqual(status_response.status_code, 200)
        status = status_response.get_json()
        self.assertEqual(status["connector"], "real")
        self.assertEqual(status["connection"], "not-configured")
        self.assertFalse(status["commandEnabled"])
        self.assertFalse(status["liveData"])
        self.assertIn("missingConfiguration", status)

        self.assertEqual(fleet_response.status_code, 200)
        self.assertEqual(fleet_response.get_json()["drones"], [])

        self.assertEqual(telemetry_response.status_code, 200)
        telemetry = telemetry_response.get_json()
        self.assertEqual(telemetry["missionState"], "not-configured")
        self.assertEqual(telemetry["linkHealth"], "not-configured")

    def test_real_mode_blocks_mission_preview_without_connector(self):
        response = self.client.post(
            "/api/dji/missions/preview",
            json={"scenarioId": "canyon-ridge", "routePoints": []},
        )

        self.assertEqual(response.status_code, 409)
        data = response.get_json()
        self.assertFalse(data["available"])
        self.assertEqual(data["riskLevel"], "unknown")
        self.assertIn("DJI connector is not configured", data["warnings"][0])
```

- [ ] **Step 2: Run tests to verify RED**

Run:

```bash
backend/.venv/bin/python -m unittest backend.tests.test_dji_api.DjiRealDataModeTest
```

Expected: FAIL because `real` connector falls back to `MockDjiConnector` and returns simulated drones.

- [ ] **Step 3: Implement `RealDjiConnector`**

Add a connector class that never invents devices:

```python
class RealDjiConnector(BaseDjiConnector):
    connector_name = "real"

    def __init__(self, allow_commands=False, config=None):
        super().__init__(allow_commands=allow_commands)
        self.config = config or {}

    def missing_configuration(self):
        required = [
            "DJI_CLOUD_API_APP_ID",
            "DJI_CLOUD_API_APP_KEY",
            "DJI_CLOUD_API_APP_LICENSE",
            "DJI_CLOUD_API_MQTT_HOST",
            "DJI_WORKSPACE_ID",
        ]
        return [key for key in required if not self.config.get(key)]

    def configured(self):
        return not self.missing_configuration()

    def status(self):
        missing = self.missing_configuration()
        return {
            "provider": "DJI",
            "connector": self.connector_name,
            "connection": "configured" if not missing else "not-configured",
            "commandEnabled": self.allow_commands and not missing,
            "liveData": False,
            "missingConfiguration": missing,
            "reservedAdapters": ["DJI Cloud API", "DJI Mobile SDK Bridge"],
            "lastSync": _utc_now(),
        }

    def fleet(self):
        return {"drones": []}

    def telemetry(self):
        return {
            "activeDroneId": None,
            "missionState": "not-configured",
            "routeProgressPct": 0,
            "windMph": None,
            "temperatureF": None,
            "firePerimeterRisk": "unknown",
            "linkHealth": "not-configured",
        }

    def preview_mission(self, payload):
        return (
            {
                "available": False,
                "scenarioId": payload.get("scenarioId", "unknown"),
                "routePoints": payload.get("routePoints") or [],
                "estimatedDurationMin": 0,
                "maxAltitudeM": 0,
                "riskLevel": "unknown",
                "warnings": [
                    "DJI connector is not configured; mission package was not sent to an aircraft."
                ],
                "requiresConfirmation": True,
            },
            409,
        )
```

Update `create_dji_connector(config)` to return `RealDjiConnector` for `real`, `production`, `dji`, or an unknown non-mock value. Keep `mock` available only when explicitly selected.

- [ ] **Step 4: Run tests to verify GREEN**

Run:

```bash
backend/.venv/bin/python -m unittest backend.tests.test_dji_api
```

Expected: PASS.

### Task 2: Flask Route Support For Tuple Preview Responses

**Files:**
- Modify: `backend/app/routes/api.py`
- Test: `backend/tests/test_dji_api.py`

- [ ] **Step 1: Write route expectation test**

The Task 1 preview test expects HTTP 409. If Flask route currently returns the tuple as JSON incorrectly, keep the test and use it as the route regression.

- [ ] **Step 2: Implement route tuple handling**

Change `dji_mission_preview`:

```python
@api_bp.route("/dji/missions/preview", methods=["POST"])
def dji_mission_preview():
    payload = request.get_json(silent=True) or {}
    result = _dji_connector().preview_mission(payload)
    if isinstance(result, tuple):
        return result
    return result
```

- [ ] **Step 3: Run backend tests**

Run:

```bash
backend/.venv/bin/python -m unittest discover -s backend/tests
```

Expected: PASS.

### Task 3: Flutter Models Accept Real Unavailable Values

**Files:**
- Modify: `flutter_app/lib/models/drone_connection.dart`
- Modify: `flutter_app/lib/services/drone_api_client.dart`
- Test: `flutter_app/test/widget_test.dart`

- [ ] **Step 1: Add model coverage through widget expectations**

Update widget tests so the default app no longer expects fake drones and instead expects:

```dart
expect(find.text('DJI connector not configured'), findsWidgets);
expect(find.text('0 / 0 Online'), findsOneWidget);
expect(find.text('No real DJI aircraft connected'), findsWidgets);
expect(find.text('Command gate locked'), findsWidgets);
```

- [ ] **Step 2: Run widget test to verify RED**

Run:

```bash
/Users/xavier/development/flutter/bin/flutter test
```

Expected: FAIL because the Flutter mock client and UI still produce fake fleet rows.

- [ ] **Step 3: Extend models**

Add fields to `DjiStatus`:

```dart
required this.liveData,
required this.missingConfiguration,
```

Parse:

```dart
liveData: json['liveData'] as bool? ?? false,
missingConfiguration:
    (json['missingConfiguration'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(),
```

Add `available` to `MissionPreview`:

```dart
available: json['available'] as bool? ?? true,
```

Keep numeric telemetry parsing safe when backend sends `null`.

- [ ] **Step 4: Replace Flutter mock client defaults with truthful unavailable data**

Change `MockDroneApiClient` so local tests and offline preview do not invent drones:

```dart
Future<DjiStatus> fetchStatus() async {
  return const DjiStatus(
    provider: 'DJI',
    connector: 'real',
    connection: 'not-configured',
    commandEnabled: false,
    liveData: false,
    missingConfiguration: [
      'DJI_CLOUD_API_APP_ID',
      'DJI_CLOUD_API_APP_KEY',
      'DJI_CLOUD_API_APP_LICENSE',
      'DJI_CLOUD_API_MQTT_HOST',
      'DJI_WORKSPACE_ID',
    ],
    reservedAdapters: ['DJI Cloud API', 'DJI Mobile SDK Bridge'],
    lastSync: 'not configured',
  );
}

Future<List<DroneSummary>> fetchFleet() async => const [];
```

Preview should return `available: false`, zero duration/altitude, and warning text matching backend.

- [ ] **Step 5: Run widget tests**

Run:

```bash
/Users/xavier/development/flutter/bin/flutter test
```

Expected: PASS.

### Task 4: UI Truthful Empty States

**Files:**
- Modify: `flutter_app/lib/screens/live_simulator_screen.dart`
- Modify: `flutter_app/lib/screens/fleet_page.dart`
- Modify: `flutter_app/lib/screens/scenario_library_screen.dart`

- [ ] **Step 1: Write failing UI expectations**

Add widget assertions that `ConnectedDronesPanel` shows an empty state when `fleet.isEmpty`, and `MissionHeroStatus` labels the connector as not configured.

- [ ] **Step 2: Implement empty state components**

In `ConnectedDronesPanel`, render:

```dart
if (fleet.isEmpty)
  const Padding(
    padding: EdgeInsets.symmetric(vertical: 18),
    child: Text(
      'No real DJI aircraft connected',
      style: TextStyle(color: Color(0xff62716c), fontWeight: FontWeight.w700),
    ),
  )
```

In hero/link status, render:

```dart
status?.connection == 'not-configured'
    ? 'DJI connector not configured'
    : 'DJI Link'
```

In mission action panel, keep start disabled when `preview?.available == false`.

- [ ] **Step 3: Run Flutter analyze and tests**

Run:

```bash
/Users/xavier/development/flutter/bin/flutter analyze
/Users/xavier/development/flutter/bin/flutter test
```

Expected: PASS.

### Task 5: Documentation And Environment Contract

**Files:**
- Modify: `backend/.env.example`
- Modify: `README.md`
- Create: `docs/DJI_REAL_INTEGRATION.md`

- [ ] **Step 1: Document real connection requirements**

Document:

```text
DRONE_CONNECTOR=real
ALLOW_DJI_COMMANDS=false
DJI_CLOUD_API_APP_ID=
DJI_CLOUD_API_APP_KEY=
DJI_CLOUD_API_APP_LICENSE=
DJI_CLOUD_API_MQTT_HOST=
DJI_WORKSPACE_ID=
```

Explain that without these values, the site intentionally shows no aircraft instead of fake data.

- [ ] **Step 2: Document DJI paths**

State the two supported paths:

```text
DJI Cloud API: Pilot 2 or DJI Dock connects to the backend/cloud platform.
DJI Mobile SDK Bridge: future Android/controller bridge forwards real device state to this backend.
```

- [ ] **Step 3: Run docs grep**

Run:

```bash
rg -n "mock|simulated|fake|not-configured|DJI_CLOUD_API" README.md docs backend/.env.example flutter_app/README.md
```

Expected: mock language only appears where explicitly describing development-only mode.

### Task 6: Verification

**Files:**
- All changed files.

- [ ] **Step 1: Run backend tests**

Run:

```bash
backend/.venv/bin/python -m unittest discover -s backend/tests
```

Expected: PASS.

- [ ] **Step 2: Run Flutter checks**

Run:

```bash
cd flutter_app
/Users/xavier/development/flutter/bin/flutter analyze
/Users/xavier/development/flutter/bin/flutter test
/Users/xavier/development/flutter/bin/flutter build web
```

Expected: PASS.

- [ ] **Step 3: Browser QA**

Run local web build and verify in browser:

```bash
cd flutter_app
python3 -m http.server 8139 --bind 127.0.0.1 --directory build/web
```

Open `http://127.0.0.1:8139/` and verify:

```text
DJI connector not configured
0 / 0 Online
No real DJI aircraft connected
Command gate locked
```

---

## Self-Review

Spec coverage: The plan removes fake backend fleet/telemetry defaults, removes Flutter fake fallback data, documents the real DJI integration contract, and keeps command safety locked.

Placeholder scan: No implementation step relies on TBD or unspecified behavior. Each task names exact files, commands, and expected output.

Type consistency: Backend `liveData`, `missingConfiguration`, and `available` fields are matched by Flutter model updates and UI assertions.
