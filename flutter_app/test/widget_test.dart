import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fire_drone_app/main.dart';

void main() {
  testWidgets('AeroScout dashboard renders and filters scenarios', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const AeroScoutApp());

    expect(find.text('AeroScout Sim'), findsWidgets);
    expect(find.text('Scenario Planner'), findsOneWidget);
    expect(find.text('Scenario Library'), findsWidgets);
    expect(find.text('Drone Configuration'), findsOneWidget);
    expect(find.text('Readiness & Coverage'), findsOneWidget);
    expect(find.text('Min Mountains · California'), findsWidgets);

    await tester.tap(find.text('Coastal'));
    await tester.pump();

    expect(find.text('Santa Cruz Fog Belt'), findsWidgets);
    expect(find.text('Min Mountains · California'), findsNothing);

    await tester.tap(find.text('Live Simulator'));
    await tester.pump();

    expect(find.text('Live Simulator'), findsWidgets);
    expect(find.text('Run #2417'), findsOneWidget);
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
    await tester.pump();

    expect(find.text('AeroScout Sim'), findsWidgets);
    expect(find.text('Scenario Planner'), findsOneWidget);
    expect(find.text('Scenario Library'), findsWidgets);
    expect(find.text('Readiness & Coverage'), findsOneWidget);
    expect(find.text('Min Mountains · California'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
