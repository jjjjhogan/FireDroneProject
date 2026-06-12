class AnalyticsKpi {
  const AnalyticsKpi({
    required this.id,
    required this.label,
    required this.value,
    required this.detail,
    this.trend,
  });

  final String id;
  final String label;
  final String value;
  final String detail;
  final String? trend;

  factory AnalyticsKpi.fromJson(Map<String, dynamic> json) {
    return AnalyticsKpi(
      id: json['id'] as String? ?? 'unknown',
      label: json['label'] as String? ?? 'Metric',
      value: json['value'] as String? ?? '--',
      detail: json['detail'] as String? ?? '',
      trend: json['trend'] as String?,
    );
  }
}

class AnalyticsTrendPoint {
  const AnalyticsTrendPoint({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final double value;
  final String unit;

  factory AnalyticsTrendPoint.fromJson(Map<String, dynamic> json) {
    return AnalyticsTrendPoint(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String? ?? '',
    );
  }
}

class AnalyticsMissionRecord {
  const AnalyticsMissionRecord({
    required this.missionId,
    required this.scenarioName,
    required this.outcome,
    required this.durationMin,
    required this.hotspotsDetected,
    required this.completedAt,
  });

  final String missionId;
  final String scenarioName;
  final String outcome;
  final int durationMin;
  final int hotspotsDetected;
  final String completedAt;

  factory AnalyticsMissionRecord.fromJson(Map<String, dynamic> json) {
    return AnalyticsMissionRecord(
      missionId: json['missionId'] as String? ?? 'unknown',
      scenarioName: json['scenarioName'] as String? ?? 'Unknown scenario',
      outcome: json['outcome'] as String? ?? 'completed',
      durationMin: (json['durationMin'] as num? ?? 0).round(),
      hotspotsDetected: (json['hotspotsDetected'] as num? ?? 0).round(),
      completedAt: json['completedAt'] as String? ?? 'unknown',
    );
  }
}

class AnalyticsEnvironmental {
  const AnalyticsEnvironmental({
    required this.windMph,
    required this.humidityPct,
    required this.visibilityMi,
    required this.smokeIndex,
    required this.thermalNoise,
  });

  final double windMph;
  final int humidityPct;
  final double visibilityMi;
  final String smokeIndex;
  final String thermalNoise;

  factory AnalyticsEnvironmental.fromJson(Map<String, dynamic> json) {
    return AnalyticsEnvironmental(
      windMph: (json['windMph'] as num? ?? 0).toDouble(),
      humidityPct: (json['humidityPct'] as num? ?? 0).round(),
      visibilityMi: (json['visibilityMi'] as num? ?? 0).toDouble(),
      smokeIndex: json['smokeIndex'] as String? ?? 'unknown',
      thermalNoise: json['thermalNoise'] as String? ?? 'unknown',
    );
  }
}

class AnalyticsFleetUtilization {
  const AnalyticsFleetUtilization({
    required this.activeDrones,
    required this.availableDrones,
    required this.chargingDrones,
    required this.flightHoursToday,
    required this.sortiesToday,
    required this.avgBatteryAtLaunchPct,
  });

  final int activeDrones;
  final int availableDrones;
  final int chargingDrones;
  final double flightHoursToday;
  final int sortiesToday;
  final int avgBatteryAtLaunchPct;

  factory AnalyticsFleetUtilization.fromJson(Map<String, dynamic> json) {
    return AnalyticsFleetUtilization(
      activeDrones: (json['activeDrones'] as num? ?? 0).round(),
      availableDrones: (json['availableDrones'] as num? ?? 0).round(),
      chargingDrones: (json['chargingDrones'] as num? ?? 0).round(),
      flightHoursToday: (json['flightHoursToday'] as num? ?? 0).toDouble(),
      sortiesToday: (json['sortiesToday'] as num? ?? 0).round(),
      avgBatteryAtLaunchPct:
          (json['avgBatteryAtLaunchPct'] as num? ?? 0).round(),
    );
  }
}

class AnalyticsIntegrationTarget {
  const AnalyticsIntegrationTarget({
    required this.label,
    required this.endpoint,
    required this.status,
  });

  final String label;
  final String endpoint;
  final String status;

  factory AnalyticsIntegrationTarget.fromJson(Map<String, dynamic> json) {
    return AnalyticsIntegrationTarget(
      label: json['label'] as String? ?? 'Integration',
      endpoint: json['endpoint'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.dataSource,
    required this.lastUpdated,
    required this.kpis,
    required this.weeklyDetections,
    required this.responseTimesMin,
    required this.recentMissions,
    required this.environmental,
    required this.fleetUtilization,
    required this.integrationTargets,
  });

  final String dataSource;
  final String lastUpdated;
  final List<AnalyticsKpi> kpis;
  final List<AnalyticsTrendPoint> weeklyDetections;
  final List<AnalyticsTrendPoint> responseTimesMin;
  final List<AnalyticsMissionRecord> recentMissions;
  final AnalyticsEnvironmental environmental;
  final AnalyticsFleetUtilization fleetUtilization;
  final List<AnalyticsIntegrationTarget> integrationTargets;

  factory AnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(
      String key,
      T Function(Map<String, dynamic> item) mapper,
    ) {
      return (json[key] as List<dynamic>? ?? const [])
          .map((item) => mapper(item as Map<String, dynamic>))
          .toList();
    }

    return AnalyticsSnapshot(
      dataSource: json['dataSource'] as String? ?? 'mock',
      lastUpdated: json['lastUpdated'] as String? ?? 'unknown',
      kpis: mapList('kpis', AnalyticsKpi.fromJson),
      weeklyDetections: mapList(
        'weeklyDetections',
        AnalyticsTrendPoint.fromJson,
      ),
      responseTimesMin: mapList(
        'responseTimesMin',
        AnalyticsTrendPoint.fromJson,
      ),
      recentMissions: mapList(
        'recentMissions',
        AnalyticsMissionRecord.fromJson,
      ),
      environmental: AnalyticsEnvironmental.fromJson(
        json['environmental'] as Map<String, dynamic>? ?? const {},
      ),
      fleetUtilization: AnalyticsFleetUtilization.fromJson(
        json['fleetUtilization'] as Map<String, dynamic>? ?? const {},
      ),
      integrationTargets: mapList(
        'integrationTargets',
        AnalyticsIntegrationTarget.fromJson,
      ),
    );
  }
}
