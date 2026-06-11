import 'package:flutter/material.dart';

import '../widgets/common/metric_card.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/common/section_header.dart';

class FleetPage extends StatelessWidget {
  const FleetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Drone Fleet'),
        SizedBox(height: 14),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Scout Alpha',
              value: 'Ready',
              detail: 'Thermal + visual',
            ),
            MetricCard(
              label: 'Relay Beta',
              value: 'Charging',
              detail: '74% battery',
            ),
            MetricCard(
              label: 'Mapper Delta',
              value: 'Ready',
              detail: 'LiDAR sweep',
            ),
          ],
        ),
      ],
    );
  }
}
