import 'package:flutter/material.dart';

class ThermalFront {
  ThermalFront({
    required this.id,
    required this.label,
    required this.normalizedPosition,
    this.normalizedRadiusX = 0.14,
    this.normalizedRadiusY = 0.21,
    this.windMph = 18,
    this.humidityPct = 28,
  });

  final String id;
  final String label;
  Offset normalizedPosition;
  final double normalizedRadiusX;
  final double normalizedRadiusY;
  final double windMph;
  final int humidityPct;

  ThermalFront copyWith({Offset? normalizedPosition}) {
    return ThermalFront(
      id: id,
      label: label,
      normalizedPosition: normalizedPosition ?? this.normalizedPosition,
      normalizedRadiusX: normalizedRadiusX,
      normalizedRadiusY: normalizedRadiusY,
      windMph: windMph,
      humidityPct: humidityPct,
    );
  }
}
