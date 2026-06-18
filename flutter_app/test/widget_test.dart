import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fire_drone_app/main.dart';
import 'package:fire_drone_app/services/operations_api_client.dart';

void main() {
  testWidgets('DJI mission control dashboard renders and filters scenarios', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const AeroScoutApp(operationsClient: TestOperationsApiClient()),
    );
    await tester.pumpAndSettle();

    expect(find.text('AeroScout Command'), findsWidgets);
    expect(find.text('OFFICIAL WILDFIRE OPERATIONS'), findsOneWidget);
    expect(find.text('Official/Public-Safety Prototype'), findsWidgets);
    expect(find.text('System Mode'), findsOneWidget);
    expect(find.text('Simulation Mode'), findsWidgets);
    expect(find.text('Real Hardware Disabled'), findsWidgets);
    expect(find.text('Not production ready'), findsWidgets);
    expect(find.text('Active Drones'), findsOneWidget);
    expect(find.text('Active Detections'), findsOneWidget);
    expect(find.text('Confirmed / Unconfirmed'), findsOneWidget);
    expect(find.text('Safety Lock'), findsOneWidget);
    expect(find.text('Data Source'), findsOneWidget);
    expect(find.text('MISSION OVERVIEW'), findsWidgets);
    expect(find.text('DRONE TELEMETRY'), findsOneWidget);
    expect(find.text('OPERATIONS MAP'), findsNothing);
    expect(find.text('FIRE / SMOKE ALERTS'), findsOneWidget);
    expect(find.text('Confidence'), findsWidgets);
    expect(find.text('Severity'), findsWidgets);
    expect(find.text('SAFETY-GATED COMMANDS'), findsOneWidget);
    expect(find.text('Operator confirmation'), findsWidgets);
    expect(find.text('Remote ID checklist'), findsWidgets);
    expect(find.text('Airspace approval'), findsWidgets);
    expect(find.text('Placeholder'), findsNothing);
    expect(find.text('AUDIT LOG'), findsOneWidget);
    expect(find.text('Emergency Stop'), findsOneWidget);
    expect(find.text('Canyon Ridge Fire'), findsWidgets);

    await tester.ensureVisible(find.text('PLANNING MAP'));
    await tester.pumpAndSettle();

    expect(find.text('PLANNING MAP'), findsOneWidget);
    expect(find.text('Interactive GIS map'), findsOneWidget);
    expect(find.text('Satellite imagery'), findsWidgets);
    expect(find.text('Street map'), findsNothing);
    expect(find.text('OpenStreetMap tiles'), findsNothing);
    expect(find.textContaining('Free API'), findsNothing);
    expect(find.text('GEOFENCE LAYER'), findsNothing);
    expect(find.text('Geofence on'), findsOneWidget);
    expect(find.textContaining('GIS layer'), findsOneWidget);
    expect(find.text('Zoom 13'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-zoom-in')));
    await tester.pumpAndSettle();
    expect(find.text('Zoom 14'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-toggle-geofence')));
    await tester.pumpAndSettle();
    expect(find.text('Geofence hidden'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-source-info')));
    await tester.pumpAndSettle();
    expect(find.text('GEOFENCE LAYER'), findsOneWidget);
    expect(find.text('Mission geofence'), findsWidgets);
    expect(find.text('Route source: backend-mission-gis'), findsOneWidget);
    expect(find.text('Viewport: Backend bounds'), findsOneWidget);
    expect(find.text('Route points: 5'), findsOneWidget);
    expect(find.text('Map alerts: 3'), findsOneWidget);
    expect(find.textContaining('Attribution: Powered by Esri'), findsOneWidget);
    expect(find.text('Tile policy: Development imagery'), findsOneWidget);
    expect(find.textContaining('Map source:'), findsOneWidget);

    expect(find.text('CONNECTED DRONES'), findsOneWidget);
    expect(find.text('DJI connector not configured'), findsWidgets);
    expect(find.text('0 / 0 Online'), findsOneWidget);
    expect(find.text('No real DJI aircraft connected'), findsWidgets);
    expect(find.text('TELEMETRY LINK'), findsOneWidget);
    expect(find.text('FLEET HEALTH'), findsOneWidget);
    expect(find.text('DJI Link'), findsWidgets);
    expect(find.text('Connect DJI Drone'), findsOneWidget);
    expect(find.text('Connect DJI'), findsOneWidget);
    expect(find.text('Backend Persistence'), findsOneWidget);
    expect(find.text('Map Provider'), findsOneWidget);
    expect(find.text('START MISSION'), findsWidgets);
    expect(find.text('Scenario Library'), findsOneWidget);
    expect(find.text('About & Safety'), findsOneWidget);

    await tester.ensureVisible(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Alert confirmed'), findsOneWidget);
    expect(find.textContaining('Confirmed alert'), findsWidgets);

    await tester.ensureVisible(find.text('I confirm this simulated command'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I confirm this simulated command'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Arm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arm'));
    await tester.pumpAndSettle();
    expect(find.text('Simulated command accepted'), findsWidgets);

    await tester.ensureVisible(find.text('Connect DJI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect DJI'));
    await tester.pumpAndSettle();

    expect(find.text('Backend ingest token'), findsOneWidget);
    expect(find.text('Generate token'), findsOneWidget);
    expect(find.text('Cloud API'), findsOneWidget);
    expect(find.text('Mobile SDK'), findsOneWidget);
    expect(find.text('Advanced settings'), findsOneWidget);
    expect(find.text('Cloud API App ID'), findsNothing);
    expect(find.text('Cloud API App License'), findsNothing);

    await tester.tap(find.text('Advanced settings'));
    await tester.pumpAndSettle();

    expect(find.text('Cloud API App ID'), findsOneWidget);
    expect(find.text('Cloud API App License'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scenario Library'));
    await tester.pumpAndSettle();

    expect(find.text('Mission Scenarios'), findsOneWidget);
    expect(find.text('Selected Scenario'), findsOneWidget);
    expect(find.text('Simulated mission planning package'), findsOneWidget);
    expect(find.text('Open Selected Scenario'), findsOneWidget);
    expect(find.text('Open in Simulator'), findsNWidgets(10));
    expect(find.text('San Bernardino Mountain Ridge'), findsWidgets);
    expect(find.text('Search scenarios'), findsOneWidget);
    expect(find.text('6 drones'), findsWidgets);
    expect(find.text('2 alerts'), findsWidgets);

    final coastalFilter = find.widgetWithText(ChoiceChip, 'Coastal');
    await tester.ensureVisible(coastalFilter);
    await tester.pumpAndSettle();
    await tester.tap(coastalFilter);
    await tester.pumpAndSettle();

    expect(find.text('Santa Cruz Fog Belt'), findsWidgets);
    expect(find.text('San Bernardino Mountain Ridge'), findsNothing);

    await tester.tap(find.text('Live Simulator'));
    await tester.pumpAndSettle();

    expect(find.text('Canyon Ridge Fire'), findsWidgets);
    expect(find.text('START MISSION'), findsWidgets);

    await tester.tap(find.text('About & Safety'));
    await tester.pumpAndSettle();

    expect(find.text('About & Safety'), findsWidgets);
    expect(find.text('Official/Public-Safety Prototype'), findsWidgets);
    expect(find.text('Simulation Mode'), findsWidgets);
    expect(find.text('Real Hardware Disabled'), findsWidgets);
    expect(find.text('Not production ready'), findsWidgets);
    expect(find.text('GitHub Integration References'), findsOneWidget);
    expect(find.text('Future Integration Roadmap'), findsOneWidget);
    expect(find.text('PX4/MAVLink'), findsOneWidget);
  });

  testWidgets('AeroScout scenario library fits compact mobile width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const AeroScoutApp(operationsClient: TestOperationsApiClient()),
    );
    await tester.pumpAndSettle();

    expect(find.text('AeroScout Command'), findsWidgets);
    expect(find.text('Canyon Ridge Fire'), findsWidgets);
    expect(find.text('CONNECTED DRONES'), findsWidgets);
    expect(find.text('DJI connector not configured'), findsWidgets);
    expect(find.text('No real DJI aircraft connected'), findsWidgets);
    expect(find.text('OPERATIONS MAP'), findsNothing);
    expect(find.text('PLANNING MAP'), findsOneWidget);
    expect(find.text('Interactive GIS map'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-search-field')), findsOneWidget);
    expect(find.text('Place'), findsOneWidget);
    expect(find.text('GEOFENCE LAYER'), findsNothing);
    final searchButtonRect = tester.getRect(
      find.byKey(const ValueKey('map-search-button')),
    );
    final droneToggleRect = tester.getRect(
      find.byKey(const ValueKey('map-toggle-drone')),
    );
    expect(searchButtonRect.overlaps(droneToggleRect), isFalse);
    expect(tester.getTopLeft(find.text('PLANNING MAP')).dy, lessThan(360));
    expect(find.text('DJI Link'), findsWidgets);
    expect(find.text('START MISSION'), findsWidgets);
    expect(find.text('SAFETY-GATED COMMANDS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('planning map searches real places through free map API', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const AeroScoutApp(operationsClient: TestOperationsApiClient()),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('PLANNING MAP'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-search-field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('map-search-field')),
      'Los Padres National Forest',
    );
    await tester.tap(find.byKey(const ValueKey('map-search-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Free API'), findsNothing);
    expect(
      find.text('Los Padres National Forest, California, United States'),
      findsOneWidget,
    );
    expect(
      find.text('Search focus: Los Padres National Forest'),
      findsOneWidget,
    );
  });
}

class TestOperationsApiClient extends UnavailableOperationsApiClient {
  const TestOperationsApiClient();

  @override
  Future<MapProviderConfig> fetchMapConfig() async {
    return MapProviderConfig.fromJson(const {
      'provider': 'openstreetmap',
      'tileUrlTemplate': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'attribution': 'OpenStreetMap contributors',
      'configured': true,
      'requiresApiKey': false,
      'defaultBasemap': 'satellite',
      'basemaps': [
        {
          'id': 'satellite',
          'label': 'Satellite imagery',
          'provider': 'arcgis-world-imagery',
          'tileUrlTemplate':
              'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          'attribution':
              'Powered by Esri | Sources: Esri, Maxar, Earthstar Geographics, and the GIS User Community',
          'configured': true,
          'requiresApiKey': false,
          'policy': {
            'status': 'development-imagery',
            'productionReady': false,
            'message':
                'ArcGIS World Imagery gives a realistic satellite basemap for development previews.',
          },
        },
        {
          'id': 'streets',
          'label': 'Street map',
          'provider': 'openstreetmap',
          'tileUrlTemplate': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          'attribution': 'OpenStreetMap contributors',
          'configured': true,
          'requiresApiKey': false,
          'policy': {
            'status': 'development-only',
            'productionReady': false,
            'message':
                'Public OpenStreetMap tile servers are for development previews; use a dedicated provider for production.',
          },
        },
      ],
      'searchProvider': 'nominatim',
      'center': {'lat': 34.6234, 'lng': -119.7196, 'zoom': 13},
      'tilePolicy': {
        'status': 'development-only',
        'productionReady': false,
        'message':
            'Public OpenStreetMap tile servers are for development previews; use a dedicated provider for production.',
      },
    });
  }

  @override
  Future<MapMissionLayer> fetchMapMissionLayer() async {
    return MapMissionLayer.fromJson(const {
      'source': 'backend-mission-gis',
      'updatedAt': '2026-06-12T18:00:00+00:00',
      'bounds': {
        'source': 'computed-from-map-layers',
        'north': 34.6376,
        'south': 34.6098,
        'east': -119.7104,
        'west': -119.7444,
      },
      'route': {
        'id': 'canyon-ridge-route',
        'name': 'Canyon Ridge mission route',
        'source': 'incident-mission-planner',
        'points': [
          {
            'label': 'LZ',
            'lat': 34.6368,
            'lng': -119.7334,
            'altitudeM': 92,
            'action': 'Launch and link check',
          },
          {
            'label': 'WP1',
            'lat': 34.6282,
            'lng': -119.7104,
            'altitudeM': 118,
            'action': 'Thermal scan north ridge',
          },
          {
            'label': 'WP2',
            'lat': 34.6098,
            'lng': -119.7192,
            'altitudeM': 122,
            'action': 'Inspect southern perimeter',
          },
          {
            'label': 'WP3',
            'lat': 34.6214,
            'lng': -119.7444,
            'altitudeM': 110,
            'action': 'Check containment line',
          },
          {
            'label': 'RTL',
            'lat': 34.6368,
            'lng': -119.7334,
            'altitudeM': 92,
            'action': 'Return to launch',
          },
        ],
      },
      'alerts': [
        {
          'id': 'thermal-hotspot-north',
          'label': 'Thermal hotspot north',
          'type': 'thermal',
          'severity': 'high',
          'confidence': 0.87,
          'lat': 34.6308,
          'lng': -119.7294,
          'source': 'incident-gis-seed',
          'status': 'Unconfirmed',
        },
        {
          'id': 'smoke-column-center',
          'label': 'Smoke column center',
          'type': 'smoke',
          'severity': 'medium',
          'confidence': 0.78,
          'lat': 34.6234,
          'lng': -119.7196,
          'source': 'incident-gis-seed',
          'status': 'Unconfirmed',
        },
        {
          'id': 'fire-edge-south',
          'label': 'Fire edge south',
          'type': 'fire',
          'severity': 'critical',
          'confidence': 0.91,
          'lat': 34.6162,
          'lng': -119.7336,
          'source': 'incident-gis-seed',
          'status': 'Unconfirmed',
        },
      ],
      'drones': [
        {
          'id': 'planned-launch-zone',
          'name': 'Planned launch zone',
          'model': 'Operator-selected aircraft',
          'connection': 'planned',
          'live': false,
          'lat': 34.6376,
          'lng': -119.7340,
          'altitudeM': 0,
          'source': 'mission-planning',
          'warnings': ['No live aircraft position has been ingested.'],
        },
      ],
    });
  }

  @override
  Future<List<MapSearchResult>> searchMap(String query) async {
    return const [
      MapSearchResult(
        id: 'relation/396488',
        displayName: 'Los Padres National Forest, California, United States',
        lat: 34.6761,
        lng: -119.9028,
        category: 'boundary',
        type: 'protected_area',
        boundingBox: MapBounds(
          source: 'search-result',
          north: 35.8027,
          south: 33.9432,
          east: -118.4982,
          west: -121.7906,
        ),
      ),
    ];
  }
}
