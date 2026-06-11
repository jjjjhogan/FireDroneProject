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
    expect(find.text('DJI-ready wildfire mission control'), findsWidgets);
    expect(find.text('DJI Link'), findsWidgets);
    expect(find.text('Mission Readiness'), findsWidgets);
    expect(find.text('Scenario Library'), findsWidgets);
    expect(find.text('Mission Scenarios'), findsOneWidget);
    expect(find.text('Open in Simulator'), findsNWidgets(4));
    expect(find.text('Min Mountains · California'), findsWidgets);

    await tester.tap(find.text('Coastal'));
    await tester.pump();

    expect(find.text('Santa Cruz Fog Belt'), findsWidgets);
    expect(find.text('Min Mountains · California'), findsNothing);

    await tester.tap(find.text('Live Simulator'));
    await tester.pumpAndSettle();

    expect(find.text('Live Simulator'), findsWidgets);
    expect(find.text('DJI Mission Preview'), findsOneWidget);
    expect(find.text('Run status'), findsOneWidget);
    expect(find.text('Start run'), findsOneWidget);
    expect(find.text('Confirm mission package'), findsOneWidget);
    expect(find.text('Command gate locked'), findsWidgets);
    expect(
      find.text('Fire zone is independent of patrol route'),
      findsOneWidget,
    );
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
    expect(find.text('DJI-ready wildfire mission control'), findsWidgets);
    expect(find.text('DJI Link'), findsWidgets);
    expect(find.text('Scenario Library'), findsWidgets);
    expect(find.text('Mission Scenarios'), findsOneWidget);
    expect(find.text('Min Mountains · California'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
