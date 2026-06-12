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
    expect(find.text('Canyon Ridge Fire'), findsWidgets);
    expect(find.text('PLANNING MAP'), findsOneWidget);
    expect(find.text('CONNECTED DRONES'), findsOneWidget);
    expect(find.text('DJI connector not configured'), findsWidgets);
    expect(find.text('0 / 0 Online'), findsOneWidget);
    expect(find.text('No real DJI aircraft connected'), findsWidgets);
    expect(find.text('TELEMETRY LINK'), findsOneWidget);
    expect(find.text('FLEET HEALTH'), findsOneWidget);
    expect(find.text('DJI Link'), findsWidgets);
    expect(find.text('START MISSION'), findsWidgets);
    expect(find.text('Scenario Library'), findsOneWidget);

    await tester.tap(find.text('Scenario Library'));
    await tester.pumpAndSettle();

    expect(find.text('Mission Scenarios'), findsOneWidget);
    expect(find.text('Open in Simulator'), findsNWidgets(4));
    expect(find.text('Min Mountains · California'), findsWidgets);

    await tester.tap(find.text('Coastal'));
    await tester.pump();

    expect(find.text('Santa Cruz Fog Belt'), findsWidgets);
    expect(find.text('Min Mountains · California'), findsNothing);

    await tester.tap(find.text('Live Simulator'));
    await tester.pumpAndSettle();

    expect(find.text('Canyon Ridge Fire'), findsWidgets);
    expect(find.text('START MISSION'), findsWidgets);
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
    expect(tester.takeException(), isNull);
  });
}
