import 'package:flutter/material.dart';

import '../models/route_point.dart';
import '../models/scenario.dart';
import '../models/simulation_layout.dart';
import '../models/thermal_front.dart';

const scenarios = [
  Scenario(
    name: 'Min Mountains · California',
    region: 'Mountain',
    description:
        'Steep ridgeline scan with smoke-obscured valleys and narrow return corridors.',
    drones: 6,
    risk: 'High heat',
    color: Color(0xff315241),
    seed: 4,
    image: 'assets/images/scenario-mountain.jpg',
  ),
  Scenario(
    name: 'Santa Cruz Fog Belt',
    region: 'Coastal',
    description:
        'Low ceiling patrol that balances thermal locks against shifting marine fog.',
    drones: 5,
    risk: 'Visibility',
    color: Color(0xff2f7d9a),
    seed: 8,
    image: 'assets/images/scenario-coastal.jpg',
  ),
  Scenario(
    name: 'Yukon Boreal Line',
    region: 'Boreal',
    description:
        'Long-range perimeter sweep through dense conifer canopy and cold uplifts.',
    drones: 8,
    risk: 'Canopy',
    color: Color(0xff0e7656),
    seed: 12,
    image: 'assets/images/scenario-boreal.jpg',
  ),
  Scenario(
    name: 'Colorado Plateau Watch',
    region: 'Plateau',
    description:
        'Mesa-to-canyon mapping with relay handoffs and strong afternoon winds.',
    drones: 7,
    risk: 'Wind',
    color: Color(0xffc2542d),
    seed: 16,
    image: 'assets/images/scenario-plateau.jpg',
  ),
];

SimulationLayout defaultLayoutForScenario(Scenario scenario) {
  return defaultLayoutForSeed(scenario.seed);
}

SimulationLayout defaultLayoutForSeed(int seed) {
  final layouts = <int, SimulationLayout>{
    4: SimulationLayout(
      routePoints: [
        RoutePoint(
          id: 'start',
          role: RoutePointRole.start,
          label: 'Launch pad',
          normalizedPosition: const Offset(0.12, 0.72),
          windMph: 14,
          humidityPct: 38,
          coveragePct: 72,
        ),
        RoutePoint(
          id: 'checkpoint-1',
          role: RoutePointRole.checkpoint,
          label: 'Ridge checkpoint',
          normalizedPosition: const Offset(0.38, 0.42),
          windMph: 11,
          humidityPct: 41,
          coveragePct: 81,
        ),
        RoutePoint(
          id: 'end',
          role: RoutePointRole.end,
          label: 'Return base',
          normalizedPosition: const Offset(0.88, 0.34),
          windMph: 12,
          humidityPct: 44,
          coveragePct: 88,
        ),
      ],
      thermalFront: ThermalFront(
        id: 'thermal-1',
        label: 'Thermal front',
        normalizedPosition: const Offset(0.64, 0.52),
        windMph: 18,
        humidityPct: 29,
      ),
    ),
    8: SimulationLayout(
      routePoints: [
        RoutePoint(
          id: 'start',
          role: RoutePointRole.start,
          label: 'Coastal launch',
          normalizedPosition: const Offset(0.14, 0.62),
          windMph: 9,
          humidityPct: 62,
          coveragePct: 76,
        ),
        RoutePoint(
          id: 'checkpoint-1',
          role: RoutePointRole.checkpoint,
          label: 'Fog line',
          normalizedPosition: const Offset(0.46, 0.34),
          windMph: 7,
          humidityPct: 71,
          coveragePct: 84,
        ),
        RoutePoint(
          id: 'end',
          role: RoutePointRole.end,
          label: 'Harbor return',
          normalizedPosition: const Offset(0.82, 0.58),
          windMph: 8,
          humidityPct: 68,
          coveragePct: 90,
        ),
      ],
      thermalFront: ThermalFront(
        id: 'thermal-1',
        label: 'Marine layer',
        normalizedPosition: const Offset(0.58, 0.48),
        windMph: 10,
        humidityPct: 78,
      ),
    ),
    12: SimulationLayout(
      routePoints: [
        RoutePoint(
          id: 'start',
          role: RoutePointRole.start,
          label: 'Perimeter start',
          normalizedPosition: const Offset(0.1, 0.44),
          windMph: 8,
          humidityPct: 55,
          coveragePct: 69,
        ),
        RoutePoint(
          id: 'checkpoint-1',
          role: RoutePointRole.checkpoint,
          label: 'Canopy gap',
          normalizedPosition: const Offset(0.42, 0.62),
          windMph: 6,
          humidityPct: 58,
          coveragePct: 77,
        ),
        RoutePoint(
          id: 'end',
          role: RoutePointRole.end,
          label: 'North relay',
          normalizedPosition: const Offset(0.82, 0.26),
          windMph: 9,
          humidityPct: 51,
          coveragePct: 91,
        ),
      ],
      thermalFront: ThermalFront(
        id: 'thermal-1',
        label: 'Smolder patch',
        normalizedPosition: const Offset(0.68, 0.38),
        windMph: 11,
        humidityPct: 42,
      ),
    ),
    16: SimulationLayout(
      routePoints: [
        RoutePoint(
          id: 'start',
          role: RoutePointRole.start,
          label: 'Mesa launch',
          normalizedPosition: const Offset(0.14, 0.74),
          windMph: 22,
          humidityPct: 31,
          coveragePct: 64,
        ),
        RoutePoint(
          id: 'checkpoint-1',
          role: RoutePointRole.checkpoint,
          label: 'Canyon relay',
          normalizedPosition: const Offset(0.48, 0.38),
          windMph: 19,
          humidityPct: 34,
          coveragePct: 82,
        ),
        RoutePoint(
          id: 'end',
          role: RoutePointRole.end,
          label: 'Plateau end',
          normalizedPosition: const Offset(0.86, 0.32),
          windMph: 20,
          humidityPct: 30,
          coveragePct: 86,
        ),
      ],
      thermalFront: ThermalFront(
        id: 'thermal-1',
        label: 'Wind corridor fire',
        normalizedPosition: const Offset(0.36, 0.56),
        windMph: 26,
        humidityPct: 27,
      ),
    ),
  };

  return layouts[seed] ?? layouts[4]!;
}

SimulationLayout cloneLayout(SimulationLayout layout) {
  return SimulationLayout(
    routePoints: layout.routePoints
        .map((point) => point.copyWith())
        .toList(),
    thermalFront: layout.thermalFront.copyWith(),
  );
}
