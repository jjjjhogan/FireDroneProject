import 'package:flutter/material.dart';

import '../models/simulation_point.dart';

class SimulationRoutePainter extends CustomPainter {
  SimulationRoutePainter({
    required this.points,
    required this.hazardPoint,
  });

  final List<SimulationPoint> points;
  final SimulationPoint? hazardPoint;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x44ffffff), Color(0x11ffffff)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final grid = Paint()
      ..color = const Color(0x88d9e6e1)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (hazardPoint != null) {
      final hazardCenter = Offset(
        hazardPoint!.normalizedPosition.dx * size.width,
        hazardPoint!.normalizedPosition.dy * size.height,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: hazardCenter,
          width: size.width * 0.28,
          height: size.height * 0.42,
        ),
        Paint()..color = const Color(0x44f05d2f),
      );
    }

    if (points.length >= 2) {
      final route = Path();
      for (var i = 0; i < points.length; i++) {
        final offset = Offset(
          points[i].normalizedPosition.dx * size.width,
          points[i].normalizedPosition.dy * size.height,
        );
        if (i == 0) {
          route.moveTo(offset.dx, offset.dy);
        } else {
          route.lineTo(offset.dx, offset.dy);
        }
      }
      canvas.drawPath(
        route,
        Paint()
          ..color = const Color(0xff0e7656)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SimulationRoutePainter oldDelegate) {
    if (oldDelegate.points.length != points.length) {
      return true;
    }
    for (var i = 0; i < points.length; i++) {
      if (oldDelegate.points[i].normalizedPosition !=
          points[i].normalizedPosition) {
        return true;
      }
    }
    return oldDelegate.hazardPoint?.normalizedPosition !=
        hazardPoint?.normalizedPosition;
  }
}
