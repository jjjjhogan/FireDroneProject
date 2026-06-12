import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/analytics_snapshot.dart';
import 'analytics_chart_card.dart';

class ResponseBarChart extends StatelessWidget {
  const ResponseBarChart({required this.points, super.key});

  final List<AnalyticsTrendPoint> points;

  static const _barColor = Color(0xff12805c);

  @override
  Widget build(BuildContext context) {
    final maxY = points.fold<double>(
      0,
      (max, point) => point.value > max ? point.value : max,
    );

    return AnalyticsChartCard(
      title: 'Response Time Breakdown',
      subtitle: 'Median stage durations from recent sorties.',
      chart: BarChart(
        BarChartData(
          maxY: maxY + 2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.withValues(alpha: 0.18), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) => Text(
                  '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}m',
                  style: const TextStyle(fontSize: 11, color: Color(0xff62716c)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      points[index].label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Color(0xff62716c)),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].value,
                    color: _barColor,
                    width: 22,
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
