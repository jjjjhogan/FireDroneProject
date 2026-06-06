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
    expect(find.text('Scenario Library'), findsOneWidget);
    expect(find.text('Pre-built Scenarios'), findsOneWidget);
    expect(find.text('Min Mountains · California'), findsOneWidget);

    await tester.tap(find.text('Coastal'));
    await tester.pump();

    expect(find.text('Santa Cruz Fog Belt'), findsOneWidget);
    expect(find.text('Min Mountains · California'), findsNothing);

    await tester.tap(find.text('Live Simulator'));
    await tester.pump();

    expect(find.text('Live Simulator'), findsWidgets);
    expect(find.text('Active point'), findsOneWidget);
    expect(find.text('Drag points to adjust patrol route'), findsOneWidget);
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
    expect(find.text('Pre-built Scenarios'), findsOneWidget);
    expect(find.text('Min Mountains · California'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
