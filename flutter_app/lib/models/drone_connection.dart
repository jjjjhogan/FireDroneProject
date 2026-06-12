import 'simulation_layout.dart';

class DjiStatus {
  const DjiStatus({
    required this.provider,
    required this.connector,
    required this.connection,
    required this.commandEnabled,
    required this.liveData,
    required this.missingConfiguration,
    required this.reservedAdapters,
    required this.lastSync,
  });

  final String provider;
  final String connector;
  final String connection;
  final bool commandEnabled;
  final bool liveData;
  final List<String> missingConfiguration;
  final List<String> reservedAdapters;
  final String lastSync;

  factory DjiStatus.fromJson(Map<String, dynamic> json) {
    return DjiStatus(
      provider: json['provider'] as String? ?? 'DJI',
      connector: json['connector'] as String? ?? 'real',
      connection: json['connection'] as String? ?? 'not-configured',
      commandEnabled: json['commandEnabled'] as bool? ?? false,
      liveData: json['liveData'] as bool? ?? false,
      missingConfiguration:
          (json['missingConfiguration'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      reservedAdapters: (json['reservedAdapters'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      lastSync: json['lastSync'] as String? ?? 'not configured',
    );
  }
}

class DroneSummary {
  const DroneSummary({
    required this.id,
    required this.name,
    required this.model,
    required this.connection,
    required this.batteryPct,
    required this.signalPct,
    required this.lat,
    required this.lng,
    required this.altitudeM,
    required this.lastSeen,
    required this.warnings,
  });

  final String id;
  final String name;
  final String model;
  final String connection;
  final int batteryPct;
  final int signalPct;
  final double lat;
  final double lng;
  final int altitudeM;
  final String lastSeen;
  final List<String> warnings;

  factory DroneSummary.fromJson(Map<String, dynamic> json) {
    return DroneSummary(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'DJI aircraft',
      model: json['model'] as String? ?? 'DJI enterprise aircraft',
      connection: json['connection'] as String? ?? 'offline',
      batteryPct: (json['batteryPct'] as num? ?? 0).round(),
      signalPct: (json['signalPct'] as num? ?? 0).round(),
      lat: (json['lat'] as num? ?? 0).toDouble(),
      lng: (json['lng'] as num? ?? 0).toDouble(),
      altitudeM: (json['altitudeM'] as num? ?? 0).round(),
      lastSeen: json['lastSeen'] as String? ?? 'unknown',
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class TelemetrySnapshot {
  const TelemetrySnapshot({
    required this.activeDroneId,
    required this.missionState,
    required this.routeProgressPct,
    required this.windMph,
    required this.temperatureF,
    required this.firePerimeterRisk,
    required this.linkHealth,
  });

  final String activeDroneId;
  final String missionState;
  final int routeProgressPct;
  final double windMph;
  final double temperatureF;
  final String firePerimeterRisk;
  final String linkHealth;

  factory TelemetrySnapshot.fromJson(Map<String, dynamic> json) {
    return TelemetrySnapshot(
      activeDroneId: json['activeDroneId'] as String? ?? 'unknown',
      missionState: json['missionState'] as String? ?? 'standby',
      routeProgressPct: (json['routeProgressPct'] as num? ?? 0).round(),
      windMph: (json['windMph'] as num? ?? 0).toDouble(),
      temperatureF: (json['temperatureF'] as num? ?? 0).toDouble(),
      firePerimeterRisk: json['firePerimeterRisk'] as String? ?? 'unknown',
      linkHealth: json['linkHealth'] as String? ?? 'unknown',
    );
  }

  SimulationTelemetry toSimulationTelemetry({required bool routeCrossesFire}) {
    return SimulationTelemetry(
      label: linkHealth == 'stable' ? 'DJI link stable' : linkHealth,
      windMph: windMph,
      humidityPct: firePerimeterRisk == 'elevated' ? 38 : 44,
      coveragePct: 72 + routeProgressPct.clamp(0, 18),
      progressPct: routeProgressPct,
      routeCrossesFire: routeCrossesFire,
    );
  }
}

class MissionPreview {
  const MissionPreview({
    required this.available,
    required this.scenarioId,
    required this.routePoints,
    required this.estimatedDurationMin,
    required this.maxAltitudeM,
    required this.riskLevel,
    required this.warnings,
    required this.requiresConfirmation,
  });

  final bool available;
  final String scenarioId;
  final List<Map<String, double>> routePoints;
  final int estimatedDurationMin;
  final int maxAltitudeM;
  final String riskLevel;
  final List<String> warnings;
  final bool requiresConfirmation;

  factory MissionPreview.fromJson(Map<String, dynamic> json) {
    final points = (json['routePoints'] as List<dynamic>? ?? const []).map((
      item,
    ) {
      final point = item as Map<String, dynamic>;
      return {
        'lat': (point['lat'] as num? ?? 0).toDouble(),
        'lng': (point['lng'] as num? ?? 0).toDouble(),
      };
    }).toList();

    return MissionPreview(
      available: json['available'] as bool? ?? true,
      scenarioId: json['scenarioId'] as String? ?? 'unknown',
      routePoints: points,
      estimatedDurationMin: (json['estimatedDurationMin'] as num? ?? 0).round(),
      maxAltitudeM: (json['maxAltitudeM'] as num? ?? 0).round(),
      riskLevel: json['riskLevel'] as String? ?? 'unknown',
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? true,
    );
  }
}

class MissionConfirmResult {
  const MissionConfirmResult({
    required this.accepted,
    required this.blockedReason,
    required this.missionId,
    required this.nextRequiredAction,
  });

  final bool accepted;
  final String? blockedReason;
  final String? missionId;
  final String nextRequiredAction;

  factory MissionConfirmResult.fromJson(Map<String, dynamic> json) {
    return MissionConfirmResult(
      accepted: json['accepted'] as bool? ?? false,
      blockedReason: json['blockedReason'] as String?,
      missionId: json['missionId'] as String?,
      nextRequiredAction:
          json['nextRequiredAction'] as String? ?? 'Review mission package',
    );
  }
}
