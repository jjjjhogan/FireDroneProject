import 'package:flutter/material.dart';

import '../../models/analytics_snapshot.dart';
import '../common/info_card.dart';
import '../common/status_pill.dart';

class AnalyticsIntegrationPanel extends StatelessWidget {
  const AnalyticsIntegrationPanel({required this.targets, super.key});

  final List<AnalyticsIntegrationTarget> targets;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      color: const Color(0xfff8fbfa),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff2364aa).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  size: 18,
                  color: Color(0xff2364aa),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Integration',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Reserved endpoints for live analytics feeds when the backend is connected.',
                      style: TextStyle(color: Color(0xff62716c), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < targets.length; i++) ...[
            _IntegrationRow(target: targets[i]),
            if (i != targets.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _IntegrationRow extends StatelessWidget {
  const _IntegrationRow({required this.target});

  final AnalyticsIntegrationTarget target;

  Color get _statusColor => switch (target.status) {
    'connected' => const Color(0xffb7f1d8),
    'ready' => const Color(0xffd7ecff),
    _ => const Color(0xffeef1f0),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdfe8e4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  target.endpoint,
                  style: const TextStyle(
                    color: Color(0xff60716b),
                    fontFamily: 'Courier New',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(label: target.status, color: _statusColor),
        ],
      ),
    );
  }
}
