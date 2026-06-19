import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/analytics_snapshot.dart';
import '../analytics_helpers.dart';
import 'analytics_chart_card.dart';
import 'chart_empty_state.dart';

class ModelPerformanceCharts extends StatelessWidget {
  const ModelPerformanceCharts({
    required this.confidenceTrend,
    required this.coverageTrend,
    super.key,
  });

  final List<AnalyticsTrendPoint> confidenceTrend;
  final List<AnalyticsTrendPoint> coverageTrend;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 980;
        final confidenceChart = ThermalConfidenceLineChart(
          points: confidenceTrend,
        );
        final coverageChart = PatrolCoverageLineChart(points: coverageTrend);

        if (stacked) {
          return Column(
            children: [
              confidenceChart,
              const SizedBox(height: 16),
              coverageChart,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: confidenceChart),
            const SizedBox(width: 16),
            Expanded(child: coverageChart),
          ],
        );
      },
    );
  }
}

class ThermalConfidenceLineChart extends StatelessWidget {
  const ThermalConfidenceLineChart({required this.points, super.key});

  final List<AnalyticsTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return AnalyticsChartCard(
        title: 'Thermal Confidence',
        subtitle: 'Hourly model ensemble average across active sorties.',
        icon: Icons.local_fire_department_outlined,
        accent: const Color(0xff0e7656),
        chart: const ChartEmptyState(
          message: 'No thermal confidence series returned by the analytics feed.',
        ),
      );
    }

    final minValue = points.fold<double>(
      points.first.value,
      (min, point) => point.value < min ? point.value : min,
    );
    final maxValue = points.fold<double>(
      points.first.value,
      (max, point) => point.value > max ? point.value : max,
    );

    return AnalyticsChartCard(
      title: 'Thermal Confidence',
      subtitle: 'Hourly model ensemble average across active sorties.',
      icon: Icons.local_fire_department_outlined,
      accent: const Color(0xff0e7656),
      chart: LineChart(
        LineChartData(
          minY: (minValue - 8).clamp(0, double.infinity),
          maxY: maxValue + 4,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withValues(alpha: 0.18),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff62716c),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      points[index].label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff62716c),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              isCurved: true,
              color: const Color(0xff0e7656),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0x330e7656),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatrolCoverageLineChart extends StatelessWidget {
  const PatrolCoverageLineChart({required this.points, super.key});

  final List<AnalyticsTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return AnalyticsChartCard(
        title: 'Patrol Coverage',
        subtitle: 'Rolling weekly corridor completion percentage.',
        icon: Icons.map_outlined,
        accent: const Color(0xffffc857),
        chart: const ChartEmptyState(
          message: 'No patrol coverage series returned by the analytics feed.',
        ),
      );
    }

    final minValue = points.fold<double>(
      points.first.value,
      (min, point) => point.value < min ? point.value : min,
    );
    final maxValue = points.fold<double>(
      points.first.value,
      (max, point) => point.value > max ? point.value : max,
    );

    return AnalyticsChartCard(
      title: 'Patrol Coverage',
      subtitle: 'Rolling weekly corridor completion percentage.',
      icon: Icons.map_outlined,
      accent: const Color(0xffffc857),
      chart: LineChart(
        LineChartData(
          minY: (minValue - 8).clamp(0, double.infinity),
          maxY: maxValue + 4,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withValues(alpha: 0.18),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff62716c),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      points[index].label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff62716c),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              isCurved: true,
              color: const Color(0xffffc857),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              dashArray: [6, 4],
            ),
          ],
        ),
      ),
    );
  }
}

class MissionHotspotBarChart extends StatelessWidget {
  const MissionHotspotBarChart({required this.missions, super.key});

  final List<AnalyticsMissionRecord> missions;

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return AnalyticsChartCard(
        title: 'Hotspots by Recent Mission',
        subtitle: 'Detection count per completed or aborted sortie.',
        icon: Icons.bar_chart,
        accent: const Color(0xffc2542d),
        chart: const ChartEmptyState(
          message: 'No recent missions available for hotspot comparison.',
          icon: Icons.flight_takeoff_outlined,
        ),
      );
    }

    final maxY = chartMaxY(
      missions.map((mission) => mission.hotspotsDetected.toDouble()),
      padding: 1,
      minimum: 1,
    );

    return AnalyticsChartCard(
      title: 'Hotspots by Recent Mission',
      subtitle: 'Detection count per completed or aborted sortie.',
      icon: Icons.bar_chart,
      accent: const Color(0xffc2542d),
      chart: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withValues(alpha: 0.18),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff62716c),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= missions.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      abbreviateScenarioLabel(missions[index].scenarioName),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xff62716c),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < missions.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: missions[i].hotspotsDetected.toDouble(),
                    color: missions[i].outcome == 'completed'
                        ? const Color(0xff0e7656)
                        : const Color(0xffd97706),
                    width: 24,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
