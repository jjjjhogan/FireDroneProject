import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/drone_connection.dart';
import '../models/scenario.dart';
import '../models/simulation_layout.dart';

abstract class DroneApiClient {
  Future<DjiStatus> fetchStatus();
  Future<DjiConnectionConfig> fetchConnectionConfig();
  Future<DjiConnectionConfig> saveConnectionConfig(
    DjiConnectionRequest request,
  );
  Future<List<DroneSummary>> fetchFleet();
  Future<TelemetrySnapshot> fetchTelemetry();
  Future<MissionPreview> previewMission({
    required Scenario scenario,
    required SimulationLayout layout,
  });
  Future<MissionConfirmResult> confirmMission(MissionPreview preview);
}

class ResilientDroneApiClient implements DroneApiClient {
  ResilientDroneApiClient({DroneApiClient? primary, DroneApiClient? fallback})
    : _primary = primary ?? HttpDroneApiClient(),
      _fallback = fallback ?? const UnavailableDroneApiClient();

  final DroneApiClient _primary;
  final DroneApiClient _fallback;

  Future<T> _fromPrimary<T>(
    Future<T> Function(DroneApiClient client) request,
  ) async {
    try {
      return await request(_primary);
    } catch (_) {
      return request(_fallback);
    }
  }

  @override
  Future<DjiStatus> fetchStatus() {
    return _fromPrimary((client) => client.fetchStatus());
  }

  @override
  Future<DjiConnectionConfig> fetchConnectionConfig() {
    return _fromPrimary((client) => client.fetchConnectionConfig());
  }

  @override
  Future<DjiConnectionConfig> saveConnectionConfig(
    DjiConnectionRequest request,
  ) {
    return _fromPrimary((client) => client.saveConnectionConfig(request));
  }

  @override
  Future<List<DroneSummary>> fetchFleet() {
    return _fromPrimary((client) => client.fetchFleet());
  }

  @override
  Future<TelemetrySnapshot> fetchTelemetry() {
    return _fromPrimary((client) => client.fetchTelemetry());
  }

  @override
  Future<MissionPreview> previewMission({
    required Scenario scenario,
    required SimulationLayout layout,
  }) {
    return _fromPrimary(
      (client) => client.previewMission(scenario: scenario, layout: layout),
    );
  }

  @override
  Future<MissionConfirmResult> confirmMission(MissionPreview preview) {
    return _fromPrimary((client) => client.confirmMission(preview));
  }
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
  Future<DjiConnectionConfig> fetchConnectionConfig() async {
    return DjiConnectionConfig.fromJson(await _getJson('/dji/connection'));
  }

  @override
  Future<DjiConnectionConfig> saveConnectionConfig(
    DjiConnectionRequest request,
  ) async {
    final json = await _postJson('/dji/connection', request.toJson());
    return DjiConnectionConfig.fromJson(
      json['config'] as Map<String, dynamic>? ?? const {},
    );
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

class UnavailableDroneApiClient implements DroneApiClient {
  const UnavailableDroneApiClient();

  @override
  Future<DjiStatus> fetchStatus() async {
    return const DjiStatus(
      provider: 'DJI',
      connector: 'real',
      connection: 'not-configured',
      commandEnabled: false,
      liveData: false,
      ingestConfigured: false,
      aircraftCount: 0,
      source: 'none',
      staleReason: '',
      missingConfiguration: [
        'DJI_CLOUD_API_APP_ID',
        'DJI_CLOUD_API_APP_KEY',
        'DJI_CLOUD_API_APP_LICENSE',
        'DJI_CLOUD_API_MQTT_HOST',
        'DJI_WORKSPACE_ID',
      ],
      reservedAdapters: ['DJI Cloud API', 'DJI Mobile SDK Bridge'],
      lastSync: 'not configured',
    );
  }

  @override
  Future<DjiConnectionConfig> fetchConnectionConfig() async {
    return const DjiConnectionConfig(
      configured: false,
      mode: 'not-configured',
      operatorLabel: '',
      ingestTokenConfigured: false,
      cloudMqttHostConfigured: false,
      cloudMqttUsernameConfigured: false,
      cloudMqttClientId: '',
      workspaceIdConfigured: false,
      appIdConfigured: false,
      mobileBridgeEndpoint: '',
      updatedAt: null,
    );
  }

  @override
  Future<DjiConnectionConfig> saveConnectionConfig(
    DjiConnectionRequest request,
  ) {
    return fetchConnectionConfig();
  }

  @override
  Future<List<DroneSummary>> fetchFleet() async {
    return const [];
  }

  @override
  Future<TelemetrySnapshot> fetchTelemetry() async {
    return const TelemetrySnapshot(
      activeDroneId: 'unknown',
      missionState: 'not-configured',
      routeProgressPct: 0,
      windMph: 0,
      temperatureF: 0,
      firePerimeterRisk: 'unknown',
      linkHealth: 'not-configured',
    );
  }

  @override
  Future<MissionPreview> previewMission({
    required Scenario scenario,
    required SimulationLayout layout,
  }) async {
    return MissionPreview(
      available: false,
      scenarioId: scenario.name,
      routePoints: layout.routePoints
          .map(
            (point) => {
              'lat': 37.2 + point.normalizedPosition.dy / 10,
              'lng': -119.55 + point.normalizedPosition.dx / 10,
            },
          )
          .toList(),
      estimatedDurationMin: 0,
      maxAltitudeM: 0,
      riskLevel: 'unknown',
      warnings: const [
        'DJI connector is not configured; mission package was not sent to an aircraft.',
      ],
      requiresConfirmation: true,
    );
  }

  @override
  Future<MissionConfirmResult> confirmMission(MissionPreview preview) async {
    return const MissionConfirmResult(
      accepted: false,
      blockedReason:
          'DJI connector is not configured; live command dispatch is unavailable.',
      missionId: null,
      nextRequiredAction: 'Configure DJI Cloud API or Mobile SDK bridge',
    );
  }
}
