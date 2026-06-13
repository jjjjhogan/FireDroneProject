import 'operations_enums.dart';

class DroneTelemetry {
  const DroneTelemetry({
    required this.droneId,
    required this.lat,
    required this.lon,
    required this.altitudeMeters,
    required this.speedMps,
    required this.headingDeg,
    required this.batteryPercent,
    required this.gpsStatus,
    required this.linkStatus,
    required this.missionState,
    required this.timestamp,
  });

  final String droneId;
  final double lat;
  final double lon;
  final double altitudeMeters;
  final double speedMps;
  final double headingDeg;
  final int batteryPercent;
  final String gpsStatus;
  final LinkStatus linkStatus;
  final MissionStatus missionState;
  final DateTime timestamp;
}
