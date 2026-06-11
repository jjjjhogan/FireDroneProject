import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

const _terrainTabs = ['Mountain', 'Plateau', 'Mixed'];

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTerrain = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 920;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResponsiveRow(
                      isWide: isWide,
                      leftFlex: 2,
                      rightFlex: 1,
                      left: const _ActiveRegionCard(),
                      right: const _RecentAnomaliesCard(),
                    ),
                    const SizedBox(height: 20),
                    _ResponsiveRow(
                      isWide: isWide,
                      leftFlex: 3,
                      rightFlex: 2,
                      left: _DetectionChartCard(
                        selectedTerrain: _selectedTerrain,
                        onTerrainChanged: (i) =>
                            setState(() => _selectedTerrain = i),
                      ),
                      right: const _CoordinationModesCard(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({
    required this.isWide,
    required this.left,
    required this.right,
    required this.leftFlex,
    required this.rightFlex,
  });

  final bool isWide;
  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(
        children: [
          left,
          const SizedBox(height: 20),
          right,
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: leftFlex, child: left),
          const SizedBox(width: 20),
          Expanded(flex: rightFlex, child: right),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            'Operations Dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Min Mountains Pilot'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export Report'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      padding: padding,
      child: child,
    );
  }
}

class _ActiveRegionCard extends StatelessWidget {
  const _ActiveRegionCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RegionImageHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: const [
                _RegionStat(value: '6 / 8', label: 'Drones airborne'),
                _RegionStat(value: '42 min', label: 'Patrol elapsed'),
                _RegionStat(value: '81%', label: 'Avg battery'),
                _RegionStat(value: '2', label: 'Heat anomalies'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionImageHeader extends StatelessWidget {
  const _RegionImageHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A6741), Color(0xFF8B9A6B)],
              ),
            ),
          ),
          Image.asset(
            'assets/images/scenario-mountain.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.65),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: const [
                _OverlayTag(
                  label: 'Active Region',
                  color: Color(0xCC1A1D21),
                ),
                SizedBox(width: 8),
                _OverlayTag(
                  label: 'Patrol Live',
                  color: AppColors.fwiLow,
                  showDot: true,
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SICHUAN PILOT REGION · MIN MOUNTAINS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sector 3-North · 1,840 km² · 6 drones airborne',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _MetricChip(icon: Icons.air, label: 'SW 14 km/h'),
                    _MetricChip(icon: Icons.thermostat, label: '26°C'),
                    _MetricChip(icon: Icons.water_drop_outlined, label: 'RH 38%'),
                    _MetricChip(
                      icon: Icons.warning_amber_rounded,
                      label: 'FWI Elevated',
                      color: AppColors.fwiMed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayTag extends StatelessWidget {
  const _OverlayTag({
    required this.label,
    required this.color,
    this.showDot = false,
  });

  final String label;
  final Color color;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionStat extends StatelessWidget {
  const _RegionStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _RecentAnomaliesCard extends StatelessWidget {
  const _RecentAnomaliesCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Recent Anomalies',
            trailing: Text(
              'View all',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _AnomalyItem(
            icon: Icons.local_fire_department,
            iconColor: AppColors.fwiHigh,
            iconBg: Color(0xFFFDE7E7),
            title: 'Hotspot · 31.42°N 103.81°E',
            subtitle: 'Confirmed by Drone-04 · 6 min ago',
            status: 'Response time: 4m 12s',
            statusColor: AppColors.fwiHigh,
          ),
          SizedBox(height: 12),
          const _AnomalyItem(
            icon: Icons.thermostat,
            iconColor: AppColors.fwiMed,
            iconBg: Color(0xFFFDF0E0),
            title: 'Thermal flare',
            subtitle: 'Drone-02 investigating',
            status: 'Confidence 67%',
            statusColor: AppColors.fwiMed,
          ),
          SizedBox(height: 12),
          const _AnomalyItem(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.textSecondary,
            iconBg: Color(0xFFEFF1F4),
            title: 'False positive cleared',
            subtitle: 'Charcoal kiln · 18 min ago',
          ),
        ],
      ),
    );
  }
}

class _AnomalyItem extends StatelessWidget {
  const _AnomalyItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.status,
    this.statusColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? status;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    status!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor ?? AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectionChartCard extends StatelessWidget {
  const _DetectionChartCard({
    required this.selectedTerrain,
    required this.onTerrainChanged,
  });

  final int selectedTerrain;
  final ValueChanged<int> onTerrainChanged;

  static const _adaptiveByTerrain = [
    [23.0, 14, 11, 9, 7, 6, 5.5, 5, 5],
    [20.0, 13, 10, 8, 6.5, 5.5, 5, 4.5, 4.2],
    [25.0, 16, 12, 10, 8, 7, 6, 5.5, 5.2],
  ];
  static const _staticByTerrain = [
    [28.0, 19, 14, 12, 10, 8.5, 7.5, 7, 6.5],
    [25.0, 17, 13, 11, 9, 8, 7, 6.5, 6],
    [29.0, 21, 16, 13, 11, 9.5, 8.5, 8, 7.5],
  ];
  static const _xLabels = ['2', '4', '6', '8', '10', '12', '16', '20', '24'];

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Detection Time vs. Fleet Size',
            subtitle:
                'Simulated across the Min Mountains pilot region (1,840 km²)',
            trailing: _SegmentedTabs(
              tabs: _terrainTabs,
              selectedIndex: selectedTerrain,
              onChanged: onTerrainChanged,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                adaptive: _adaptiveByTerrain[selectedTerrain]
                    .map((e) => e.toDouble())
                    .toList(),
                staticSweep: _staticByTerrain[selectedTerrain]
                    .map((e) => e.toDouble())
                    .toList(),
                xLabels: _xLabels,
                maxY: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _LegendDot(color: AppColors.chartGreen, label: 'Adaptive swarm'),
              SizedBox(width: 24),
              _LegendDot(
                color: AppColors.chartGrey,
                label: 'Static grid sweep',
                dashed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isSelected
                    ? Border.all(color: AppColors.border)
                    : null,
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(3),
            border: dashed ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.adaptive,
    required this.staticSweep,
    required this.xLabels,
    required this.maxY,
  });

  final List<double> adaptive;
  final List<double> staticSweep;
  final List<String> xLabels;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 28.0;
    const bottomPad = 22.0;
    const topPad = 8.0;
    const rightPad = 6.0;

    final plotW = size.width - leftPad - rightPad;
    final plotH = size.height - topPad - bottomPad;
    final origin = Offset(leftPad, topPad);

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    const tickCount = 6;
    for (var i = 0; i <= tickCount; i++) {
      final value = maxY * i / tickCount;
      final y = origin.dy + plotH * (1 - i / tickCount);
      canvas.drawLine(
        Offset(origin.dx, y),
        Offset(origin.dx + plotW, y),
        gridPaint,
      );
      _drawText(
        canvas,
        value.toStringAsFixed(0),
        Offset(origin.dx - 6, y),
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddle: true,
      );
    }

    final n = adaptive.length;
    double xAt(int i) => origin.dx + plotW * (i / (n - 1));
    double yAt(double v) => origin.dy + plotH * (1 - (v / maxY).clamp(0, 1));

    for (var i = 0; i < n; i++) {
      _drawText(
        canvas,
        xLabels[i],
        Offset(xAt(i), origin.dy + plotH + 6),
        align: TextAlign.center,
        anchorCenter: true,
      );
    }

    _drawSeries(
      canvas,
      points: [for (var i = 0; i < n; i++) Offset(xAt(i), yAt(staticSweep[i]))],
      color: AppColors.chartGrey,
      dashed: true,
      fillMarker: false,
    );
    _drawSeries(
      canvas,
      points: [for (var i = 0; i < n; i++) Offset(xAt(i), yAt(adaptive[i]))],
      color: AppColors.chartGreen,
      dashed: false,
      fillMarker: true,
    );
  }

  void _drawSeries(
    Canvas canvas, {
    required List<Offset> points,
    required Color color,
    required bool dashed,
    required bool fillMarker,
  }) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = dashed ? 1.5 : 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (dashed) {
      _drawDashedPath(canvas, path, linePaint);
    } else {
      canvas.drawPath(path, linePaint);
    }

    for (final p in points) {
      if (fillMarker) {
        canvas.drawCircle(p, 4, Paint()..color = color);
        canvas.drawCircle(
          p,
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else {
        canvas.drawCircle(p, 3, Paint()..color = AppColors.surface);
        canvas.drawCircle(
          p,
          3,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required TextAlign align,
    bool anchorRight = false,
    bool anchorCenter = false,
    bool anchorMiddle = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();

    var dx = offset.dx;
    var dy = offset.dy;
    if (anchorRight) {
      dx -= tp.width;
    } else if (anchorCenter) {
      dx -= tp.width / 2;
    }
    if (anchorMiddle) {
      dy -= tp.height / 2;
    }
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.adaptive != adaptive ||
        oldDelegate.staticSweep != staticSweep;
  }
}

class _CoordinationModesCard extends StatelessWidget {
  const _CoordinationModesCard();

  static const _segments = [
    _DonutSegment('Grid sweep', 22, AppColors.chartGreen),
    _DonutSegment('Sector relay', 26, AppColors.chartBlue),
    _DonutSegment('Risk-weighted', 18, AppColors.chartOrange),
    _DonutSegment('Adaptive swarm', 34, AppColors.chartRed),
  ];

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Coordination Modes',
            subtitle: 'Strategy share in last 100 runs',
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _DonutPainter(segments: _segments),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              for (final s in _segments)
                SizedBox(
                  width: 130,
                  child: _LegendDot(color: s.color, label: s.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutSegment {
  const _DonutSegment(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments});

  final List<_DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    const strokeWidth = 26.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const gap = 0.04;
    var start = -math.pi / 2 + gap / 2;

    for (final s in segments) {
      final sweep = (s.value / total) * 2 * math.pi - gap;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => false;
}
