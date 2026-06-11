import 'dart:math' as math;

import 'package:flutter/material.dart';

class TerrainPainter extends CustomPainter {
  TerrainPainter({required this.seed, required this.night});

  final int seed;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: night
            ? const [Color(0xff12352d), Color(0xff0c1715)]
            : const [Color(0xffdbeee8), Color(0xffffe0b5)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final random = math.Random(seed);
    for (var layer = 0; layer < 4; layer++) {
      final path = Path()..moveTo(0, size.height);
      final base = size.height * (0.45 + layer * 0.13);
      for (var x = 0.0; x <= size.width + 30; x += 34) {
        final wave =
            math.sin((x / size.width * math.pi * 2) + layer + seed) * 18;
        final jitter = (random.nextDouble() - 0.5) * 20;
        path.lineTo(x, base + wave + jitter);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      final color = night
          ? [
              const Color(0xff1f5748),
              const Color(0xff173c34),
              const Color(0xff102a25),
              const Color(0xff0b1b18),
            ][layer]
          : [
              const Color(0xff8ec7a4),
              const Color(0xff6aa37f),
              const Color(0xff4b795f),
              const Color(0xff315241),
            ][layer];
      canvas.drawPath(path, Paint()..color = color);
    }

    final fire = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0xffffd166), Color(0xffff7d3b), Color(0x00ff7d3b)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.72, size.height * 0.58),
              radius: size.shortestSide * 0.33,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.58),
      size.shortestSide * 0.34,
      fire,
    );

    final dronePaint = Paint()
      ..color = night ? Colors.white : const Color(0xff10231d)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final center = Offset(
        size.width * (0.22 + i * 0.22),
        size.height * (0.24 + i * 0.06),
      );
      canvas.drawCircle(center, 9, dronePaint);
      canvas.drawLine(
        center.translate(-18, 0),
        center.translate(18, 0),
        dronePaint,
      );
      canvas.drawLine(
        center.translate(0, -18),
        center.translate(0, 18),
        dronePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TerrainPainter oldDelegate) {
    return seed != oldDelegate.seed || night != oldDelegate.night;
  }
}
