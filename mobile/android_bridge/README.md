# DJI Mobile SDK Bridge

This folder contains a small Android/Kotlin HTTP bridge client for a DJI Mobile
SDK app. It does not send flight commands. It only posts aircraft telemetry that
the mobile app has already read from DJI Mobile SDK callbacks.

Target endpoint:

```text
POST /api/dji/ingest/mobile-sdk
Authorization: Bearer <DJI_INGEST_TOKEN>
```

Expected usage inside a DJI Mobile SDK app:

1. Register and connect the DJI Mobile SDK in the native Android app.
2. Read aircraft, battery, position, flight mode, and link state from SDK
   callbacks.
3. Convert those values to `MobileSdkAircraftSnapshot` and
   `MobileSdkFlightSnapshot`.
4. Call `MobileSdkBridgeClient.postSnapshot(...)` every 1-5 seconds while the
   operator is monitoring.

Keep `ALLOW_DJI_COMMANDS=false` until mission command dispatch is designed,
reviewed, and manually approved.
