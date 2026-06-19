import 'simulation_layout.dart';

class DjiStatus {
  const DjiStatus({
    required this.provider,
    required this.connector,
    required this.connection,
    required this.commandEnabled,
    required this.liveData,
    required this.ingestConfigured,
    required this.aircraftCount,
    required this.source,
    required this.staleReason,
    required this.missingConfiguration,
    required this.reservedAdapters,
    required this.lastSync,
  });

  final String provider;
  final String connector;
  final String connection;
  final bool commandEnabled;
  final bool liveData;
  final bool ingestConfigured;
  final int aircraftCount;
  final String source;
  final String staleReason;
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
      ingestConfigured: json['ingestConfigured'] as bool? ?? false,
      aircraftCount: (json['aircraftCount'] as num? ?? 0).round(),
      source: json['source'] as String? ?? 'none',
      staleReason: json['staleReason'] as String? ?? '',
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

class DjiConnectionConfig {
  const DjiConnectionConfig({
    required this.configured,
    required this.mode,
    required this.operatorLabel,
    required this.ingestTokenConfigured,
    required this.cloudMqttHostConfigured,
    required this.cloudMqttUsernameConfigured,
    required this.cloudMqttClientId,
    required this.workspaceIdConfigured,
    required this.appIdConfigured,
    required this.mobileBridgeEndpoint,
    required this.updatedAt,
    this.cloudBridge,
  });

  final bool configured;
  final String mode;
  final String operatorLabel;
  final bool ingestTokenConfigured;
  final bool cloudMqttHostConfigured;
  final bool cloudMqttUsernameConfigured;
  final String cloudMqttClientId;
  final bool workspaceIdConfigured;
  final bool appIdConfigured;
  final String mobileBridgeEndpoint;
  final String? updatedAt;
  final CloudBridgeStatus? cloudBridge;

  factory DjiConnectionConfig.fromJson(Map<String, dynamic> json) {
    final bridgeJson = json['cloudBridge'];
    return DjiConnectionConfig(
      configured: json['configured'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'not-configured',
      operatorLabel: json['operatorLabel'] as String? ?? '',
      ingestTokenConfigured: json['ingestTokenConfigured'] as bool? ?? false,
      cloudMqttHostConfigured:
          json['cloudMqttHostConfigured'] as bool? ?? false,
      cloudMqttUsernameConfigured:
          json['cloudMqttUsernameConfigured'] as bool? ?? false,
      cloudMqttClientId: json['cloudMqttClientId'] as String? ?? '',
      workspaceIdConfigured: json['workspaceIdConfigured'] as bool? ?? false,
      appIdConfigured: json['appIdConfigured'] as bool? ?? false,
      mobileBridgeEndpoint: json['mobileBridgeEndpoint'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
      cloudBridge: bridgeJson is Map<String, dynamic>
          ? CloudBridgeStatus.fromJson(bridgeJson)
          : null,
    );
  }
}

class CloudBridgeStatus {
  const CloudBridgeStatus({
    required this.running,
    required this.state,
    required this.host,
    this.lastMessageAt,
    this.lastError,
  });

  final bool running;
  final String state;
  final String host;
  final String? lastMessageAt;
  final String? lastError;

  factory CloudBridgeStatus.fromJson(Map<String, dynamic> json) {
    return CloudBridgeStatus(
      running: json['running'] as bool? ?? false,
      state: json['state'] as String? ?? 'stopped',
      host: json['host'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] as String?,
      lastError: json['lastError'] as String?,
    );
  }

  String get displayLabel {
    if (running && state == 'subscribed') {
      return 'MQTT subscribed';
    }
    if (state == 'starting') {
      return 'MQTT starting';
    }
    if (state == 'stopped') {
      return 'MQTT stopped';
    }
    if (state == 'connect-failed' || state == 'missing-config') {
      return 'MQTT $state';
    }
    return 'MQTT $state';
  }
}

class DjiConnectionRequest {
  const DjiConnectionRequest({
    required this.mode,
    required this.ingestToken,
    required this.operatorLabel,
    required this.cloudMqttHost,
    required this.cloudMqttPort,
    required this.cloudMqttUsername,
    required this.cloudMqttPassword,
    required this.cloudMqttClientId,
    required this.cloudApiAppId,
    required this.cloudApiAppKey,
    required this.cloudApiAppLicense,
    required this.workspaceId,
  });

  final String mode;
  final String ingestToken;
  final String operatorLabel;
  final String cloudMqttHost;
  final int cloudMqttPort;
  final String cloudMqttUsername;
  final String cloudMqttPassword;
  final String cloudMqttClientId;
  final String cloudApiAppId;
  final String cloudApiAppKey;
  final String cloudApiAppLicense;
  final String workspaceId;

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'ingestToken': ingestToken,
      'operatorLabel': operatorLabel,
      'cloudMqttHost': cloudMqttHost,
      'cloudMqttPort': cloudMqttPort,
      'cloudMqttUsername': cloudMqttUsername,
      'cloudMqttPassword': cloudMqttPassword,
      'cloudMqttClientId': cloudMqttClientId,
      'cloudApiAppId': cloudApiAppId,
      'cloudApiAppKey': cloudApiAppKey,
      'cloudApiAppLicense': cloudApiAppLicense,
      'workspaceId': workspaceId,
    };
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
