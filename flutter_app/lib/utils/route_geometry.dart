import 'dart:ui';

import '../models/route_point.dart';
import '../models/simulation_layout.dart';
import '../models/thermal_front.dart';

class RouteGeometry {
  static const _sampleCount = 24;

  static Offset positionAtProgress(List<RoutePoint> route, double progress) {
    if (route.isEmpty) {
      return Offset.zero;
    }
    if (route.length == 1) {
      return route.first.normalizedPosition;
    }

    final segments = _segmentLengths(route);
    final total = segments.fold<double>(0, (sum, length) => sum + length);
    if (total == 0) {
      return route.first.normalizedPosition;
    }

    var target = progress.clamp(0, 1) * total;
    for (var i = 0; i < segments.length; i++) {
      if (target <= segments[i]) {
        final t = segments[i] == 0 ? 0.0 : target / segments[i];
        return Offset.lerp(
          route[i].normalizedPosition,
          route[i + 1].normalizedPosition,
          t,
        )!;
      }
      target -= segments[i];
    }
    return route.last.normalizedPosition;
  }

  static SimulationTelemetry telemetryAtProgress({
    required List<RoutePoint> route,
    required ThermalFront thermalFront,
    required double progress,
    required bool routeCrossesFire,
  }) {
    if (route.isEmpty) {
      return SimulationTelemetry(
        label: 'No route',
        windMph: 0,
        humidityPct: 0,
        coveragePct: 0,
        progressPct: (progress * 100).round(),
        routeCrossesFire: routeCrossesFire,
      );
    }

    if (route.length == 1) {
      final point = route.first;
      return SimulationTelemetry(
        label: point.label,
        windMph: point.windMph,
        humidityPct: point.humidityPct,
        coveragePct: point.coveragePct,
        progressPct: (progress * 100).round(),
        routeCrossesFire: routeCrossesFire,
      );
    }

    final segments = _segmentLengths(route);
    final total = segments.fold<double>(0, (sum, length) => sum + length);
    final target = progress.clamp(0, 1) * total;
    var walked = 0.0;

    for (var i = 0; i < segments.length; i++) {
      if (target <= walked + segments[i]) {
        final t = segments[i] == 0 ? 0.0 : (target - walked) / segments[i];
        final from = route[i];
        final to = route[i + 1];
        return SimulationTelemetry(
          label: t < 0.5 ? from.label : to.label,
          windMph: lerpDouble(from.windMph, to.windMph, t)!,
          humidityPct: lerpDouble(
            from.humidityPct.toDouble(),
            to.humidityPct.toDouble(),
            t,
          )!.round(),
          coveragePct: lerpDouble(
            from.coveragePct.toDouble(),
            to.coveragePct.toDouble(),
            t,
          )!.round(),
          progressPct: (progress * 100).round(),
          routeCrossesFire: routeCrossesFire,
        );
      }
      walked += segments[i];
    }

    final end = route.last;
    return SimulationTelemetry(
      label: end.label,
      windMph: end.windMph,
      humidityPct: end.humidityPct,
      coveragePct: end.coveragePct,
      progressPct: (progress * 100).round(),
      routeCrossesFire: routeCrossesFire,
    );
  }

  static bool routeCrossesThermalFront(
    List<RoutePoint> route,
    ThermalFront thermalFront,
  ) {
    if (route.length < 2) {
      return false;
    }
    for (var i = 0; i < route.length - 1; i++) {
      if (segmentCrossesThermalFront(
        route[i].normalizedPosition,
        route[i + 1].normalizedPosition,
        thermalFront,
      )) {
        return true;
      }
    }
    return false;
  }

  static bool segmentCrossesThermalFront(
    Offset start,
    Offset end,
    ThermalFront thermalFront,
  ) {
    for (var i = 0; i <= _sampleCount; i++) {
      final t = i / _sampleCount;
      final sample = Offset.lerp(start, end, t)!;
      if (_pointInsideThermalFront(sample, thermalFront)) {
        return true;
      }
    }
    return false;
  }

  static bool _pointInsideThermalFront(
    Offset point,
    ThermalFront thermalFront,
  ) {
    final dx =
        (point.dx - thermalFront.normalizedPosition.dx) /
        thermalFront.normalizedRadiusX;
    final dy =
        (point.dy - thermalFront.normalizedPosition.dy) /
        thermalFront.normalizedRadiusY;
    return (dx * dx) + (dy * dy) <= 1;
  }

  static List<double> _segmentLengths(List<RoutePoint> route) {
    final lengths = <double>[];
    for (var i = 0; i < route.length - 1; i++) {
      lengths.add(
        (route[i + 1].normalizedPosition - route[i].normalizedPosition)
            .distance,
      );
    }
    return lengths;
  }
}
