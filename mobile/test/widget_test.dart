import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fire_drone/main.dart';

void main() {
  testWidgets('Scenario library screen renders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const AeroScoutApp());

    expect(find.text('Scenario Library'), findsOneWidget);
    expect(find.text('Pre-built Scenarios'), findsOneWidget);
    expect(find.text('AeroScout'), findsOneWidget);
    expect(find.text('Build Custom Scenario'), findsOneWidget);
  });
}
