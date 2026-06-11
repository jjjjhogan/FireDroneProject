import 'package:flutter/material.dart';

import '../../models/route_point.dart';
import '../../models/thermal_front.dart';
import '../../utils/route_geometry.dart';

class SimulationRoutePainter extends CustomPainter {
  SimulationRoutePainter({
    required this.routePoints,
    required this.thermalFront,
    this.playbackPosition,
  });

  final List<RoutePoint> routePoints;
  final ThermalFront thermalFront;
  final Offset? playbackPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x88d9e6e1)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final hazardCenter = Offset(
      thermalFront.normalizedPosition.dx * size.width,
      thermalFront.normalizedPosition.dy * size.height,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: hazardCenter,
        width: size.width * thermalFront.normalizedRadiusX * 2,
        height: size.height * thermalFront.normalizedRadiusY * 2,
      ),
      Paint()..color = const Color(0x55f05d2f),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: hazardCenter,
        width: size.width * thermalFront.normalizedRadiusX * 2,
        height: size.height * thermalFront.normalizedRadiusY * 2,
      ),
      Paint()
        ..color = const Color(0xffc2542d)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (routePoints.length >= 2) {
      for (var i = 0; i < routePoints.length - 1; i++) {
        final start = Offset(
          routePoints[i].normalizedPosition.dx * size.width,
          routePoints[i].normalizedPosition.dy * size.height,
        );
        final end = Offset(
          routePoints[i + 1].normalizedPosition.dx * size.width,
          routePoints[i + 1].normalizedPosition.dy * size.height,
        );
        final crossesFire = RouteGeometry.segmentCrossesThermalFront(
          routePoints[i].normalizedPosition,
          routePoints[i + 1].normalizedPosition,
          thermalFront,
        );
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = crossesFire
                ? const Color(0xffd94848)
                : const Color(0xff0e7656)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    if (playbackPosition != null) {
      final droneCenter = Offset(
        playbackPosition!.dx * size.width,
        playbackPosition!.dy * size.height,
      );
      canvas.drawCircle(
        droneCenter,
        16,
        Paint()..color = const Color(0x440e7656),
      );
      canvas.drawCircle(droneCenter, 10, Paint()..color = Colors.white);
      canvas.drawCircle(
        droneCenter,
        10,
        Paint()
          ..color = const Color(0xff10231d)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final arm = Paint()
        ..color = const Color(0xff10231d)
        ..strokeWidth = 2;
      canvas.drawLine(
        droneCenter.translate(-14, 0),
        droneCenter.translate(14, 0),
        arm,
      );
      canvas.drawLine(
        droneCenter.translate(0, -14),
        droneCenter.translate(0, 14),
        arm,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SimulationRoutePainter oldDelegate) {
    if (oldDelegate.playbackPosition != playbackPosition) {
      return true;
    }
    if (oldDelegate.routePoints.length != routePoints.length) {
      return true;
    }
    for (var i = 0; i < routePoints.length; i++) {
      if (oldDelegate.routePoints[i].normalizedPosition !=
          routePoints[i].normalizedPosition) {
        return true;
      }
    }
    return oldDelegate.thermalFront.normalizedPosition !=
        thermalFront.normalizedPosition;
  }
}
