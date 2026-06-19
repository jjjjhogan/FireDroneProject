import 'package:fire_drone_app/data/mock_analytics.dart';
import 'package:fire_drone_app/models/analytics_snapshot.dart';
import 'package:fire_drone_app/models/drone_connection.dart';
import 'package:fire_drone_app/models/scenario.dart';
import 'package:fire_drone_app/models/simulation_layout.dart';
import 'package:fire_drone_app/services/drone_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingDroneApiClient implements DroneApiClient {
  _RecordingDroneApiClient({this.failWrites = false, this.failReads = false});

  final bool failWrites;
  final bool failReads;
  int readCalls = 0;
  int writeCalls = 0;

  Never _fail(String action) => throw StateError('primary $action failed');

  @override
  Future<DjiStatus> fetchStatus() async {
    readCalls++;
    if (failReads) _fail('fetchStatus');
    return const DjiStatus(
      provider: 'DJI',
      connector: 'real',
      connection: 'bridge-online',
      commandEnabled: false,
      liveData: true,
      ingestConfigured: true,
      aircraftCount: 1,
      source: 'test',
      staleReason: '',
      missingConfiguration: [],
      reservedAdapters: [],
      lastSync: 'now',
    );
  }

  @override
  Future<DjiConnectionConfig> fetchConnectionConfig() async {
    readCalls++;
    if (failReads) _fail('fetchConnectionConfig');
    return const DjiConnectionConfig(
      configured: true,
      mode: 'cloud-api',
      operatorLabel: '',
      ingestTokenConfigured: true,
      cloudMqttHostConfigured: true,
      cloudMqttUsernameConfigured: false,
      cloudMqttClientId: 'test-client',
      workspaceIdConfigured: false,
      appIdConfigured: false,
      mobileBridgeEndpoint: '',
      updatedAt: null,
    );
  }

  @override
  Future<String> generateConnectionToken() async {
    writeCalls++;
    if (failWrites) _fail('generateConnectionToken');
    return 'generated-token';
  }

  @override
  Future<DjiConnectionConfig> saveConnectionConfig(
    DjiConnectionRequest request,
  ) async {
    writeCalls++;
    if (failWrites) _fail('saveConnectionConfig');
    return const DjiConnectionConfig(
      configured: true,
      mode: 'cloud-api',
      operatorLabel: 'saved',
      ingestTokenConfigured: true,
      cloudMqttHostConfigured: true,
      cloudMqttUsernameConfigured: false,
      cloudMqttClientId: 'test-client',
      workspaceIdConfigured: false,
      appIdConfigured: false,
      mobileBridgeEndpoint: '',
      updatedAt: 'saved-at',
    );
  }

  @override
  Future<List<DroneSummary>> fetchFleet() async {
    readCalls++;
    if (failReads) _fail('fetchFleet');
    return const [];
  }

  @override
  Future<TelemetrySnapshot> fetchTelemetry() async {
    readCalls++;
    if (failReads) _fail('fetchTelemetry');
    return const TelemetrySnapshot(
      activeDroneId: 'drone-1',
      missionState: 'bridge-online',
      routeProgressPct: 0,
      windMph: 0,
      temperatureF: 0,
      firePerimeterRisk: 'unknown',
      linkHealth: 'stable',
    );
  }

  @override
  Future<AnalyticsSnapshot> fetchAnalytics() async {
    readCalls++;
    if (failReads) _fail('fetchAnalytics');
    return mockAnalyticsSnapshot;
  }

  @override
  Future<MissionPreview> previewMission({
    required Scenario scenario,
    required SimulationLayout layout,
  }) async {
    readCalls++;
    if (failReads) _fail('previewMission');
    return MissionPreview(
      available: true,
      scenarioId: scenario.name,
      routePoints: const [],
      estimatedDurationMin: 1,
      maxAltitudeM: 120,
      riskLevel: 'low',
      warnings: const [],
      requiresConfirmation: true,
    );
  }

  @override
  Future<MissionConfirmResult> confirmMission(MissionPreview preview) async {
    writeCalls++;
    if (failWrites) _fail('confirmMission');
    return const MissionConfirmResult(
      accepted: true,
      blockedReason: null,
      missionId: 'mission-1',
      nextRequiredAction: 'Monitor',
    );
  }
}

void main() {
  const sampleRequest = DjiConnectionRequest(
    mode: 'cloud-api',
    ingestToken: 'secret',
    operatorLabel: '',
    cloudMqttHost: '127.0.0.1',
    cloudMqttPort: 1883,
    cloudMqttUsername: '',
    cloudMqttPassword: '',
    cloudMqttClientId: 'test-client',
    cloudApiAppId: '',
    cloudApiAppKey: '',
    cloudApiAppLicense: '',
    workspaceId: '',
  );

  group('ResilientDroneApiClient', () {
    test('read requests fall back when primary fails', () async {
      final primary = _RecordingDroneApiClient(failReads: true);
      final client = ResilientDroneApiClient(
        primary: primary,
        fallback: const UnavailableDroneApiClient(),
      );

      final status = await client.fetchStatus();

      expect(primary.readCalls, 1);
      expect(status.connection, 'not-configured');
    });

    test('saveConnectionConfig does not fall back when primary fails', () async {
      final primary = _RecordingDroneApiClient(failWrites: true);
      final client = ResilientDroneApiClient(
        primary: primary,
        fallback: const UnavailableDroneApiClient(),
      );

      await expectLater(
        client.saveConnectionConfig(sampleRequest),
        throwsA(isA<StateError>()),
      );
      expect(primary.writeCalls, 1);
    });

    test('generateConnectionToken does not fall back when primary fails', () async {
      final primary = _RecordingDroneApiClient(failWrites: true);
      final client = ResilientDroneApiClient(
        primary: primary,
        fallback: const UnavailableDroneApiClient(),
      );

      await expectLater(
        client.generateConnectionToken(),
        throwsA(isA<StateError>()),
      );
      expect(primary.writeCalls, 1);
    });

    test('confirmMission does not fall back when primary fails', () async {
      final primary = _RecordingDroneApiClient(failWrites: true);
      final client = ResilientDroneApiClient(
        primary: primary,
        fallback: const UnavailableDroneApiClient(),
      );

      await expectLater(
        client.confirmMission(
          MissionPreview(
            available: true,
            scenarioId: 'test',
            routePoints: const [],
            estimatedDurationMin: 1,
            maxAltitudeM: 120,
            riskLevel: 'low',
            warnings: const [],
            requiresConfirmation: true,
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(primary.writeCalls, 1);
    });

    test('write requests use primary when available', () async {
      final primary = _RecordingDroneApiClient();
      final client = ResilientDroneApiClient(
        primary: primary,
        fallback: const UnavailableDroneApiClient(),
      );

      final config = await client.saveConnectionConfig(sampleRequest);

      expect(primary.writeCalls, 1);
      expect(config.operatorLabel, 'saved');
    });
  });
}
