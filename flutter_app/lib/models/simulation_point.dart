import 'package:flutter/material.dart';

enum SimulationPointType { drone, checkpoint, hazard }

class SimulationPoint {
  SimulationPoint({
    required this.id,
    required this.type,
    required this.label,
    required this.normalizedPosition,
    required this.windMph,
    required this.humidityPct,
    required this.coveragePct,
  });

  final String id;
  final SimulationPointType type;
  final String label;
  Offset normalizedPosition;
  final double windMph;
  final int humidityPct;
  final int coveragePct;

  SimulationPoint copyWith({Offset? normalizedPosition}) {
    return SimulationPoint(
      id: id,
      type: type,
      label: label,
      normalizedPosition: normalizedPosition ?? this.normalizedPosition,
      windMph: windMph,
      humidityPct: humidityPct,
      coveragePct: coveragePct,
    );
  }
}
