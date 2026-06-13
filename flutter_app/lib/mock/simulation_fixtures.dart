import 'package:flutter/material.dart';

import '../models/drone_telemetry.dart';
import '../models/fire_detection_event.dart';
import '../models/mission.dart';
import '../models/operations_enums.dart';
import '../models/scenario.dart';

final simulationBaseTime = DateTime.utc(2026, 6, 12, 16, 42, 18);

final mockDroneTelemetry = [
  DroneTelemetry(
    droneId: 'drone-thermal-1',
    lat: 34.6241,
    lon: -119.7152,
    altitudeMeters: 118,
    speedMps: 9.4,
    headingDeg: 184,
    batteryPercent: 82,
    gpsStatus: '3D fix',
    linkStatus: LinkStatus.simulated,
    missionState: MissionStatus.active,
    timestamp: simulationBaseTime,
  ),
  DroneTelemetry(
    droneId: 'drone-overwatch-2',
    lat: 34.6189,
    lon: -119.7231,
    altitudeMeters: 104,
    speedMps: 7.8,
    headingDeg: 221,
    batteryPercent: 76,
    gpsStatus: '3D fix',
    linkStatus: LinkStatus.simulated,
    missionState: MissionStatus.active,
    timestamp: simulationBaseTime.subtract(const Duration(seconds: 12)),
  ),
  DroneTelemetry(
    droneId: 'drone-relay-3',
    lat: 34.6116,
    lon: -119.7314,
    altitudeMeters: 96,
    speedMps: 4.2,
    headingDeg: 94,
    batteryPercent: 69,
    gpsStatus: 'RTK float',
    linkStatus: LinkStatus.simulated,
    missionState: MissionStatus.paused,
    timestamp: simulationBaseTime.subtract(const Duration(seconds: 28)),
  ),
];

final mockFireDetectionEvents = [
  FireDetectionEvent(
    eventId: 'alert-smoke-1',
    detectionType: DetectionType.smoke,
    confidence: 0.87,
    severity: AlertSeverity.high,
    lat: 34.6234,
    lon: -119.7196,
    sourceDroneId: 'drone-thermal-1',
    imagePlaceholder: 'Thermal frame A-17',
    timestamp: simulationBaseTime.subtract(const Duration(minutes: 2)),
    status: AlertStatus.unconfirmed,
    reviewer: null,
    reviewTimestamp: null,
    notes: 'Smoke column near ridge saddle.',
  ),
  FireDetectionEvent(
    eventId: 'alert-fire-2',
    detectionType: DetectionType.fire,
    confidence: 0.79,
    severity: AlertSeverity.critical,
    lat: 34.626,
    lon: -119.7129,
    sourceDroneId: 'drone-overwatch-2',
    imagePlaceholder: 'Visible frame B-04',
    timestamp: simulationBaseTime.subtract(const Duration(minutes: 5)),
    status: AlertStatus.unconfirmed,
    reviewer: null,
    reviewTimestamp: null,
    notes: 'Possible flame signature inside existing perimeter.',
  ),
  FireDetectionEvent(
    eventId: 'alert-smoke-3',
    detectionType: DetectionType.smoke,
    confidence: 0.62,
    severity: AlertSeverity.medium,
    lat: 34.6179,
    lon: -119.7299,
    sourceDroneId: 'drone-relay-3',
    imagePlaceholder: 'Thermal frame C-21',
    timestamp: simulationBaseTime.subtract(const Duration(minutes: 9)),
    status: AlertStatus.resolved,
    reviewer: 'Simulation Operator',
    reviewTimestamp: simulationBaseTime.subtract(const Duration(minutes: 6)),
    notes: 'Resolved as drift from confirmed perimeter.',
  ),
];

final mockMission = Mission(
  missionId: 'mission-canyon-ridge',
  name: 'Canyon Ridge Fire',
  area: 'Los Padres National Forest, CA',
  assignedDroneId: 'drone-thermal-1',
  operatorName: 'Simulation Operator',
  status: MissionStatus.active,
  startTime: simulationBaseTime.subtract(const Duration(minutes: 28)),
  lastUpdateTime: simulationBaseTime,
  notes:
      'Simulation-only incident command workflow. Hardware commands disabled.',
);

const mockScenarios = [
  Scenario(
    scenarioId: 'canyon-ridge',
    title: 'San Bernardino Mountain Ridge',
    region: 'Mountain',
    description:
        'Steep ridgeline scan with smoke-obscured valleys, utility corridors, and mutual-aid staging zones.',
    difficulty: ScenarioDifficulty.advanced,
    simulatedDroneCount: 6,
    simulatedAlertCount: 2,
    tags: ['thermal', 'ridge', 'mutual aid'],
    color: Color(0xff315241),
    seed: 4,
    image: 'assets/images/scenario-mountain.jpg',
  ),
  Scenario(
    scenarioId: 'santa-cruz-fog',
    title: 'Santa Cruz Fog Belt',
    region: 'Coastal',
    description:
        'Low ceiling patrol that balances thermal locks against shifting marine fog.',
    difficulty: ScenarioDifficulty.intermediate,
    simulatedDroneCount: 5,
    simulatedAlertCount: 3,
    tags: ['fog', 'coastal', 'visibility'],
    color: Color(0xff2f7d9a),
    seed: 8,
    image: 'assets/images/scenario-coastal.jpg',
  ),
  Scenario(
    scenarioId: 'yukon-boreal',
    title: 'Yukon Boreal Line',
    region: 'Boreal',
    description:
        'Long-range perimeter sweep through dense conifer canopy and cold uplifts.',
    difficulty: ScenarioDifficulty.advanced,
    simulatedDroneCount: 8,
    simulatedAlertCount: 4,
    tags: ['boreal', 'canopy', 'relay'],
    color: Color(0xff0e7656),
    seed: 12,
    image: 'assets/images/scenario-boreal.jpg',
  ),
  Scenario(
    scenarioId: 'colorado-plateau',
    title: 'Colorado Plateau Watch',
    region: 'Plateau',
    description:
        'Mesa-to-canyon mapping with relay handoffs and strong afternoon winds.',
    difficulty: ScenarioDifficulty.extreme,
    simulatedDroneCount: 7,
    simulatedAlertCount: 3,
    tags: ['wind', 'plateau', 'relay'],
    color: Color(0xffc2542d),
    seed: 16,
    image: 'assets/images/scenario-plateau.jpg',
  ),
];
