import 'package:flutter/material.dart';

import '../models/scenario.dart';
import '../models/simulation_point.dart';

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

List<SimulationPoint> defaultPointsForScenario(Scenario scenario) {
  final layouts = <int, List<SimulationPoint>>{
    4: [
      SimulationPoint(
        id: 'drone-1',
        type: SimulationPointType.drone,
        label: 'Scout Alpha',
        normalizedPosition: const Offset(0.14, 0.68),
        windMph: 14,
        humidityPct: 38,
        coveragePct: 72,
      ),
      SimulationPoint(
        id: 'checkpoint-1',
        type: SimulationPointType.checkpoint,
        label: 'Ridge checkpoint',
        normalizedPosition: const Offset(0.38, 0.42),
        windMph: 11,
        humidityPct: 41,
        coveragePct: 81,
      ),
      SimulationPoint(
        id: 'hazard-1',
        type: SimulationPointType.hazard,
        label: 'Thermal front',
        normalizedPosition: const Offset(0.64, 0.52),
        windMph: 18,
        humidityPct: 29,
        coveragePct: 63,
      ),
      SimulationPoint(
        id: 'drone-2',
        type: SimulationPointType.drone,
        label: 'Relay Beta',
        normalizedPosition: const Offset(0.86, 0.36),
        windMph: 12,
        humidityPct: 44,
        coveragePct: 88,
      ),
    ],
    8: [
      SimulationPoint(
        id: 'drone-1',
        type: SimulationPointType.drone,
        label: 'Coastal scout',
        normalizedPosition: const Offset(0.18, 0.58),
        windMph: 9,
        humidityPct: 62,
        coveragePct: 76,
      ),
      SimulationPoint(
        id: 'checkpoint-1',
        type: SimulationPointType.checkpoint,
        label: 'Fog line',
        normalizedPosition: const Offset(0.46, 0.34),
        windMph: 7,
        humidityPct: 71,
        coveragePct: 84,
      ),
      SimulationPoint(
        id: 'hazard-1',
        type: SimulationPointType.hazard,
        label: 'Marine layer',
        normalizedPosition: const Offset(0.72, 0.48),
        windMph: 10,
        humidityPct: 78,
        coveragePct: 58,
      ),
    ],
    12: [
      SimulationPoint(
        id: 'drone-1',
        type: SimulationPointType.drone,
        label: 'Perimeter scout',
        normalizedPosition: const Offset(0.12, 0.44),
        windMph: 8,
        humidityPct: 55,
        coveragePct: 69,
      ),
      SimulationPoint(
        id: 'checkpoint-1',
        type: SimulationPointType.checkpoint,
        label: 'Canopy gap',
        normalizedPosition: const Offset(0.42, 0.62),
        windMph: 6,
        humidityPct: 58,
        coveragePct: 77,
      ),
      SimulationPoint(
        id: 'drone-2',
        type: SimulationPointType.drone,
        label: 'Relay unit',
        normalizedPosition: const Offset(0.78, 0.28),
        windMph: 9,
        humidityPct: 51,
        coveragePct: 91,
      ),
    ],
    16: [
      SimulationPoint(
        id: 'drone-1',
        type: SimulationPointType.drone,
        label: 'Mesa scout',
        normalizedPosition: const Offset(0.16, 0.72),
        windMph: 22,
        humidityPct: 31,
        coveragePct: 64,
      ),
      SimulationPoint(
        id: 'hazard-1',
        type: SimulationPointType.hazard,
        label: 'Wind corridor',
        normalizedPosition: const Offset(0.52, 0.46),
        windMph: 26,
        humidityPct: 27,
        coveragePct: 55,
      ),
      SimulationPoint(
        id: 'checkpoint-1',
        type: SimulationPointType.checkpoint,
        label: 'Canyon relay',
        normalizedPosition: const Offset(0.84, 0.38),
        windMph: 19,
        humidityPct: 34,
        coveragePct: 82,
      ),
    ],
  };

  return layouts[scenario.seed] ?? layouts[4]!;
}
