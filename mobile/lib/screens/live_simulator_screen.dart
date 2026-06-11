import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/mission_map_painter.dart';

class LiveSimulatorScreen extends StatelessWidget {
  const LiveSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Live Simulator',
          actions: [
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Start run'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Mission Board',
                  subtitle: 'Foothill ridge sweep · Run #2417',
                ),
                const SizedBox(height: 16),
                InfoCard(
                  child: SizedBox(
                    height: 320,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: CustomPaint(painter: MissionMapPainter()),
                        ),
                        const Positioned(
                          left: 16,
                          top: 16,
                          child: StatusPill(
                            label: 'Thermal front tracking',
                            color: AppColors.fwiMed,
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: StatusPill(
                            label: 'ETA full coverage · 18 min',
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const ResponsiveGrid(
                  children: [
                    MetricCard(
                      label: 'Run #2417',
                      value: 'Active',
                      detail: 'Foothill ridge sweep',
                      accent: AppColors.primary,
                    ),
                    MetricCard(
                      label: 'Coverage',
                      value: '83%',
                      detail: 'Projected in 18 minutes',
                    ),
                    MetricCard(
                      label: 'Wind Shift',
                      value: '12 km/h',
                      detail: 'Northwest at 14:20',
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
