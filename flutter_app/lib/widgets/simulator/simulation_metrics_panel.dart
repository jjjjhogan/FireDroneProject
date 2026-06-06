import 'package:flutter/material.dart';

import '../../models/simulation_point.dart';
import '../common/metric_card.dart';
import '../common/responsive_grid.dart';

class SimulationMetricsPanel extends StatelessWidget {
  const SimulationMetricsPanel({
    required this.scenarioName,
    required this.activePoint,
    super.key,
  });

  final String scenarioName;
  final SimulationPoint? activePoint;

  @override
  Widget build(BuildContext context) {
    final point = activePoint;

    return ResponsiveGrid(
      children: [
        MetricCard(
          label: 'Active point',
          value: point?.label ?? 'None selected',
          detail: scenarioName,
        ),
        MetricCard(
          label: 'Coverage',
          value: point != null ? '${point.coveragePct}%' : '--',
          detail: point != null
              ? 'Sector at ${(point.normalizedPosition.dx * 100).round()}% east'
              : 'Select or drag a point',
        ),
        MetricCard(
          label: 'Wind / RH',
          value: point != null
              ? '${point.windMph.round()} mph'
              : '--',
          detail: point != null ? '${point.humidityPct}% humidity' : '--',
        ),
      ],
    );
  }
}
