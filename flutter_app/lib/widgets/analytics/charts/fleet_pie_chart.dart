import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/analytics_snapshot.dart';
import 'analytics_chart_card.dart';

class FleetPieChart extends StatelessWidget {
  const FleetPieChart({required this.utilization, super.key});

  final AnalyticsFleetUtilization utilization;

  @override
  Widget build(BuildContext context) {
    final sections = [
      _section(
        value: utilization.activeDrones.toDouble(),
        color: const Color(0xff0e7656),
        label: 'Active',
      ),
      _section(
        value: utilization.availableDrones.toDouble(),
        color: const Color(0xff12805c),
        label: 'Available',
      ),
      _section(
        value: utilization.chargingDrones.toDouble(),
        color: const Color(0xffffc857),
        label: 'Charging',
      ),
    ];

    return AnalyticsChartCard(
      title: 'Fleet Status Mix',
      subtitle:
          '${utilization.sortiesToday} sorties today · ${utilization.flightHoursToday.toStringAsFixed(1)} flight hours.',
      chart: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: sections,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legend('Active', utilization.activeDrones, const Color(0xff0e7656)),
                const SizedBox(height: 8),
                _legend(
                  'Available',
                  utilization.availableDrones,
                  const Color(0xff12805c),
                ),
                const SizedBox(height: 8),
                _legend(
                  'Charging',
                  utilization.chargingDrones,
                  const Color(0xffffc857),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section({
    required double value,
    required Color color,
    required String label,
  }) {
    return PieChartSectionData(
      value: value == 0 ? 0.001 : value,
      color: color,
      title: value.toStringAsFixed(0),
      radius: 58,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    );
  }

  Widget _legend(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label · $count',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    );
  }
}
