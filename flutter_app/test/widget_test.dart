import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fire_drone_app/main.dart';

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

    await tester.pumpWidget(const AeroScoutApp());
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
    expect(find.text('OPERATIONS MAP'), findsOneWidget);
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
    expect(find.text('PLANNING MAP'), findsOneWidget);
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
    expect(find.text('Open in Simulator'), findsNWidgets(4));
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

    await tester.pumpWidget(const AeroScoutApp());
    await tester.pumpAndSettle();

    expect(find.text('AeroScout Command'), findsWidgets);
    expect(find.text('Canyon Ridge Fire'), findsWidgets);
    expect(find.text('CONNECTED DRONES'), findsWidgets);
    expect(find.text('DJI connector not configured'), findsWidgets);
    expect(find.text('No real DJI aircraft connected'), findsWidgets);
    expect(find.text('DJI Link'), findsWidgets);
    expect(find.text('START MISSION'), findsWidgets);
    expect(find.text('SAFETY-GATED COMMANDS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
