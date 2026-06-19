import 'package:flutter/material.dart';

import '../../models/analytics_snapshot.dart';
import '../common/info_card.dart';
import 'analytics_helpers.dart';

IconData analyticsIconForKpi(String id) => switch (id) {
  'detection_latency' => Icons.timer_outlined,
  'thermal_confidence' => Icons.local_fire_department_outlined,
  'safe_return' => Icons.battery_charging_full_outlined,
  'coverage_efficiency' => Icons.map_outlined,
  'false_positive_rate' => Icons.rule_outlined,
  'command_gate' => Icons.lock_outline,
  _ => Icons.insights_outlined,
};

Color analyticsAccentForKpi(String id) => switch (id) {
  'detection_latency' => const Color(0xff2364aa),
  'thermal_confidence' => const Color(0xffc2542d),
  'safe_return' => const Color(0xff0e7656),
  'coverage_efficiency' => const Color(0xff12805c),
  'false_positive_rate' => const Color(0xffb45309),
  'command_gate' => const Color(0xff475569),
  _ => const Color(0xff0e7656),
};

class AnalyticsKpiCard extends StatelessWidget {
  const AnalyticsKpiCard({required this.kpi, super.key});

  final AnalyticsKpi kpi;

  @override
  Widget build(BuildContext context) {
    final accent = analyticsAccentForKpi(kpi.id);
    final icon = analyticsIconForKpi(kpi.id);
    final sentiment = analyticsTrendSentiment(kpi.id, kpi.trend);
    final trendColors = trendSentimentColors(sentiment);

    return InfoCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, size: 18, color: accent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              kpi.label,
                              style: const TextStyle(
                                color: Color(0xff60716b),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        kpi.value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        kpi.detail,
                        style: const TextStyle(
                          color: Color(0xff65736f),
                          height: 1.35,
                        ),
                      ),
                      if (kpi.trend != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: trendColors.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: trendColors.border),
                          ),
                          child: Text(
                            kpi.trend!,
                            style: TextStyle(
                              color: trendColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
