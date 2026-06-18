import 'package:flutter/material.dart';

import 'operations_enums.dart';

export 'region_profile.dart'
    show regionProfiles, regionProfileFor, regionProfileForScenario, regions;

class Scenario {
  const Scenario({
    required this.scenarioId,
    required this.title,
    required this.region,
    required this.description,
    required this.difficulty,
    required this.simulatedDroneCount,
    required this.simulatedAlertCount,
    required this.tags,
    this.color = const Color(0xff315241),
    this.seed = 4,
    this.image = 'assets/images/scenario-mountain.jpg',
  });

  final String scenarioId;
  final String title;
  final String region;
  final String description;
  final ScenarioDifficulty difficulty;
  final int simulatedDroneCount;
  final int simulatedAlertCount;
  final List<String> tags;
  final Color color;
  final int seed;
  final String image;

  String get name => title;

  int get drones => simulatedDroneCount;

  String get risk => difficulty.label;
}
