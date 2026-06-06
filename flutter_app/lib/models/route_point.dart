import 'package:flutter/material.dart';

enum RoutePointRole { start, checkpoint, end }

class RoutePoint {
  RoutePoint({
    required this.id,
    required this.role,
    required this.label,
    required this.normalizedPosition,
    required this.windMph,
    required this.humidityPct,
    required this.coveragePct,
  });

  final String id;
  final RoutePointRole role;
  final String label;
  Offset normalizedPosition;
  final double windMph;
  final int humidityPct;
  final int coveragePct;

  RoutePoint copyWith({Offset? normalizedPosition}) {
    return RoutePoint(
      id: id,
      role: role,
      label: label,
      normalizedPosition: normalizedPosition ?? this.normalizedPosition,
      windMph: windMph,
      humidityPct: humidityPct,
      coveragePct: coveragePct,
    );
  }
}
