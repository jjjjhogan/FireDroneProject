import 'package:flutter/material.dart';

import '../../models/analytics_snapshot.dart';
import '../common/info_card.dart';

class AnalyticsTrendBars extends StatelessWidget {
  const AnalyticsTrendBars({
    required this.title,
    required this.subtitle,
    required this.points,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<AnalyticsTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(
      0,
      (max, point) => point.value > max ? point.value : max,
    );

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
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xffedf3f0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Container(
                            width: constraints.maxWidth * widthFactor,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xff0e7656),
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
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
