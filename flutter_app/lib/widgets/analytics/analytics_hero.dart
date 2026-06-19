import 'package:flutter/material.dart';

import '../../models/analytics_snapshot.dart';
import '../common/status_pill.dart';
import 'analytics_helpers.dart';

class AnalyticsHero extends StatelessWidget {
  const AnalyticsHero({
    required this.analytics,
    this.onRefresh,
    this.refreshing = false,
    super.key,
  });

  final AnalyticsSnapshot analytics;
  final VoidCallback? onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final highlights = analytics.kpis.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff071512), Color(0xff0f241f), Color(0xff142f28)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff29423d)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MISSION ANALYTICS',
                      style: TextStyle(
                        color: Color(0xff7cc7ff),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  tooltip: 'Refresh analytics',
                  onPressed: refreshing ? null : onRefresh,
                  icon: refreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xffb7f1d8),
                          ),
                        )
                      : const Icon(
                          Icons.refresh,
                          color: Color(0xffb7f1d8),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Patrol efficiency, thermal performance, fleet utilization, and chart-ready series for the DJI wildfire workflow.',
            style: TextStyle(color: Color(0xffd7e7e1), height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: analytics.dataSource == 'api'
                    ? 'Live API feed'
                    : 'Mock feed',
                color: analytics.dataSource == 'api'
                    ? const Color(0xffb7f1d8)
                    : const Color(0xffffd9a8),
              ),
              StatusPill(
                label: 'Updated ${formatAnalyticsTimestamp(analytics.lastUpdated)}',
                color: const Color(0xffd7ecff),
              ),
              StatusPill(
                label: '${analytics.kpis.length} KPIs tracked',
                color: const Color(0xffd7e7e1),
              ),
            ],
          ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 720;
                final cards = highlights
                    .map((kpi) => _HeroStat(kpi: kpi))
                    .toList();

                if (stacked) {
                  return Column(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i != cards.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      Expanded(child: cards[i]),
                      if (i != cards.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.kpi});

  final AnalyticsKpi kpi;

  @override
  Widget build(BuildContext context) {
    final sentiment = analyticsTrendSentiment(kpi.id, kpi.trend);
    final trendColors = trendSentimentColors(sentiment);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi.label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            kpi.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (kpi.trend != null) ...[
            const SizedBox(height: 6),
            Text(
              kpi.trend!,
              style: TextStyle(
                color: trendColors.text.withValues(alpha: 0.95),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
