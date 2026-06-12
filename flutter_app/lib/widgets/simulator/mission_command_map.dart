import 'dart:math' as math;

import 'package:flutter/material.dart';

class MissionCommandMap extends StatelessWidget {
  const MissionCommandMap({
    required this.missionAvailable,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
    super.key,
  });

  final bool missionAvailable;
  final VoidCallback onStartMission;
  final VoidCallback onPause;
  final VoidCallback onAbort;

  static const _centerLat = 34.62;
  static const _centerLng = -119.72;
  static const _zoom = 11;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 410,
      decoration: BoxDecoration(
        color: const Color(0xff0c1715),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffd2d8d5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: OsmTileLayer()),
          Positioned.fill(
            child: Image.asset(
              'assets/images/mission-map-fallback.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.76),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
              ),
            ),
          ),
          const Positioned.fill(child: FireMissionOverlay()),
          const Positioned(left: 16, top: 14, child: MapTitlePill()),
          const Positioned(left: 16, top: 72, child: MapToolRail()),
          const Positioned(right: 16, top: 16, child: MapLayerRail()),
          const Positioned(right: 16, bottom: 78, child: MapZoomRail()),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: MapCommandControls(
              missionAvailable: missionAvailable,
              onStartMission: onStartMission,
              onPause: onPause,
              onAbort: onAbort,
            ),
          ),
          const Positioned(left: 18, bottom: 82, child: MapScale()),
          const Positioned(right: 14, bottom: 82, child: OsmAttribution()),
        ],
      ),
    );
  }
}

class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key});

  static int _tileX(double lng, int zoom) {
    return (((lng + 180) / 360) * math.pow(2, zoom)).floor();
  }

  static int _tileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180;
    return ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2 *
            math.pow(2, zoom))
        .floor();
  }

  @override
  Widget build(BuildContext context) {
    final centerX = _tileX(
      MissionCommandMap._centerLng,
      MissionCommandMap._zoom,
    );
    final centerY = _tileY(
      MissionCommandMap._centerLat,
      MissionCommandMap._zoom,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth / 4;
        final tileHeight = constraints.maxHeight / 3;
        return Stack(
          children: [
            for (var row = 0; row < 3; row++)
              for (var col = 0; col < 4; col++)
                Positioned(
                  left: col * tileWidth,
                  top: row * tileHeight,
                  width: tileWidth + 1,
                  height: tileHeight + 1,
                  child: Image.network(
                    'https://tile.openstreetmap.org/${MissionCommandMap._zoom}/${centerX + col - 2}/${centerY + row - 1}.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/mission-map-fallback.png',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class FireMissionOverlay extends StatelessWidget {
  const FireMissionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: FireMissionPainter());
  }
}

class FireMissionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 70) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 58) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final firePath = Path()
      ..moveTo(size.width * 0.34, size.height * 0.34)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.22,
        size.width * 0.61,
        size.height * 0.27,
        size.width * 0.67,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.60,
        size.width * 0.57,
        size.height * 0.74,
        size.width * 0.43,
        size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.62,
        size.width * 0.24,
        size.height * 0.45,
        size.width * 0.34,
        size.height * 0.34,
      )
      ..close();

    canvas.drawPath(firePath, Paint()..color = const Color(0x66c2542d));
    canvas.drawPath(
      firePath,
      Paint()
        ..color = const Color(0xffe23b2f)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final route = [
      Offset(size.width * 0.48, size.height * 0.06),
      Offset(size.width * 0.66, size.height * 0.42),
      Offset(size.width * 0.47, size.height * 0.82),
      Offset(size.width * 0.28, size.height * 0.50),
    ];
    final routePaint = Paint()
      ..color = const Color(0xff22b7ae)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final routePath = Path()..moveTo(route.first.dx, route.first.dy);
    for (final point in route.skip(1)) {
      routePath.lineTo(point.dx, point.dy);
    }
    routePath.close();
    canvas.drawPath(routePath, routePaint);

    for (var i = 0; i < route.length; i++) {
      canvas.drawCircle(route[i], 13, Paint()..color = const Color(0xff16b7a8));
      canvas.drawCircle(
        route[i],
        10,
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
      _drawLabel(canvas, route[i], '${i + 1}');
    }

    final drone = Offset(size.width * 0.50, size.height * 0.50);
    canvas.drawCircle(drone, 24, Paint()..color = const Color(0x6622b7ae));
    _drawDrone(canvas, drone);

    final flames = [
      Offset(size.width * 0.43, size.height * 0.45),
      Offset(size.width * 0.53, size.height * 0.37),
      Offset(size.width * 0.58, size.height * 0.54),
      Offset(size.width * 0.47, size.height * 0.63),
      Offset(size.width * 0.36, size.height * 0.55),
    ];
    for (final point in flames) {
      canvas.drawCircle(point, 9, Paint()..color = const Color(0xffff8a00));
      canvas.drawCircle(
        point.translate(0, -3),
        5,
        Paint()..color = const Color(0xffffdf6e),
      );
    }
  }

  void _drawDrone(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center.translate(-22, 0), center.translate(22, 0), paint);
    canvas.drawLine(center.translate(0, -16), center.translate(0, 16), paint);
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
    for (final point in [
      center.translate(-22, 0),
      center.translate(22, 0),
      center.translate(0, -16),
      center.translate(0, 16),
    ]) {
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawLabel(Canvas canvas, Offset center, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapTitlePill extends StatelessWidget {
  const MapTitlePill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLANNING MAP',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'No live DJI/fire feed connected',
            style: TextStyle(color: Color(0xffd8e7e1)),
          ),
        ],
      ),
    );
  }
}

class MapToolRail extends StatelessWidget {
  const MapToolRail({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        MapToolButton(icon: Icons.navigation),
        MapToolButton(icon: Icons.location_on),
        MapToolButton(icon: Icons.polyline),
        MapToolButton(icon: Icons.hexagon_outlined),
        MapToolButton(icon: Icons.info_outline),
      ],
    );
  }
}

class MapLayerRail extends StatelessWidget {
  const MapLayerRail({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        MapToolButton(icon: Icons.layers),
        MapToolButton(label: '3D'),
        MapToolButton(icon: Icons.my_location),
      ],
    );
  }
}

class MapZoomRail extends StatelessWidget {
  const MapZoomRail({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        MapToolButton(icon: Icons.add),
        MapToolButton(icon: Icons.remove),
      ],
    );
  }
}

class MapToolButton extends StatelessWidget {
  const MapToolButton({this.icon, this.label, super.key});

  final IconData? icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: Colors.white, size: 20)
            : Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class MapCommandControls extends StatelessWidget {
  const MapCommandControls({
    required this.missionAvailable,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
    super.key,
  });

  final bool missionAvailable;
  final VoidCallback onStartMission;
  final VoidCallback onPause;
  final VoidCallback onAbort;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: compact ? 3 : 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff16845f),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: missionAvailable ? onStartMission : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    compact ? 'START\nMISSION' : 'START MISSION',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (compact) ...[
                SizedBox(
                  width: 48,
                  child: Tooltip(
                    message: 'Pause mission preview',
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xff314046)),
                        minimumSize: const Size.fromHeight(46),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: onPause,
                      child: const Icon(Icons.pause),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  child: Tooltip(
                    message: 'Abort mission preview',
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffff6157),
                        side: const BorderSide(color: Color(0xffff6157)),
                        minimumSize: const Size.fromHeight(46),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: onAbort,
                      child: const Icon(Icons.stop),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xff314046)),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('PAUSE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffff6157),
                      side: const BorderSide(color: Color(0xffff6157)),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: onAbort,
                    icon: const Icon(Icons.stop),
                    label: const Text('ABORT'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class MapScale extends StatelessWidget {
  const MapScale({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 82, child: Divider(color: Colors.white, thickness: 2)),
        Text('1 km', style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      color: Colors.white.withValues(alpha: 0.78),
      child: const Text(
        '© OpenStreetMap contributors',
        style: TextStyle(fontSize: 10, color: Color(0xff10231d)),
      ),
    );
  }
}
