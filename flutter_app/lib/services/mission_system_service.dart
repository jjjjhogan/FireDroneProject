import 'dart:convert';

import 'package:http/http.dart' as http;

import '../mock/simulation_fixtures.dart';
import '../models/mission.dart';
import '../models/scenario.dart';
import '../models/simulation_layout.dart';
import '../models/drone_connection.dart';

abstract class MissionSystemService {
  Future<MissionRecord?> fetchActiveMission();
  Future<List<MissionRecord>> fetchRecentMissions({int limit = 10});
  Future<MissionRecord> planMission({
    required Scenario scenario,
    required SimulationLayout layout,
    String? assignedDroneId,
    String dataSource,
  });
  Future<MissionRecord> transitionMission({
    required String missionId,
    required String status,
    String? notes,
    int? progressPct,
  });
}

class HttpMissionSystemService implements MissionSystemService {
  HttpMissionSystemService({this.baseUrl = 'http://127.0.0.1:5000/api'});

  final String baseUrl;

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode >= 400) {
      throw Exception('Mission API failed (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode >= 400) {
      throw Exception('Mission API failed (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<MissionRecord?> fetchActiveMission() async {
    final json = await _getJson('/missions/active');
    final mission = json['mission'];
    if (mission == null) {
      return null;
    }
    return MissionRecord.fromJson(mission as Map<String, dynamic>);
  }

  @override
  Future<List<MissionRecord>> fetchRecentMissions({int limit = 10}) async {
    final json = await _getJson('/missions?limit=$limit');
    return (json['missions'] as List<dynamic>? ?? const [])
        .map((item) => MissionRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MissionRecord> planMission({
    required Scenario scenario,
    required SimulationLayout layout,
    String? assignedDroneId,
    String dataSource = 'simulation',
  }) async {
    final json = await _postJson('/missions/plan', {
      'scenarioId': scenario.scenarioId,
      'scenarioName': scenario.title,
      'area': scenario.region,
      'operatorName': 'Simulation Operator',
      'assignedDroneId': assignedDroneId ?? 'unassigned',
      'dataSource': dataSource,
      'routePoints': layout.routePoints
          .map(
            (point) => {
              'lat': 37.2 + point.normalizedPosition.dy / 10,
              'lng': -119.55 + point.normalizedPosition.dx / 10,
            },
          )
          .toList(),
    });
    return MissionRecord.fromJson(json['mission'] as Map<String, dynamic>);
  }

  @override
  Future<MissionRecord> transitionMission({
    required String missionId,
    required String status,
    String? notes,
    int? progressPct,
  }) async {
    final json = await _postJson('/missions/$missionId/transition', {
      'status': status,
      if (notes != null) 'notes': notes,
      if (progressPct != null) 'progressPct': progressPct,
    });
    return MissionRecord.fromJson(json['mission'] as Map<String, dynamic>);
  }
}

class MockMissionSystemService implements MissionSystemService {
  MockMissionSystemService();

  MissionRecord? _active;

  @override
  Future<MissionRecord?> fetchActiveMission() async {
    return _active;
  }

  @override
  Future<List<MissionRecord>> fetchRecentMissions({int limit = 10}) async {
    if (_active == null) {
      return const [];
    }
    return [_active!];
  }

  @override
  Future<MissionRecord> planMission({
    required Scenario scenario,
    required SimulationLayout layout,
    String? assignedDroneId,
    String dataSource = 'simulation',
  }) async {
    _active = MissionRecord(
      missionId: 'mission-${scenario.scenarioId}',
      scenarioId: scenario.scenarioId,
      scenarioName: scenario.title,
      area: scenario.region,
      status: 'planning',
      assignedDroneId: assignedDroneId ?? mockMission.assignedDroneId,
      operatorName: mockMission.operatorName,
      routePoints: layout.routePoints
          .map(
            (point) => MissionRoutePoint(
              lat: 37.2 + point.normalizedPosition.dy / 10,
              lng: -119.55 + point.normalizedPosition.dx / 10,
            ),
          )
          .toList(),
      progressPct: 0,
      estimatedDurationMin: 0,
      riskLevel: 'unknown',
      dataSource: dataSource,
      notes: mockMission.notes,
      startedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    return _active!;
  }

  @override
  Future<MissionRecord> transitionMission({
    required String missionId,
    required String status,
    String? notes,
    int? progressPct,
  }) async {
    if (_active == null || _active!.missionId != missionId) {
      throw Exception('Mission not found');
    }
    _active = MissionRecord(
      missionId: _active!.missionId,
      scenarioId: _active!.scenarioId,
      scenarioName: _active!.scenarioName,
      area: _active!.area,
      status: status,
      assignedDroneId: _active!.assignedDroneId,
      operatorName: _active!.operatorName,
      routePoints: _active!.routePoints,
      progressPct: progressPct ?? _active!.progressPct,
      estimatedDurationMin: _active!.estimatedDurationMin,
      riskLevel: _active!.riskLevel,
      dataSource: _active!.dataSource,
      notes: notes ?? _active!.notes,
      startedAt: _active!.startedAt,
      updatedAt: DateTime.now().toIso8601String(),
      completedAt: status == 'completed' || status == 'aborted'
          ? DateTime.now().toIso8601String()
          : _active!.completedAt,
    );
    return _active!;
  }
}

class ResilientMissionSystemService implements MissionSystemService {
  ResilientMissionSystemService({
    HttpMissionSystemService? httpService,
    MockMissionSystemService? mockService,
  }) : _http = httpService ?? HttpMissionSystemService(),
       _mock = mockService ?? MockMissionSystemService();

  final HttpMissionSystemService _http;
  final MockMissionSystemService _mock;

  @override
  Future<MissionRecord?> fetchActiveMission() async {
    try {
      return await _http.fetchActiveMission();
    } catch (_) {
      return _mock.fetchActiveMission();
    }
  }

  @override
  Future<List<MissionRecord>> fetchRecentMissions({int limit = 10}) async {
    try {
      return await _http.fetchRecentMissions(limit: limit);
    } catch (_) {
      return _mock.fetchRecentMissions(limit: limit);
    }
  }

  @override
  Future<MissionRecord> planMission({
    required Scenario scenario,
    required SimulationLayout layout,
    String? assignedDroneId,
    String dataSource = 'simulation',
  }) async {
    try {
      return await _http.planMission(
        scenario: scenario,
        layout: layout,
        assignedDroneId: assignedDroneId,
        dataSource: dataSource,
      );
    } catch (_) {
      return _mock.planMission(
        scenario: scenario,
        layout: layout,
        assignedDroneId: assignedDroneId,
        dataSource: dataSource,
      );
    }
  }

  @override
  Future<MissionRecord> transitionMission({
    required String missionId,
    required String status,
    String? notes,
    int? progressPct,
  }) async {
    try {
      return await _http.transitionMission(
        missionId: missionId,
        status: status,
        notes: notes,
        progressPct: progressPct,
      );
    } catch (_) {
      return _mock.transitionMission(
        missionId: missionId,
        status: status,
        notes: notes,
        progressPct: progressPct,
      );
    }
  }
}

String missionDataSourceForStatus(DjiStatus? status) {
  if (status?.liveData ?? false) {
    return status?.source ?? 'dji-bridge';
  }
  if (status?.ingestConfigured ?? false) {
    return 'dji-bridge-pending';
  }
  return 'simulation';
}
