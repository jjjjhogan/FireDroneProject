import 'package:flutter/material.dart';

import 'aero_scout_shell.dart';
import '../services/drone_api_client.dart';

class AeroScoutApp extends StatelessWidget {
  const AeroScoutApp({
    this.droneClient = const MockDroneApiClient(),
    super.key,
  });

  final DroneApiClient droneClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroScout Command',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0c7c59),
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xffeef4f1),
        useMaterial3: true,
      ),
      home: AeroScoutShell(droneClient: droneClient),
    );
  }
}
