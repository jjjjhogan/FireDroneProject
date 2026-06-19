import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/analytics_snapshot.dart';
import '../analytics_helpers.dart';
import 'analytics_chart_card.dart';
import 'chart_empty_state.dart';

class HotspotLineChart extends StatelessWidget {
  const HotspotLineChart({required this.points, super.key});

  final List<AnalyticsTrendPoint> points;

  static const _lineColor = Color(0xff0e7656);
  static const _fillColor = Color(0x330e7656);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return AnalyticsChartCard(
        title: 'Weekly Hotspot Detections',
        subtitle: 'Thermal cue volume across the last seven patrol days.',
        icon: Icons.local_fire_department_outlined,
        accent: _lineColor,
        chart: const ChartEmptyState(
          message: 'No weekly detection series returned by the analytics feed.',
        ),
      );
    }

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    final maxY = chartMaxY(points.map((point) => point.value));

    return AnalyticsChartCard(
      title: 'Weekly Hotspot Detections',
      subtitle: 'Thermal cue volume across the last seven patrol days.',
      icon: Icons.local_fire_department_outlined,
      accent: _lineColor,
      chart: LineChart(
        LineChartData(
          minY: 0,
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
                reservedSize: 28,
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
              spots: spots,
              isCurved: true,
              color: _lineColor,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: _fillColor),
            ),
          ],
        ),
      ),
    );
  }
}
