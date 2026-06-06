import 'package:flutter/material.dart';

import '../../models/simulation_layout.dart';
import '../common/metric_card.dart';
import '../common/responsive_grid.dart';

class SimulationMetricsPanel extends StatelessWidget {
  const SimulationMetricsPanel({
    required this.scenarioName,
    required this.runState,
    required this.telemetry,
    super.key,
  });

  final String scenarioName;
  final SimulationRunState runState;
  final SimulationTelemetry telemetry;

  String get _runStatus => switch (runState) {
        SimulationRunState.idle => 'Ready',
        SimulationRunState.running => 'Running',
        SimulationRunState.paused => 'Paused',
        SimulationRunState.complete => 'Complete',
      };

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      children: [
        MetricCard(
          label: 'Run status',
          value: _runStatus,
          detail: '${telemetry.progressPct}% · $scenarioName',
        ),
        MetricCard(
          label: 'Route vs fire',
          value: telemetry.routeCrossesFire ? 'Crosses fire' : 'Clear path',
          detail: telemetry.routeCrossesFire
              ? 'Patrol line intersects thermal front'
              : 'Route avoids thermal zone',
        ),
        MetricCard(
          label: 'Live telemetry',
          value: telemetry.label,
          detail:
              '${telemetry.windMph.round()} mph · ${telemetry.humidityPct}% RH · ${telemetry.coveragePct}% coverage',
        ),
      ],
    );
  }
}
