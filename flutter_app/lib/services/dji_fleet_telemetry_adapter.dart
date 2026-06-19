import '../models/drone_connection.dart';
import '../models/drone_telemetry.dart';
import '../models/operations_enums.dart';

List<DroneTelemetry> droneTelemetryFromDjiFleet({
  required List<DroneSummary> fleet,
  required TelemetrySnapshot telemetry,
}) {
  if (fleet.isEmpty) {
    return const [];
  }

  return fleet
      .map(
        (drone) => DroneTelemetry(
          droneId: drone.id,
          lat: drone.lat,
          lon: drone.lng,
          altitudeMeters: drone.altitudeM.toDouble(),
          speedMps: 0,
          headingDeg: 0,
          batteryPercent: drone.batteryPct,
          gpsStatus: hasValidPosition(drone) ? '3D fix' : 'searching',
          linkStatus: linkStatusForDrone(drone),
          missionState: missionStatusFromTelemetry(telemetry.missionState),
          timestamp: DateTime.now(),
        ),
      )
      .toList();
}

bool hasValidPosition(DroneSummary drone) {
  return drone.lat.abs() > 0.001 && drone.lng.abs() > 0.001;
}

LinkStatus linkStatusForDrone(DroneSummary drone) {
  if (drone.connection == 'offline' || drone.connection == 'charging') {
    return LinkStatus.offline;
  }
  if (drone.signalPct >= 75) {
    return LinkStatus.stable;
  }
  if (drone.signalPct > 0) {
    return LinkStatus.degraded;
  }
  return LinkStatus.offline;
}

MissionStatus missionStatusFromTelemetry(String missionState) {
  return switch (missionState) {
    'active' || 'in-flight' || 'executing' => MissionStatus.active,
    'paused' => MissionStatus.paused,
    'complete' || 'completed' => MissionStatus.complete,
    'blocked' => MissionStatus.blocked,
    _ => MissionStatus.planning,
  };
}

String signalQualityLabel(int signalPct) {
  if (signalPct >= 85) return 'Excellent';
  if (signalPct >= 70) return 'Strong';
  if (signalPct >= 45) return 'Fair';
  if (signalPct > 0) return 'Weak';
  return 'Offline';
}

String gpsQualityLabel(DroneSummary drone) {
  if (!hasValidPosition(drone)) return 'Searching';
  if (drone.altitudeM > 0) return '3D fix';
  return '2D fix';
}

double missionReadinessScore({
  required DjiStatus? status,
  required List<DroneSummary> fleet,
}) {
  if (!(status?.liveData ?? false) || fleet.isEmpty) {
    return 0;
  }

  final active = fleet
      .where(
        (drone) =>
            drone.connection == 'online' || drone.connection == 'standby',
      )
      .length;
  final avgBattery = fleet
          .map((drone) => drone.batteryPct)
          .fold<int>(0, (sum, value) => sum + value) /
      fleet.length;
  return ((active / fleet.length) * 0.55 + (avgBattery / 100) * 0.45).clamp(
    0.0,
    1.0,
  );
}

int averageFleetSignal(List<DroneSummary> fleet) {
  if (fleet.isEmpty) {
    return 0;
  }
  final total = fleet
      .map((drone) => drone.signalPct)
      .fold<int>(0, (sum, value) => sum + value);
  return (total / fleet.length).round();
}
