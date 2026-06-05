import 'package:flutter/material.dart';

import 'screens/scenario_library_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AeroScoutApp());
}

class AeroScoutApp extends StatelessWidget {
  const AeroScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroScout',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const ScenarioLibraryScreen(),
    );
  }
}
