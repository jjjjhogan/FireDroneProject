import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/drone_connection.dart';
import '../models/drone_telemetry.dart';
import '../models/scenario.dart';
import '../models/simulation_layout.dart';
import 'dji_fleet_telemetry_adapter.dart';
import 'drone_api_client.dart';

class DjiLiveFeed extends ChangeNotifier {
  DjiLiveFeed(this.client);

  final DroneApiClient client;
  Timer? _pollTimer;

  DjiStatus? status;
  List<DroneSummary> fleet = const [];
  TelemetrySnapshot telemetry = const TelemetrySnapshot(
    activeDroneId: 'unknown',
    missionState: 'not-configured',
    routeProgressPct: 0,
    windMph: 0,
    temperatureF: 0,
    firePerimeterRisk: 'unknown',
    linkHealth: 'not-configured',
  );
  MissionPreview? preview;
  Object? lastError;
  bool isRefreshing = false;

  bool get hasLiveFleet => status?.liveData == true && fleet.isNotEmpty;

  List<DroneTelemetry> get liveDroneTelemetry {
    if (!hasLiveFleet) {
      return const [];
    }
    return droneTelemetryFromDjiFleet(fleet: fleet, telemetry: telemetry);
  }

  double get readinessScore =>
      missionReadinessScore(status: status, fleet: fleet);

  Future<void> refreshAll({
    required Scenario scenario,
    required SimulationLayout layout,
  }) async {
    isRefreshing = true;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>([
        client.fetchStatus(),
        client.fetchFleet(),
        client.fetchTelemetry(),
        client.previewMission(scenario: scenario, layout: layout),
      ]);
      status = results[0]! as DjiStatus;
      fleet = results[1]! as List<DroneSummary>;
      telemetry = results[2]! as TelemetrySnapshot;
      preview = results[3] as MissionPreview?;
      lastError = null;
    } catch (error) {
      lastError = error;
    } finally {
      isRefreshing = false;
      notifyListeners();
      _syncPolling();
    }
  }

  Future<void> refreshTelemetry() async {
    if (isRefreshing) {
      return;
    }

    try {
      final results = await Future.wait<Object?>([
        client.fetchStatus(),
        client.fetchFleet(),
        client.fetchTelemetry(),
      ]);
      status = results[0]! as DjiStatus;
      fleet = results[1]! as List<DroneSummary>;
      telemetry = results[2]! as TelemetrySnapshot;
      lastError = null;
      notifyListeners();
      _syncPolling();
    } catch (error) {
      lastError = error;
      notifyListeners();
    }
  }

  void _syncPolling() {
    if (_shouldPoll) {
      _pollTimer ??= Timer.periodic(
        const Duration(seconds: 4),
        (_) => refreshTelemetry(),
      );
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  bool get _shouldPoll {
    final connection = status?.connection;
    return status?.ingestConfigured == true ||
        status?.liveData == true ||
        connection == 'waiting-for-bridge' ||
        connection == 'bridge-online' ||
        connection == 'bridge-stale' ||
        connection == 'configured';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
