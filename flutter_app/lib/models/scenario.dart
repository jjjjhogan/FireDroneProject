import 'package:flutter/material.dart';

class Scenario {
  const Scenario({
    required this.name,
    required this.region,
    required this.description,
    required this.drones,
    required this.risk,
    required this.color,
    required this.seed,
    required this.image,
  });

  final String name;
  final String region;
  final String description;
  final int drones;
  final String risk;
  final Color color;
  final int seed;
  final String image;
}

const regions = ['All', 'Mountain', 'Coastal', 'Boreal', 'Plateau'];
