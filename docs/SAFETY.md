# Safety Policy

AeroScout Command is a simulation-first wildfire drone operations prototype. It is not production-ready, not certified emergency-response software, and not a replacement for trained pilots, agency procedures, incident command, or aviation compliance.

## Core Safety Rules

- Simulation mode remains the default.
- Real hardware commands remain disabled by default.
- `ALLOW_DJI_COMMANDS=false` is the backend default.
- Command buttons in Flutter create simulated command attempts only.
- The UI must clearly display `Simulation Mode` and `Real Hardware Disabled`.
- No UI path may bypass `SafetyGateService`.
- No mission action may claim that real aircraft were armed, launched, repositioned, or recovered.
- Fire/smoke detections are decision-support signals, not official fire confirmations.

## Command Flow

Every command must follow this flow:

```text
Operator confirmation
  -> CommandRequest
  -> SafetyGateService
  -> CommandResult
  -> AuditLogEntry
  -> UI status update
```

Required command behavior:

- Arm, Takeoff, Land, RTL, Start, Pause, and Stop require operator confirmation.
- Emergency Stop is available as a local simulation lock.
- A blocked command must return a `CommandResult` with a reason.
- An accepted simulated command must clearly state that no hardware command was sent.
- Every command attempt must create an audit entry.

## Human Confirmation

Human confirmation is required because a real wildfire drone operation can affect aircraft, ground crews, public safety, property, and restricted airspace. The current app does not authorize or execute real flight, but the prototype still models a conservative confirmation habit.

## Audit Logging

The backend audit log is persisted in SQLite when `APP_DATABASE_FILE` is configured or defaults to `backend/instance/operations.sqlite3`. The Flutter app can fall back to local in-memory audit entries when the backend is offline. The audit trail records:

- Alert review actions
- Simulated command attempts
- Emergency stop simulation state changes
- Operator safety checklist updates

Future versions should harden audit records with tamper-resistant storage, operator identity, timestamps, request payload hashes, review notes, and incident identifiers.

## Alert Review

Alerts start as `Unconfirmed`.

Only an operator review can:

- Confirm an alert
- Mark an alert False Positive
- Resolve an alert

Every review action must create an audit entry. Model confidence and severity are decision-support values only.

## Safety Checklist

The backend exposes `/api/safety/checklist` for operator-visible geofence, Remote ID, airspace approval, and emergency stop status. These records are persisted and audited so a team can see what has been reviewed during a prototype session.

Checklist state is not automatic compliance. Before any hardware pathway is considered, geofence checks must be connected to verified mission geometry, local restrictions, incident boundaries, temporary flight restrictions, launch site constraints, and aircraft-specific limits. Remote ID and airspace approval must be backed by real aircraft, pilot, and authority records.

## Emergency Stop Boundary

The current Emergency Stop changes local and backend simulation state only. It is not a physical aircraft kill switch, not an SDK-level stop command, and not a guarantee of aircraft recovery.

Future hardware programs need aircraft-specific emergency procedures, controller fallback, pilot-in-command authority, return-to-home behavior review, and physical field testing.

## Authorized Use Only

Do not use this app for unauthorized drone operations. Do not fly near wildfire response operations without explicit authorization. Wildfire airspace may include temporary flight restrictions, crewed firefighting aircraft, evacuation operations, and ground crews.

Unauthorized drone flights around wildfire incidents can endanger people and aircraft and may violate law.

## Future Hardware Requirements

Before any real command channel is enabled, the project needs:

- Written agency authorization and operating procedures
- Licensed and trained operators where required
- Pilot-in-command responsibility and manual override plan
- Airspace and temporary flight restriction checks
- Remote ID and local regulatory compliance
- Aircraft model qualification and firmware review
- DJI Cloud API or Mobile SDK security review
- Geofence validation
- Role-based access control
- Multi-party approval for mission command dispatch
- Persistent audit logging
- Auth/RBAC deployment using non-demo tokens
- Secure secret storage and deployment hardening
- Incident command workflow integration
- Field tests in controlled, non-emergency environments

## Explicitly Out Of Scope

- Autonomous real-world wildfire flight
- Unrestricted remote control
- Bypassing geofences or airspace rules
- Treating AI detections as official fire confirmation
- Operating drones in wildfire areas without authorization
- Claiming production readiness
