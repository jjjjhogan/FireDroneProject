# GitHub Integration Review

Inspection date: 2026-06-12
Branch inspected: `codex/dji-mission-control-redesign`

This document explains how external GitHub projects influenced AeroScout Command. These projects informed architecture, data modeling, and UX patterns only. Their source code was not copied into this Flutter app, and none of them justify enabling real aircraft commands in the current prototype.

## Current App Direction

AeroScout Command is a Flutter web prototype for official-facing wildfire drone operations review. The app is simulation-first and not production-ready. It now includes:

- Official dashboard summary cards
- Mission overview
- Drone telemetry panel
- Operations map placeholder
- Fire/smoke alert review
- Scenario Library with search, filters, selected scenario detail, and simulator actions
- Safety-gated simulated command panel
- Audit log
- About & Safety screen
- DJI connector status through the existing backend adapter boundary

Real hardware command dispatch remains disabled. UI controls are simulated and must go through `SafetyGateService`.

## Influence Summary

| Reference | Influence on this Flutter app | Safety interpretation |
|---|---|---|
| `altnautica/ADOSMissionControl` | Command-center information architecture, fleet telemetry grouping, mission planner structure, safety/failsafe panel separation, and adapter boundaries | Reference only. The Flutter app does not become a full ground control station and does not copy GPL-risk code. |
| `AlimTleuliyev/wildfire-detection` | Fire/smoke detection classes, confidence display, image/frame context, and human review language | Model detections are decision-support only. Alerts start unconfirmed and require operator review. |
| `khangle2101/Real-Time-Fire-Smoke-Detection-Drone` | Future edge inference, geotagged alerts, camera/telemetry fusion, and alert delivery concepts | No autonomous response or direct flight behavior was adopted. Future ingest should remain review-first. |
| PX4 and PX4 simulation docs | SITL-first validation, simulated multi-vehicle telemetry, health/failsafe concepts | PX4 SITL is a future simulation source, not a hardware command path. |
| MAVSDK, MAVSDK-Python, MAVLink, ArduPilot concepts | Read-only telemetry adapter planning, connection model, battery/GPS/health normalization | Backend adapter only. No direct Flutter MAVLink control and no mission upload/arm/takeoff commands in this MVP. |

## ADOSMissionControl Mapping

ADOSMissionControl showed the value of a serious command-center layout:

- Persistent navigation
- Fleet and telemetry grouping
- Mission planning workspace
- Alert feed
- Safety/failsafe surfaces
- Adapter separation between UI and vehicle protocols

AeroScout Command adapts those ideas into Flutter panels:

- `OfficialDashboardScreen`
- `Mission Overview`
- `Drone Telemetry`
- `Operations Map`
- `Safety-Gated Commands`
- `Audit Log`

The adaptation is intentionally smaller and safer. It does not expose joystick control, gamepad control, direct MAVLink writes, mission upload, or unrestricted aircraft commands.

## wildfire-detection Mapping

The wildfire-detection project influenced the fire/smoke alert model:

- Detection type
- Confidence
- Severity
- Frame or image placeholder
- Human review state
- False-positive feedback

In AeroScout Command, simulated alerts start as `Unconfirmed`. Operators can:

- Confirm
- Mark False Positive
- Resolve

Every alert action creates an audit entry. The UI does not treat model output as official fire confirmation.

## Real-Time-Fire-Smoke-Detection-Drone Mapping

The real-time drone detection project influenced future backend architecture:

```text
Drone or edge device
  -> vision detection worker
  -> backend alert ingest API
  -> Flutter alert review queue
  -> audit log
```

The current implementation does not copy its code and does not adopt autonomous flight behavior. Any future camera or YOLO integration should post detection events for operator review rather than directly commanding aircraft.

## PX4, MAVSDK, MAVLink, And ArduPilot Mapping

PX4 SITL, MAVSDK, MAVLink, and ArduPilot concepts influence the future telemetry adapter plan:

```text
PX4 SITL or ArduPilot simulation
  -> MAVSDK/MAVLink read-only adapter
  -> backend normalized telemetry
  -> Flutter dashboard
```

Potential normalized fields:

- Aircraft identity
- Position
- Altitude
- Battery
- GPS status
- Heading
- Speed
- Flight mode
- Health
- Link status

The first integration should be read-only and simulation-first. Any future command pathway needs separate authorization, role-based access control, geofence checks, airspace review, Remote ID review, physical fallback, and persistent audit logging.

## DJI Adapter Boundary

The current backend already includes DJI Cloud API and Mobile SDK bridge direction:

- `GET /api/dji/status`
- `GET /api/dji/fleet`
- `GET /api/dji/telemetry`
- `POST /api/dji/missions/preview`
- `POST /api/dji/missions/confirm`
- `POST /api/dji/ingest/state`
- `POST /api/dji/ingest/cloud-api`
- `POST /api/dji/ingest/mobile-sdk`

The Flutter app consumes normalized data through `DroneApiClient`. When no connector is configured, it shows not-configured or no-live-feed states rather than inventing real aircraft.

## Current Implementation Choices

Implemented now:

- Simulation fixtures for drone telemetry, mission data, fire/smoke alerts, and scenarios
- Explicit models for telemetry, mission, scenario, command, safety status, and audit log
- Mock services for dashboard state
- Safety gate service for simulated commands
- Operator-visible alert review workflow
- Scenario Library selected scenario panel
- About & Safety screen with references and future roadmap
- SQLite persistence for backend alert and audit APIs
- Bearer-token RBAC for viewer/operator/admin/ingest prototype roles
- Map provider configuration endpoint
- PX4 SITL and MAVLink read-only telemetry ingest endpoints
- YOLO/thermal alert ingest endpoint
- Persistent safety checklist endpoint for geofence, Remote ID, airspace approval, and emergency stop simulation state

Still mocked or placeholder:

- Operations map geometry
- Validated production fire/smoke detection model
- Geofence validation
- Remote ID hardware proof
- Airspace approval authority integration
- Emergency stop hardware behavior
- Production map/geofence layer validation
- Production identity provider and token lifecycle

## License And Copying Notes

The external GitHub projects are references. Avoid copying source code, assets, UI implementations, or license-sensitive logic. In particular:

- Do not copy GPL-risk ground-control code into this repository.
- Do not copy no-license code.
- Do not move this Flutter app to React, Next.js, Streamlit, or a full GCS stack for this MVP.
- Do not import heavy flight-control dependencies into Flutter.

## Verification Target

Task 3 should be considered complete only when:

- Flutter UI labels clearly show simulation and hardware-disabled states.
- Scenario Library has live search/filter and selected scenario actions.
- Alert review and command attempts create audit entries.
- About & Safety exists in navigation.
- README, safety, future integration, and this review document are updated.
- `flutter analyze` passes.
- `flutter test` passes.

## References

- ADOSMissionControl: https://github.com/altnautica/ADOSMissionControl
- wildfire-detection: https://github.com/AlimTleuliyev/wildfire-detection
- Real-Time-Fire-Smoke-Detection-Drone: https://github.com/khangle2101/Real-Time-Fire-Smoke-Detection-Drone
- PX4 Autopilot: https://github.com/PX4/PX4-Autopilot
- PX4 simulation docs: https://docs.px4.io/main/en/simulation/
- MAVSDK: https://dronecode.org/sdk/
- MAVSDK-Python: https://github.com/mavlink/MAVSDK-Python
- MAVLink Developer Guide: https://mavlink.io/en/
