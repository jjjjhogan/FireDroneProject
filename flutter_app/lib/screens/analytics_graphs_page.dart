import 'package:flutter/material.dart';

import '../models/analytics_snapshot.dart';
import '../widgets/analytics/analytics_integration_panel.dart';
import '../widgets/analytics/analytics_section_header.dart';
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
          color: const Color(0xff0f241f),
          borderColor: const Color(0xff29423d),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.show_chart, color: Color(0xffb7f1d8)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Graph Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Interactive chart series from GET /api/analytics/summary. Overview tab keeps tabular KPIs and mission history.',
                      style: TextStyle(color: Color(0xffd7e7e1), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const AnalyticsSectionHeader(
          icon: Icons.insights_outlined,
          title: 'Detection & Response',
          subtitle: 'Weekly hotspot volume and stage-by-stage response timing.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final hotspotChart = HotspotLineChart(
              points: analytics.weeklyDetections,
            );
            final responseChart = ResponseBarChart(
              points: analytics.responseTimesMin,
            );

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
        const SizedBox(height: 22),
        const AnalyticsSectionHeader(
          icon: Icons.multiline_chart_outlined,
          title: 'Model Performance',
          subtitle:
              'Thermal confidence and patrol coverage tracked on separate time scales.',
        ),
        ModelPerformanceCharts(
          confidenceTrend: analytics.thermalConfidenceTrend,
          coverageTrend: analytics.patrolCoverageTrend,
        ),
        const SizedBox(height: 22),
        const AnalyticsSectionHeader(
          icon: Icons.pie_chart_outline,
          title: 'Fleet & Missions',
          subtitle: 'Current fleet mix and hotspot yield from recent sorties.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final fleetChart = FleetPieChart(
              utilization: analytics.fleetUtilization,
            );
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
