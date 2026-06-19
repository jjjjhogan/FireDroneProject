import '../models/operations_enums.dart';

class MissionRoutePoint {
  const MissionRoutePoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory MissionRoutePoint.fromJson(Map<String, dynamic> json) {
    return MissionRoutePoint(
      lat: (json['lat'] as num? ?? 0).toDouble(),
      lng: (json['lng'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, double> toJson() => {'lat': lat, 'lng': lng};
}

class MissionRecord {
  const MissionRecord({
    required this.missionId,
    required this.scenarioId,
    required this.scenarioName,
    required this.area,
    required this.status,
    required this.assignedDroneId,
    required this.operatorName,
    required this.routePoints,
    required this.progressPct,
    required this.estimatedDurationMin,
    required this.riskLevel,
    required this.dataSource,
    required this.notes,
    required this.startedAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String missionId;
  final String scenarioId;
  final String scenarioName;
  final String area;
  final String status;
  final String assignedDroneId;
  final String operatorName;
  final List<MissionRoutePoint> routePoints;
  final int progressPct;
  final int estimatedDurationMin;
  final String riskLevel;
  final String dataSource;
  final String notes;
  final String startedAt;
  final String updatedAt;
  final String? completedAt;

  bool get isTerminal => status == 'completed' || status == 'aborted';

  bool get canStart =>
      status == 'preview_ready' || status == 'confirmed' || status == 'planning';

  bool get canPause => status == 'active';

  bool get canAbort =>
      status == 'active' ||
      status == 'paused' ||
      status == 'preview_ready' ||
      status == 'confirmed' ||
      status == 'planning';

  factory MissionRecord.fromJson(Map<String, dynamic> json) {
    final points = (json['routePoints'] as List<dynamic>? ?? const [])
        .map(
          (item) => MissionRoutePoint.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return MissionRecord(
      missionId: json['missionId'] as String? ?? 'unknown',
      scenarioId: json['scenarioId'] as String? ?? 'unknown',
      scenarioName: json['scenarioName'] as String? ?? 'Unknown scenario',
      area: json['area'] as String? ?? 'Unknown area',
      status: json['status'] as String? ?? 'planning',
      assignedDroneId: json['assignedDroneId'] as String? ?? 'unassigned',
      operatorName: json['operatorName'] as String? ?? 'Operator',
      routePoints: points,
      progressPct: (json['progressPct'] as num? ?? 0).round(),
      estimatedDurationMin: (json['estimatedDurationMin'] as num? ?? 0).round(),
      riskLevel: json['riskLevel'] as String? ?? 'unknown',
      dataSource: json['dataSource'] as String? ?? 'simulation',
      notes: json['notes'] as String? ?? '',
      startedAt: json['startedAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      completedAt: json['completedAt'] as String?,
    );
  }

  Mission toDashboardMission() {
    return Mission(
      missionId: missionId,
      name: scenarioName,
      area: area,
      assignedDroneId: assignedDroneId,
      operatorName: operatorName,
      status: _dashboardStatus(status),
      startTime: DateTime.tryParse(startedAt) ?? DateTime.now(),
      lastUpdateTime: DateTime.tryParse(updatedAt) ?? DateTime.now(),
      notes: notes,
      scenarioId: scenarioId,
      progressPct: progressPct,
      dataSource: dataSource,
      lifecycleStatus: status,
      estimatedDurationMin: estimatedDurationMin,
      riskLevel: riskLevel,
    );
  }

  static MissionStatus _dashboardStatus(String status) {
    return switch (status) {
      'active' => MissionStatus.active,
      'paused' => MissionStatus.paused,
      'completed' => MissionStatus.complete,
      'aborted' => MissionStatus.blocked,
      'preview_ready' || 'confirmed' => MissionStatus.planning,
      _ => MissionStatus.planning,
    };
  }
}

class Mission {
  const Mission({
    required this.missionId,
    required this.name,
    required this.area,
    required this.assignedDroneId,
    required this.operatorName,
    required this.status,
    required this.startTime,
    required this.lastUpdateTime,
    required this.notes,
    this.scenarioId = 'unknown',
    this.progressPct = 0,
    this.dataSource = 'simulation',
    this.lifecycleStatus = 'planning',
    this.estimatedDurationMin = 0,
    this.riskLevel = 'unknown',
  });

  final String missionId;
  final String name;
  final String area;
  final String assignedDroneId;
  final String operatorName;
  final MissionStatus status;
  final DateTime startTime;
  final DateTime lastUpdateTime;
  final String notes;
  final String scenarioId;
  final int progressPct;
  final String dataSource;
  final String lifecycleStatus;
  final int estimatedDurationMin;
  final String riskLevel;
}
