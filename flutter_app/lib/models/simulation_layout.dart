import 'route_point.dart';
import 'thermal_front.dart';

enum SimulationRunState { idle, running, paused, complete }

class SimulationLayout {
  const SimulationLayout({
    required this.routePoints,
    required this.thermalFront,
  });

  final List<RoutePoint> routePoints;
  final ThermalFront thermalFront;
}

class SimulationTelemetry {
  const SimulationTelemetry({
    required this.label,
    required this.windMph,
    required this.humidityPct,
    required this.coveragePct,
    required this.progressPct,
    required this.routeCrossesFire,
  });

  final String label;
  final double windMph;
  final int humidityPct;
  final int coveragePct;
  final int progressPct;
  final bool routeCrossesFire;
}
