import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/analytics_snapshot.dart';
import 'analytics_chart_card.dart';

class ThermalConfidenceChart extends StatelessWidget {
  const ThermalConfidenceChart({
    required this.confidenceTrend,
    required this.coverageTrend,
    super.key,
  });

  final List<AnalyticsTrendPoint> confidenceTrend;
  final List<AnalyticsTrendPoint> coverageTrend;

  @override
  Widget build(BuildContext context) {
    return AnalyticsChartCard(
      title: 'Model Confidence & Coverage',
      subtitle:
          'Hourly thermal confidence alongside rolling patrol coverage trend.',
      height: 280,
      chart: LineChart(
        LineChartData(
          minY: 70,
          maxY: 100,
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
                  if (index < 0 || index >= confidenceTrend.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      confidenceTrend[index].label,
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
                for (var i = 0; i < confidenceTrend.length; i++)
                  FlSpot(i.toDouble(), confidenceTrend[i].value),
              ],
              isCurved: true,
              color: const Color(0xff0e7656),
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: [
                for (var i = 0; i < coverageTrend.length; i++)
                  FlSpot(
                    i *
                        (confidenceTrend.length - 1) /
                        (coverageTrend.length - 1),
                    coverageTrend[i].value,
                  ),
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
    final maxY = missions.fold<double>(
      0,
      (max, mission) => mission.hotspotsDetected > max
          ? mission.hotspotsDetected.toDouble()
          : max,
    );

    return AnalyticsChartCard(
      title: 'Hotspots by Recent Mission',
      subtitle: 'Detection count per completed or aborted sortie.',
      chart: BarChart(
        BarChartData(
          maxY: maxY + 1,
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
                  final label = missions[index].scenarioName.split(' ').first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
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
