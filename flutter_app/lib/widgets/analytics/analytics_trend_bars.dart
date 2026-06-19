import 'package:flutter/material.dart';

import '../../models/analytics_snapshot.dart';
import '../common/info_card.dart';

class AnalyticsTrendBars extends StatelessWidget {
  const AnalyticsTrendBars({
    required this.title,
    required this.subtitle,
    required this.points,
    this.accent = const Color(0xff0e7656),
    this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<AnalyticsTrendPoint> points;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return InfoCard(
        color: const Color(0xfff8fbfa),
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
            const Text(
              'No trend data available.',
              style: TextStyle(
                color: Color(0xff62716c),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = points.fold<double>(
      0,
      (max, point) => point.value > max ? point.value : max,
    );

    return InfoCard(
      color: const Color(0xfff8fbfa),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: 12),
              ],
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
          for (final point in points) ...[
            Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    point.label,
                    style: const TextStyle(
                      color: Color(0xff60716b),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final widthFactor = maxValue == 0
                          ? 0.0
                          : point.value / maxValue;
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xffedf3f0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Container(
                            width: constraints.maxWidth * widthFactor,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent.withValues(alpha: 0.75),
                                  accent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 72,
                  child: Text(
                    '${_formatValue(point.value)} ${point.unit}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  String _formatValue(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}
