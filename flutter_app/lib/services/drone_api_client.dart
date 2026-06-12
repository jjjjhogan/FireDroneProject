import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/mock_analytics.dart';
import '../models/analytics_snapshot.dart';
import '../models/drone_connection.dart';
import '../models/scenario.dart';
import '../models/simulation_layout.dart';

abstract class DroneApiClient {
  Future<DjiStatus> fetchStatus();
  Future<List<DroneSummary>> fetchFleet();
  Future<TelemetrySnapshot> fetchTelemetry();
  Future<AnalyticsSnapshot> fetchAnalytics();
  Future<MissionPreview> previewMission({
    required Scenario scenario,
    required SimulationLayout layout,
  });
  Future<MissionConfirmResult> confirmMission(MissionPreview preview);
}

class HttpDroneApiClient implements DroneApiClient {
  HttpDroneApiClient({Uri? baseUri, http.Client? client})
    : baseUri = baseUri ?? Uri.parse('http://127.0.0.1:5000/api'),
      _client = client ?? http.Client();

  final Uri baseUri;
  final http.Client _client;

  Uri _uri(String path) => baseUri.replace(path: '${baseUri.path}$path');

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _client.get(_uri(path));
    if (response.statusCode >= 400) {
      throw StateError('DJI API request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<DjiStatus> fetchStatus() async {
    return DjiStatus.fromJson(await _getJson('/dji/status'));
  }

  @override
  Future<List<DroneSummary>> fetchFleet() async {
    final json = await _getJson('/dji/fleet');
    return (json['drones'] as List<dynamic>? ?? const [])
        .map((item) => DroneSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TelemetrySnapshot> fetchTelemetry() async {
    return TelemetrySnapshot.fromJson(await _getJson('/dji/telemetry'));
  }

  @override
  Future<AnalyticsSnapshot> fetchAnalytics() async {
    return AnalyticsSnapshot.fromJson(await _getJson('/analytics/summary'));
  }

  @override
  Future<MissionPreview> previewMission({
    required Scenario scenario,
    required SimulationLayout layout,
  }) async {
    final json = await _postJson('/dji/missions/preview', {
      'scenarioId': scenario.name.toLowerCase().replaceAll(' ', '-'),
      'routePoints': layout.routePoints
          .map(
            (point) => {
              'lat': 37.2 + point.normalizedPosition.dy / 10,
              'lng': -119.55 + point.normalizedPosition.dx / 10,
            },
          )
          .toList(),
    });
    return MissionPreview.fromJson(json);
  }

  @override
  Future<MissionConfirmResult> confirmMission(MissionPreview preview) async {
    final json = await _postJson('/dji/missions/confirm', {
      'scenarioId': preview.scenarioId,
      'routePoints': preview.routePoints,
      'estimatedDurationMin': preview.estimatedDurationMin,
      'maxAltitudeM': preview.maxAltitudeM,
      'riskLevel': preview.riskLevel,
      'requiresConfirmation': preview.requiresConfirmation,
    });
    return MissionConfirmResult.fromJson(json);
  }
}

class MockDroneApiClient implements DroneApiClient {
  const MockDroneApiClient();

  @override
  Future<DjiStatus> fetchStatus() async {
    return const DjiStatus(
      provider: 'DJI',
      connector: 'mock',
      connection: 'simulated',
      commandEnabled: false,
      reservedAdapters: ['DJI Cloud API', 'DJI Mobile SDK Bridge'],
      lastSync: 'live mock feed',
    );
  }

  @override
  Future<List<DroneSummary>> fetchFleet() async {
    return const [
      DroneSummary(
        id: 'dji-thermal-01',
        name: 'DJI Thermal Lead',
        model: 'DJI enterprise aircraft',
        connection: 'online',
        batteryPct: 82,
        signalPct: 94,
        lat: 37.2138,
        lng: -119.5414,
        altitudeM: 118,
        lastSeen: 'now',
        warnings: [],
      ),
      DroneSummary(
        id: 'dji-relay-02',
        name: 'DJI Relay Scout',
        model: 'DJI enterprise aircraft',
        connection: 'standby',
        batteryPct: 68,
        signalPct: 87,
        lat: 37.2204,
        lng: -119.5266,
        altitudeM: 96,
        lastSeen: 'now',
        warnings: ['Manual launch confirmation required'],
      ),
      DroneSummary(
        id: 'dji-map-03',
        name: 'DJI Mapper Reserve',
        model: 'DJI enterprise aircraft',
        connection: 'charging',
        batteryPct: 54,
        signalPct: 0,
        lat: 37.2064,
        lng: -119.5531,
        altitudeM: 0,
        lastSeen: 'dock',
        warnings: ['Dock battery below dispatch target'],
      ),
    ];
  }

  @override
  Future<TelemetrySnapshot> fetchTelemetry() async {
    return const TelemetrySnapshot(
      activeDroneId: 'dji-thermal-01',
      missionState: 'preview-ready',
      routeProgressPct: 0,
      windMph: 14,
      temperatureF: 73,
      firePerimeterRisk: 'elevated',
      linkHealth: 'stable',
    );
  }

  @override
  Future<AnalyticsSnapshot> fetchAnalytics() async {
    return mockAnalyticsSnapshot;
  }

  @override
  Future<MissionPreview> previewMission({
    required Scenario scenario,
    required SimulationLayout layout,
  }) async {
    return MissionPreview(
      scenarioId: scenario.name,
      routePoints: layout.routePoints
          .map(
            (point) => {
              'lat': 37.2 + point.normalizedPosition.dy / 10,
              'lng': -119.55 + point.normalizedPosition.dx / 10,
            },
          )
          .toList(),
      estimatedDurationMin: 18,
      maxAltitudeM: 120,
      riskLevel: 'elevated',
      warnings: const [
        'DJI command dispatch is locked until a human confirms.',
        'Route intersects the active fire perimeter buffer.',
      ],
      requiresConfirmation: true,
    );
  }

  @override
  Future<MissionConfirmResult> confirmMission(MissionPreview preview) async {
    return const MissionConfirmResult(
      accepted: false,
      blockedReason:
          'ALLOW_DJI_COMMANDS is false; live DJI command dispatch is locked.',
      missionId: null,
      nextRequiredAction: 'Enable backend command gate',
    );
  }
}
