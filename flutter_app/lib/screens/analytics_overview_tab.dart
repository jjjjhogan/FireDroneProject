import 'package:flutter/material.dart';

import '../models/analytics_snapshot.dart';
import '../widgets/analytics/analytics_integration_panel.dart';
import '../widgets/analytics/analytics_mission_list.dart';
import '../widgets/analytics/analytics_trend_bars.dart';
import '../widgets/common/info_card.dart';
import '../widgets/common/metric_card.dart';
import '../widgets/common/responsive_grid.dart';

class AnalyticsOverviewTab extends StatelessWidget {
  const AnalyticsOverviewTab({required this.analytics, super.key});

  final AnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveGrid(
          children: analytics.kpis
              .map(
                (kpi) => MetricCard(
                  icon: _iconForKpi(kpi.id),
                  label: kpi.label,
                  value: kpi.value,
                  detail: kpi.trend == null
                      ? kpi.detail
                      : '${kpi.detail}\n${kpi.trend!}',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final trendSection = AnalyticsTrendBars(
              title: 'Weekly Hotspot Detections',
              subtitle: 'Rolling seven-day thermal cue volume.',
              points: analytics.weeklyDetections,
            );
            final responseSection = AnalyticsTrendBars(
              title: 'Response Time Breakdown',
              subtitle: 'Median stage durations from the latest sorties.',
              points: analytics.responseTimesMin,
            );

            if (stacked) {
              return Column(
                children: [
                  trendSection,
                  const SizedBox(height: 16),
                  responseSection,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: trendSection),
                const SizedBox(width: 16),
                Expanded(child: responseSection),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final fleetPanel = _FleetUtilizationPanel(
              utilization: analytics.fleetUtilization,
            );
            final environmentPanel = _EnvironmentalPanel(
              environmental: analytics.environmental,
            );

            if (stacked) {
              return Column(
                children: [
                  fleetPanel,
                  const SizedBox(height: 16),
                  environmentPanel,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fleetPanel),
                const SizedBox(width: 16),
                Expanded(child: environmentPanel),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        AnalyticsMissionList(missions: analytics.recentMissions),
        const SizedBox(height: 18),
        AnalyticsIntegrationPanel(targets: analytics.integrationTargets),
      ],
    );
  }

  IconData _iconForKpi(String id) => switch (id) {
    'detection_latency' => Icons.timer_outlined,
    'thermal_confidence' => Icons.local_fire_department_outlined,
    'safe_return' => Icons.battery_charging_full_outlined,
    'coverage_efficiency' => Icons.map_outlined,
    'false_positive_rate' => Icons.rule_outlined,
    'command_gate' => Icons.lock_outline,
    _ => Icons.insights_outlined,
  };
}

class _FleetUtilizationPanel extends StatelessWidget {
  const _FleetUtilizationPanel({required this.utilization});

  final AnalyticsFleetUtilization utilization;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fleet Utilization',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Live sortie capacity and battery posture.',
            style: TextStyle(color: Color(0xff62716c), height: 1.35),
          ),
          const SizedBox(height: 14),
          ResponsiveGrid(
            children: [
              MetricCard(
                icon: Icons.flight_takeoff_outlined,
                label: 'Active / Available',
                value:
                    '${utilization.activeDrones} / ${utilization.availableDrones}',
                detail: '${utilization.chargingDrones} charging on dock',
              ),
              MetricCard(
                icon: Icons.schedule_outlined,
                label: 'Flight Hours Today',
                value: '${utilization.flightHoursToday.toStringAsFixed(1)} h',
                detail: '${utilization.sortiesToday} sorties completed',
              ),
              MetricCard(
                icon: Icons.battery_5_bar_outlined,
                label: 'Launch Battery',
                value: '${utilization.avgBatteryAtLaunchPct}%',
                detail: 'Average battery at dispatch',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnvironmentalPanel extends StatelessWidget {
  const _EnvironmentalPanel({required this.environmental});

  final AnalyticsEnvironmental environmental;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Environmental Correlates',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Conditions influencing thermal detection quality.',
            style: TextStyle(color: Color(0xff62716c), height: 1.35),
          ),
          const SizedBox(height: 14),
          ResponsiveGrid(
            children: [
              MetricCard(
                icon: Icons.air,
                label: 'Wind',
                value: '${environmental.windMph.round()} mph',
                detail: 'Crosswind impact on hover stability',
              ),
              MetricCard(
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: '${environmental.humidityPct}%',
                detail: 'Lower humidity raises false-positive risk',
              ),
              MetricCard(
                icon: Icons.visibility_outlined,
                label: 'Visibility',
                value: '${environmental.visibilityMi.toStringAsFixed(1)} mi',
                detail:
                    'Smoke index ${environmental.smokeIndex} · thermal noise ${environmental.thermalNoise}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
