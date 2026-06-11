import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Stylised mission map: grid, planned patrol route, hazard zone and waypoints.
/// Ported from the AeroScout Sim prototype and recoloured to the app theme.
class MissionMapPainter extends CustomPainter {
  const MissionMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE7F1ED), Colors.white],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      background,
    );

    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final hazard = Paint()..color = AppColors.fwiMed.withValues(alpha: 0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.54),
        width: size.width * 0.28,
        height: size.height * 0.42,
      ),
      hazard,
    );

    final route = Path()
      ..moveTo(size.width * 0.12, size.height * 0.72)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.28,
        size.width * 0.54,
        size.height * 0.82,
        size.width * 0.72,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.16,
        size.width * 0.92,
        size.height * 0.42,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final pointPaint = Paint()..color = AppColors.primary;
    for (final point in [
      Offset(size.width * 0.12, size.height * 0.72),
      Offset(size.width * 0.34, size.height * 0.38),
      Offset(size.width * 0.72, size.height * 0.36),
      Offset(size.width * 0.92, size.height * 0.42),
    ]) {
      canvas.drawCircle(
        point,
        14,
        Paint()..color = AppColors.primary.withValues(alpha: 0.15),
      );
      canvas.drawCircle(point, 6, pointPaint);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MissionMapPainter oldDelegate) => false;
}
