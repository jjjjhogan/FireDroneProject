import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'Analytics'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Mission Performance',
                  subtitle: 'Aggregated across the last 100 simulated runs',
                ),
                const SizedBox(height: 16),
                const ResponsiveGrid(
                  children: [
                    MetricCard(
                      label: 'Detection Latency',
                      value: '2.6 min',
                      detail: 'Down 31% vs manual patrol',
                      accent: AppColors.primary,
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
                    MetricCard(
                      label: 'False Positive Rate',
                      value: '4.2%',
                      detail: 'Charcoal kilns & solar farms',
                    ),
                    MetricCard(
                      label: 'Area Covered',
                      value: '1,840 km²',
                      detail: 'Min Mountains pilot region',
                    ),
                    MetricCard(
                      label: 'Avg Fleet Size',
                      value: '6.4',
                      detail: 'Drones per dispatch',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
