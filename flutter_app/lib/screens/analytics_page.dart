import 'package:flutter/material.dart';

import '../widgets/common/metric_card.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/common/section_header.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Analytics'),
        SizedBox(height: 14),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Detection Latency',
              value: '2.6 min',
              detail: 'Down 31% vs manual patrol',
            ),
            MetricCard(
              label: 'Thermal Confidence',
              value: '91%',
              detail: 'Model ensemble average',
            ),
            MetricCard(
              label: 'Safe Return',
              value: '97%',
              detail: 'Battery-aware routing',
            ),
          ],
        ),
      ],
    );
  }
}
