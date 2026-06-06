import 'package:flutter/material.dart';

import 'aero_scout_shell.dart';

class AeroScoutApp extends StatelessWidget {
  const AeroScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroScout Sim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0c7c59),
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const AeroScoutShell(),
    );
  }
}
