import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
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
      home: const HomeShell(),
    );
  }
}
