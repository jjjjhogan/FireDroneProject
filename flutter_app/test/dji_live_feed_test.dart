import 'package:flutter_test/flutter_test.dart';

import 'package:fire_drone_app/models/drone_connection.dart';
import 'package:fire_drone_app/services/dji_fleet_telemetry_adapter.dart';
import 'package:fire_drone_app/utils/map_geo.dart';

void main() {
  test('MapViewport centers on fleet positions', () {
    const fleet = [
      DroneSummary(
        id: 'dji-1',
        name: 'Lead',
        model: 'M30',
        connection: 'online',
        batteryPct: 80,
        signalPct: 90,
        lat: 37.21,
        lng: -119.54,
        altitudeM: 100,
        lastSeen: 'now',
        warnings: [],
      ),
      DroneSummary(
        id: 'dji-2',
        name: 'Scout',
        model: 'M30',
        connection: 'standby',
        batteryPct: 70,
        signalPct: 80,
        lat: 37.22,
        lng: -119.53,
        altitudeM: 90,
        lastSeen: 'now',
        warnings: [],
      ),
    ];

    final viewport = MapViewport.fromFleet(fleet);
    expect(viewport.centerLat, closeTo(37.215, 0.001));
    expect(viewport.centerLng, closeTo(-119.535, 0.001));
  });

  test('droneTelemetryFromDjiFleet maps bridge aircraft into dashboard models', () {
    const fleet = [
      DroneSummary(
        id: 'dji-thermal-01',
        name: 'DJI Thermal Lead',
        model: 'M30',
        connection: 'online',
        batteryPct: 82,
        signalPct: 94,
        lat: 37.2138,
        lng: -119.5414,
        altitudeM: 118,
        lastSeen: 'now',
        warnings: [],
      ),
    ];
    const telemetry = TelemetrySnapshot(
      activeDroneId: 'dji-thermal-01',
      missionState: 'device-online',
      routeProgressPct: 12,
      windMph: 14,
      temperatureF: 73,
      firePerimeterRisk: 'elevated',
      linkHealth: 'stable',
    );

    final mapped = droneTelemetryFromDjiFleet(
      fleet: fleet,
      telemetry: telemetry,
    );

    expect(mapped, hasLength(1));
    expect(mapped.first.droneId, 'dji-thermal-01');
    expect(mapped.first.lat, 37.2138);
    expect(mapped.first.batteryPercent, 82);
  });
}
