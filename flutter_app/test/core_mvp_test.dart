import 'package:flutter_test/flutter_test.dart';

import 'package:fire_drone_app/models/audit_log_entry.dart';
import 'package:fire_drone_app/models/command.dart';
import 'package:fire_drone_app/models/drone_telemetry.dart';
import 'package:fire_drone_app/models/fire_detection_event.dart';
import 'package:fire_drone_app/models/mission.dart';
import 'package:fire_drone_app/models/operations_enums.dart';
import 'package:fire_drone_app/models/scenario.dart';
import 'package:fire_drone_app/models/safety_gate_status.dart';
import 'package:fire_drone_app/services/audit_log_service.dart';
import 'package:fire_drone_app/services/drone_telemetry_service.dart';
import 'package:fire_drone_app/services/fire_detection_service.dart';
import 'package:fire_drone_app/services/mission_service.dart';
import 'package:fire_drone_app/services/scenario_library_service.dart';
import 'package:fire_drone_app/safety/safety_gate_service.dart';

void main() {
  test('core MVP models expose simulation-first operations data', () {
    final timestamp = DateTime.utc(2026, 6, 12, 16, 42);

    final telemetry = DroneTelemetry(
      droneId: 'drone-1',
      lat: 34.62,
      lon: -119.72,
      altitudeMeters: 118,
      speedMps: 9.5,
      headingDeg: 184,
      batteryPercent: 82,
      gpsStatus: '3D fix',
      linkStatus: LinkStatus.simulated,
      missionState: MissionStatus.active,
      timestamp: timestamp,
    );
    expect(telemetry.droneId, 'drone-1');
    expect(telemetry.linkStatus, LinkStatus.simulated);

    final event = FireDetectionEvent(
      eventId: 'evt-1',
      detectionType: DetectionType.smoke,
      confidence: 0.87,
      severity: AlertSeverity.high,
      lat: 34.63,
      lon: -119.73,
      sourceDroneId: telemetry.droneId,
      imagePlaceholder: 'thermal-frame-001',
      timestamp: timestamp,
      status: AlertStatus.unconfirmed,
      reviewer: null,
      reviewTimestamp: null,
      notes: '',
    );
    expect(event.isOpen, isTrue);
    expect(
      event.copyWith(status: AlertStatus.confirmed).status,
      AlertStatus.confirmed,
    );

    final mission = Mission(
      missionId: 'mission-1',
      name: 'Canyon Ridge Fire',
      area: 'Los Padres National Forest, CA',
      assignedDroneId: telemetry.droneId,
      operatorName: 'Simulation Operator',
      status: MissionStatus.active,
      startTime: timestamp,
      lastUpdateTime: timestamp,
      notes: 'Simulation mode only',
    );
    expect(mission.status, MissionStatus.active);

    final scenario = Scenario(
      scenarioId: 'canyon-ridge',
      title: 'Canyon Ridge Fire',
      description: 'Official wildfire operations simulation.',
      region: 'Mountain',
      difficulty: ScenarioDifficulty.advanced,
      simulatedDroneCount: 3,
      simulatedAlertCount: 2,
      tags: const ['wildfire', 'thermal'],
    );
    expect(scenario.name, scenario.title);
    expect(scenario.drones, 3);

    final status = SafetyGateStatus(
      systemMode: SystemMode.simulation,
      hardwareEnabled: false,
      commandLocked: true,
      confirmationRequired: true,
      geofenceStatus: GeofenceStatus.simulatedValid,
      emergencyStopEngaged: false,
      statusMessage: 'Simulation lock active',
    );
    expect(status.realHardwareDisabled, isTrue);

    final request = CommandRequest(
      requestId: 'cmd-1',
      commandType: DroneCommandType.arm,
      requestedBy: 'Simulation Operator',
      targetDroneId: telemetry.droneId,
      timestamp: timestamp,
      confirmationProvided: true,
      notes: 'Panel test',
    );
    expect(request.commandType, DroneCommandType.arm);

    final result = CommandResult.blocked(
      request: request,
      reason: 'Simulation only',
      timestamp: timestamp,
    );
    expect(result.accepted, isFalse);

    final entry = AuditLogEntry(
      entryId: 'audit-1',
      timestamp: timestamp,
      actor: 'Simulation Operator',
      action: 'Reviewed alert',
      targetId: event.eventId,
      details: 'Marked confirmed',
    );
    expect(entry.targetId, 'evt-1');
  });

  test(
    'mock services provide stable simulation data and searchable scenarios',
    () async {
      final telemetry = await MockDroneTelemetryService().fetchTelemetry();
      final detections = await MockFireDetectionService().fetchDetections();
      final mission = await MockMissionService().fetchActiveMission();
      final scenarioService = MockScenarioLibraryService();

      expect(telemetry, isNotEmpty);
      expect(telemetry.first.linkStatus, LinkStatus.simulated);
      expect(detections.where((event) => event.isOpen), isNotEmpty);
      expect(mission.status, MissionStatus.active);

      final mountain = await scenarioService.searchScenarios(
        query: 'ridge',
        region: 'Mountain',
      );
      expect(mountain.length, 1);
      expect(mountain.first.scenarioId, 'canyon-ridge');

      final all = await scenarioService.listScenarios();
      expect(all.length, greaterThanOrEqualTo(4));
    },
  );

  test('audit log records command and alert review activity', () async {
    final audit = InMemoryAuditLogService();
    await audit.record(
      actor: 'Simulation Operator',
      action: 'Confirmed alert',
      targetId: 'evt-1',
      details: 'Confidence reviewed',
    );

    final entries = await audit.entries();
    expect(entries, hasLength(1));
    expect(entries.first.action, 'Confirmed alert');
  });

  test(
    'safety gate blocks real commands and simulates emergency stop',
    () async {
      final service = SafetyGateService();
      final request = CommandRequest(
        requestId: 'cmd-1',
        commandType: DroneCommandType.takeoff,
        requestedBy: 'Simulation Operator',
        targetDroneId: 'drone-1',
        timestamp: DateTime.utc(2026, 6, 12, 16, 45),
        confirmationProvided: false,
        notes: '',
      );

      final blocked = await service.submitCommand(request);
      expect(blocked.accepted, isFalse);
      expect(blocked.blockedReason, contains('confirmation'));
      expect(service.status.realHardwareDisabled, isTrue);

      final emergency = await service.submitCommand(
        request.copyWith(
          commandType: DroneCommandType.emergencyStop,
          confirmationProvided: true,
        ),
      );
      expect(emergency.accepted, isTrue);
      expect(service.status.emergencyStopEngaged, isTrue);
      expect(service.status.commandLocked, isTrue);
    },
  );
}
