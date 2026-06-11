import 'package:flutter/material.dart';

enum FwiLevel { high, med, low }

class Scenario {
  const Scenario({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.areaValue,
    required this.humidityValue,
    required this.windValue,
    required this.fwiLevel,
    required this.terrain,
    required this.imageGradient,
    this.image,
  });

  final String title;
  final String subtitle;
  final String description;
  final String areaValue;
  final String humidityValue;
  final String windValue;
  final FwiLevel fwiLevel;
  final String terrain;
  final List<Color> imageGradient;
  final String? image;
}

const mockScenarios = [
  Scenario(
    title: 'Min Mountains · Sichuan',
    subtitle: '1,840 km² · 22° avg slope',
    description:
        'Steep alpine terrain with mixed conifer forest. High fire weather index during dry season. Ideal for slope-aware patrol routing.',
    areaValue: '1,840 km²',
    humidityValue: '38%',
    windValue: '14 km/h',
    fwiLevel: FwiLevel.high,
    terrain: 'Mountain',
    imageGradient: [Color(0xFF4A6741), Color(0xFF8B9A6B)],
    image: 'assets/images/scenario-mountain.jpg',
  ),
  Scenario(
    title: 'Loess Plateau · Shaanxi',
    subtitle: '2,100 km² · 8° avg slope',
    description:
        'Gently rolling plateau with sparse grassland and scattered shrubs. Moderate fire risk with seasonal wind patterns.',
    areaValue: '2,100 km²',
    humidityValue: '42%',
    windValue: '18 km/h',
    fwiLevel: FwiLevel.med,
    terrain: 'Plateau',
    imageGradient: [Color(0xFFB8956A), Color(0xFFD4B896)],
    image: 'assets/images/scenario-plateau.jpg',
  ),
  Scenario(
    title: 'Coastal Range · Fujian',
    subtitle: '960 km² · 15° avg slope',
    description:
        'Humid subtropical coastal hills with dense bamboo and mixed forest. Lower ignition risk but complex terrain access.',
    areaValue: '960 km²',
    humidityValue: '65%',
    windValue: '9 km/h',
    fwiLevel: FwiLevel.low,
    terrain: 'Coastal',
    imageGradient: [Color(0xFF3D6B7A), Color(0xFF6B9AAA)],
    image: 'assets/images/scenario-coastal.jpg',
  ),
  Scenario(
    title: 'Daxing\'anling · Heilongjiang',
    subtitle: '3,200 km² · 5° avg slope',
    description:
        'Vast boreal forest with low relief. Cold-climate fire behavior simulation with extended detection windows.',
    areaValue: '3,200 km²',
    humidityValue: '55%',
    windValue: '11 km/h',
    fwiLevel: FwiLevel.low,
    terrain: 'Mixed',
    imageGradient: [Color(0xFF2E4A3E), Color(0xFF5A7A6A)],
    image: 'assets/images/scenario-boreal.jpg',
  ),
  Scenario(
    title: 'Qilian Mountains · Gansu',
    subtitle: '1,450 km² · 28° avg slope',
    description:
        'High-altitude mountain range with alpine meadows and rocky outcrops. Extreme slope gradients challenge drone navigation.',
    areaValue: '1,450 km²',
    humidityValue: '32%',
    windValue: '22 km/h',
    fwiLevel: FwiLevel.high,
    terrain: 'Mountain',
    imageGradient: [Color(0xFF5C6B73), Color(0xFF9AA5AD)],
    image: 'assets/images/scenario-mountain.jpg',
  ),
];
