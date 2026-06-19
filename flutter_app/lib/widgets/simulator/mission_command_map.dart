import 'package:flutter/material.dart';

import '../../models/drone_connection.dart';
import '../../utils/map_geo.dart';

class MissionCommandMap extends StatelessWidget {
  const MissionCommandMap({
    required this.missionAvailable,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
    this.status,
    this.fleet = const [],
    this.routePoints = const [],
    super.key,
  });

  final bool missionAvailable;
  final VoidCallback onStartMission;
  final VoidCallback onPause;
  final VoidCallback onAbort;
  final DjiStatus? status;
  final List<DroneSummary> fleet;
  final List<Map<String, double>> routePoints;

  MapViewport get _viewport => MapViewport.fromFleet(fleet);

  @override
  Widget build(BuildContext context) {
    final viewport = _viewport;
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
          Positioned.fill(child: OsmTileLayer(viewport: viewport)),
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
          Positioned.fill(
            child: MissionMapOverlay(
              viewport: viewport,
              fleet: fleet,
              routePoints: routePoints,
              liveData: status?.liveData ?? false,
            ),
          ),
          Positioned(
            left: 16,
            top: 14,
            child: MapTitlePill(
              missionAvailable: missionAvailable,
              status: status,
              fleetCount: fleet.length,
            ),
          ),
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
  const OsmTileLayer({required this.viewport, super.key});

  final MapViewport viewport;

  @override
  Widget build(BuildContext context) {
    final centerX = mapTileX(viewport.centerLng, viewport.zoom);
    final centerY = mapTileY(viewport.centerLat, viewport.zoom);

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
                    'https://tile.openstreetmap.org/${viewport.zoom}/${centerX + col - 2}/${centerY + row - 1}.png',
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

class MissionMapOverlay extends StatelessWidget {
  const MissionMapOverlay({
    required this.viewport,
    required this.fleet,
    required this.routePoints,
    required this.liveData,
    super.key,
  });

  final MapViewport viewport;
  final List<DroneSummary> fleet;
  final List<Map<String, double>> routePoints;
  final bool liveData;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MissionMapPainter(
        viewport: viewport,
        fleet: fleet,
        routePoints: routePoints,
        liveData: liveData,
      ),
    );
  }
}

class MissionMapPainter extends CustomPainter {
  MissionMapPainter({
    required this.viewport,
    required this.fleet,
    required this.routePoints,
    required this.liveData,
  });

  final MapViewport viewport;
  final List<DroneSummary> fleet;
  final List<Map<String, double>> routePoints;
  final bool liveData;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    if (liveData && fleet.any(hasMapPosition)) {
      _drawLiveFleet(canvas, size);
    } else {
      _drawSimulatedMission(canvas, size);
    }

    if (routePoints.length >= 2) {
      _drawRoute(canvas, size, routePoints);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 70) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 58) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  void _drawLiveFleet(Canvas canvas, Size size) {
    for (final drone in fleet.where(hasMapPosition)) {
      final point = latLngToMapOffset(
        lat: drone.lat,
        lng: drone.lng,
        width: size.width,
        height: size.height,
        viewport: viewport,
      );
      if (point.dx < -20 ||
          point.dy < -20 ||
          point.dx > size.width + 20 ||
          point.dy > size.height + 20) {
        continue;
      }

      final accent = switch (drone.connection) {
        'online' => const Color(0xff22b7ae),
        'standby' => const Color(0xffffc857),
        _ => const Color(0xff94a3b8),
      };
      canvas.drawCircle(point, 24, Paint()..color = accent.withValues(alpha: 0.35));
      _drawDrone(canvas, point, accent);
      _drawDroneLabel(canvas, point, drone.name.split(' ').first);
    }
  }

  void _drawSimulatedMission(Canvas canvas, Size size) {
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
    _drawRoutePoints(canvas, route);

    final drone = Offset(size.width * 0.50, size.height * 0.50);
    canvas.drawCircle(drone, 24, Paint()..color = const Color(0x6622b7ae));
    _drawDrone(canvas, drone, Colors.white);

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

  void _drawRoute(Canvas canvas, Size size, List<Map<String, double>> points) {
    final offsets = points
        .map(
          (point) => latLngToMapOffset(
            lat: point['lat'] ?? 0,
            lng: point['lng'] ?? 0,
            width: size.width,
            height: size.height,
            viewport: viewport,
          ),
        )
        .toList();
    _drawRoutePoints(canvas, offsets);
  }

  void _drawRoutePoints(Canvas canvas, List<Offset> route) {
    if (route.length < 2) {
      return;
    }

    final routePaint = Paint()
      ..color = const Color(0xff22b7ae)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final routePath = Path()..moveTo(route.first.dx, route.first.dy);
    for (final point in route.skip(1)) {
      routePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(routePath, routePaint);

    for (var i = 0; i < route.length; i++) {
      canvas.drawCircle(
        route[i],
        13,
        Paint()..color = const Color(0xff16b7a8),
      );
      canvas.drawCircle(
        route[i],
        10,
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
      _drawDroneLabel(canvas, route[i], '${i + 1}');
    }
  }

  void _drawDrone(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center.translate(-22, 0), center.translate(22, 0), paint);
    canvas.drawLine(center.translate(0, -16), center.translate(0, 16), paint);
    canvas.drawCircle(center, 5, Paint()..color = color);
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
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawDroneLabel(Canvas canvas, Offset center, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center +
          Offset(-painter.width / 2, -painter.height / 2 - 28),
    );
  }

  @override
  bool shouldRepaint(covariant MissionMapPainter oldDelegate) {
    return oldDelegate.viewport.centerLat != viewport.centerLat ||
        oldDelegate.viewport.centerLng != viewport.centerLng ||
        oldDelegate.liveData != liveData ||
        oldDelegate.fleet != fleet ||
        oldDelegate.routePoints != routePoints;
  }
}

class MapTitlePill extends StatelessWidget {
  const MapTitlePill({
    required this.missionAvailable,
    this.status,
    this.fleetCount = 0,
    super.key,
  });

  final bool missionAvailable;
  final DjiStatus? status;
  final int fleetCount;

  @override
  Widget build(BuildContext context) {
    final live = status?.liveData ?? false;
    final subtitle = switch (status?.connection) {
      'bridge-online' when live =>
        '${status?.source ?? 'DJI bridge'} · $fleetCount aircraft live on map',
      'bridge-online' => 'Bridge online, waiting for aircraft telemetry',
      'waiting-for-bridge' => 'Ingest configured · waiting for bridge/cloud feed',
      'bridge-stale' => 'Bridge feed stale · check Cloud API or Mobile SDK worker',
      'configured' => 'Connector configured · start bridge ingest to go live',
      _ when missionAvailable => 'Mission preview ready from backend package',
      _ => 'Connect DJI Cloud API or Mobile SDK bridge for live aircraft',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            live ? 'LIVE OPERATIONS MAP' : 'PLANNING MAP',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xffd8e7e1)),
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
