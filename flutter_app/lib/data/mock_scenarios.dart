import 'package:flutter/material.dart';

import '../mock/simulation_fixtures.dart';
import '../models/operations_enums.dart';
import '../models/route_point.dart';
import '../models/scenario.dart';
import '../models/simulation_layout.dart';
import '../models/thermal_front.dart';

const scenarios = mockScenarios;

String scenarioRiskLabel(Scenario scenario) {
  return switch (scenario.difficulty) {
    ScenarioDifficulty.basic => 'Low risk',
    ScenarioDifficulty.intermediate => 'Visibility',
    ScenarioDifficulty.advanced => 'High heat',
    ScenarioDifficulty.extreme => 'Wind',
  };
}

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
    20: SimulationLayout(
      routePoints: [
        RoutePoint(
          id: 'start',
          role: RoutePointRole.start,
          label: 'Desert pad',
          normalizedPosition: const Offset(0.16, 0.68),
          windMph: 24,
          humidityPct: 18,
          coveragePct: 61,
        ),
        RoutePoint(
          id: 'checkpoint-1',
          role: RoutePointRole.checkpoint,
          label: 'Arroyo crossing',
          normalizedPosition: const Offset(0.44, 0.46),
          windMph: 28,
          humidityPct: 16,
          coveragePct: 74,
        ),
        RoutePoint(
          id: 'end',
          role: RoutePointRole.end,
          label: 'Dust shelf',
          normalizedPosition: const Offset(0.84, 0.38),
          windMph: 25,
          humidityPct: 15,
          coveragePct: 83,
        ),
      ],
      thermalFront: ThermalFront(
        id: 'thermal-1',
        label: 'Monsoon gust front',
        normalizedPosition: const Offset(0.62, 0.54),
        windMph: 32,
        humidityPct: 22,
      ),
    ),
    24: SimulationLayout(
      routePoints: [
        RoutePoint(
          id: 'start',
          role: RoutePointRole.start,
          label: 'Range gate',
          normalizedPosition: const Offset(0.12, 0.58),
          windMph: 18,
          humidityPct: 42,
          coveragePct: 70,
        ),
        RoutePoint(
          id: 'checkpoint-1',
          role: RoutePointRole.checkpoint,
          label: 'Fence relay',
          normalizedPosition: const Offset(0.5, 0.5),
          windMph: 20,
          humidityPct: 39,
          coveragePct: 79,
        ),
        RoutePoint(
          id: 'end',
          role: RoutePointRole.end,
          label: 'Windward turn',
          normalizedPosition: const Offset(0.88, 0.44),
          windMph: 21,
          humidityPct: 36,
          coveragePct: 87,
        ),
      ],
      thermalFront: ThermalFront(
        id: 'thermal-1',
        label: 'Grass head fire',
        normalizedPosition: const Offset(0.7, 0.48),
        windMph: 23,
        humidityPct: 34,
      ),
    ),
    28: SimulationLayout(
      routePoints: [
        RoutePoint(
          id: 'start',
          role: RoutePointRole.start,
          label: 'Staging street',
          normalizedPosition: const Offset(0.18, 0.64),
          windMph: 10,
          humidityPct: 33,
          coveragePct: 68,
        ),
        RoutePoint(
          id: 'checkpoint-1',
          role: RoutePointRole.checkpoint,
          label: 'Structure line',
          normalizedPosition: const Offset(0.46, 0.4),
          windMph: 9,
          humidityPct: 31,
          coveragePct: 78,
        ),
        RoutePoint(
          id: 'end',
          role: RoutePointRole.end,
          label: 'Evac corridor',
          normalizedPosition: const Offset(0.8, 0.52),
          windMph: 11,
          humidityPct: 29,
          coveragePct: 89,
        ),
      ],
      thermalFront: ThermalFront(
        id: 'thermal-1',
        label: 'Ember shower zone',
        normalizedPosition: const Offset(0.58, 0.36),
        windMph: 14,
        humidityPct: 26,
      ),
    ),
    32: SimulationLayout(
      routePoints: [
        RoutePoint(
          id: 'start',
          role: RoutePointRole.start,
          label: 'Coastal inlet',
          normalizedPosition: const Offset(0.14, 0.6),
          windMph: 13,
          humidityPct: 74,
          coveragePct: 67,
        ),
        RoutePoint(
          id: 'checkpoint-1',
          role: RoutePointRole.checkpoint,
          label: 'Palmetto gap',
          normalizedPosition: const Offset(0.48, 0.36),
          windMph: 15,
          humidityPct: 78,
          coveragePct: 76,
        ),
        RoutePoint(
          id: 'end',
          role: RoutePointRole.end,
          label: 'Storm outflow',
          normalizedPosition: const Offset(0.84, 0.46),
          windMph: 17,
          humidityPct: 72,
          coveragePct: 88,
        ),
      ],
      thermalFront: ThermalFront(
        id: 'thermal-1',
        label: 'Humid fuel belt',
        normalizedPosition: const Offset(0.66, 0.5),
        windMph: 19,
        humidityPct: 81,
      ),
    ),
    36: SimulationLayout(
      routePoints: [
        RoutePoint(
          id: 'start',
          role: RoutePointRole.start,
          label: 'Trailhead pad',
          normalizedPosition: const Offset(0.16, 0.7),
          windMph: 16,
          humidityPct: 48,
          coveragePct: 63,
        ),
        RoutePoint(
          id: 'checkpoint-1',
          role: RoutePointRole.checkpoint,
          label: 'Talus bench',
          normalizedPosition: const Offset(0.42, 0.34),
          windMph: 18,
          humidityPct: 44,
          coveragePct: 75,
        ),
        RoutePoint(
          id: 'end',
          role: RoutePointRole.end,
          label: 'Snow line',
          normalizedPosition: const Offset(0.82, 0.28),
          windMph: 20,
          humidityPct: 41,
          coveragePct: 85,
        ),
      ],
      thermalFront: ThermalFront(
        id: 'thermal-1',
        label: 'Alpine smoke pool',
        normalizedPosition: const Offset(0.6, 0.42),
        windMph: 22,
        humidityPct: 38,
      ),
    ),
    40: SimulationLayout(
      routePoints: [
        RoutePoint(
          id: 'start',
          role: RoutePointRole.start,
          label: 'Levee pad',
          normalizedPosition: const Offset(0.12, 0.56),
          windMph: 7,
          humidityPct: 82,
          coveragePct: 65,
        ),
        RoutePoint(
          id: 'checkpoint-1',
          role: RoutePointRole.checkpoint,
          label: 'Peat channel',
          normalizedPosition: const Offset(0.46, 0.48),
          windMph: 6,
          humidityPct: 86,
          coveragePct: 74,
        ),
        RoutePoint(
          id: 'end',
          role: RoutePointRole.end,
          label: 'Mangrove edge',
          normalizedPosition: const Offset(0.86, 0.4),
          windMph: 8,
          humidityPct: 84,
          coveragePct: 86,
        ),
      ],
      thermalFront: ThermalFront(
        id: 'thermal-1',
        label: 'Peat smolder line',
        normalizedPosition: const Offset(0.64, 0.56),
        windMph: 9,
        humidityPct: 88,
      ),
    ),
  };

  return layouts[seed] ?? layouts[4]!;
}

SimulationLayout cloneLayout(SimulationLayout layout) {
  return SimulationLayout(
    routePoints: layout.routePoints.map((point) => point.copyWith()).toList(),
    thermalFront: layout.thermalFront.copyWith(),
  );
}
