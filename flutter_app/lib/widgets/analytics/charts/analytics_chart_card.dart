import 'package:flutter/material.dart';

import '../../common/info_card.dart';

class AnalyticsChartCard extends StatelessWidget {
  const AnalyticsChartCard({
    required this.title,
    required this.subtitle,
    required this.chart,
    this.height = 260,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget chart;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xff62716c), height: 1.35),
          ),
          const SizedBox(height: 16),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }
}
