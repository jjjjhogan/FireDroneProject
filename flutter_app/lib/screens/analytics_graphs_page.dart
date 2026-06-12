import 'package:flutter/material.dart';

import '../models/analytics_snapshot.dart';
import '../widgets/analytics/analytics_integration_panel.dart';
import '../widgets/analytics/charts/fleet_pie_chart.dart';
import '../widgets/analytics/charts/hotspot_line_chart.dart';
import '../widgets/analytics/charts/performance_charts.dart';
import '../widgets/analytics/charts/response_bar_chart.dart';
import '../widgets/common/info_card.dart';

class AnalyticsGraphsPage extends StatelessWidget {
  const AnalyticsGraphsPage({required this.analytics, super.key});

  final AnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          color: const Color(0xfff8fbfa),
          child: Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xff0e7656)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Graph Analytics',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chart series are sourced from the analytics feed and can be swapped to GET /api/analytics/graphs when live data is available.',
                      style: TextStyle(color: Color(0xff62716c), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final hotspotChart = HotspotLineChart(points: analytics.weeklyDetections);
            final responseChart = ResponseBarChart(points: analytics.responseTimesMin);

            if (stacked) {
              return Column(
                children: [
                  hotspotChart,
                  const SizedBox(height: 16),
                  responseChart,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: hotspotChart),
                const SizedBox(width: 16),
                Expanded(child: responseChart),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        ThermalConfidenceChart(
          confidenceTrend: analytics.thermalConfidenceTrend,
          coverageTrend: analytics.patrolCoverageTrend,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: const [
            _ChartLegend(color: Color(0xff0e7656), label: 'Thermal confidence'),
            _ChartLegend(color: Color(0xffffc857), label: 'Patrol coverage'),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final fleetChart = FleetPieChart(utilization: analytics.fleetUtilization);
            final missionChart = MissionHotspotBarChart(
              missions: analytics.recentMissions,
            );

            if (stacked) {
              return Column(
                children: [
                  fleetChart,
                  const SizedBox(height: 16),
                  missionChart,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fleetChart),
                const SizedBox(width: 16),
                Expanded(child: missionChart),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        AnalyticsIntegrationPanel(
          targets: analytics.integrationTargets
              .where(
                (target) =>
                    target.endpoint.contains('/analytics/') ||
                    target.endpoint.contains('/dji/telemetry'),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
