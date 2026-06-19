import 'package:flutter/material.dart';

import '../../common/info_card.dart';

class AnalyticsChartCard extends StatelessWidget {
  const AnalyticsChartCard({
    required this.title,
    required this.subtitle,
    required this.chart,
    this.height = 260,
    this.icon = Icons.bar_chart_outlined,
    this.accent = const Color(0xff0e7656),
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget chart;
  final double height;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xff62716c),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: height,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xfff8fbfa),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xffe5ece8)),
            ),
            child: chart,
          ),
        ],
      ),
    );
  }
}
