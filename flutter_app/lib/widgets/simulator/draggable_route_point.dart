import 'package:flutter/material.dart';

import '../../models/route_point.dart';

class DraggableRoutePoint extends StatelessWidget {
  const DraggableRoutePoint({
    required this.point,
    required this.isSelected,
    required this.mapSize,
    required this.draggable,
    required this.onSelect,
    required this.onMoved,
    super.key,
  });

  final RoutePoint point;
  final bool isSelected;
  final Size mapSize;
  final bool draggable;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMoved;

  Color get _color => switch (point.role) {
    RoutePointRole.start => const Color(0xff10231d),
    RoutePointRole.checkpoint => const Color(0xff0e7656),
    RoutePointRole.end => const Color(0xff2f7d9a),
  };

  IconData get _icon => switch (point.role) {
    RoutePointRole.start => Icons.play_arrow_rounded,
    RoutePointRole.checkpoint => Icons.flag_outlined,
    RoutePointRole.end => Icons.stop_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final left = point.normalizedPosition.dx * mapSize.width - 18;
    final top = point.normalizedPosition.dy * mapSize.height - 18;

    return Positioned(
      left: left.clamp(0, mapSize.width - 36),
      top: top.clamp(0, mapSize.height - 36),
      child: GestureDetector(
        onTap: onSelect,
        onPanUpdate: draggable
            ? (details) {
                final next = Offset(
                  (point.normalizedPosition.dx * mapSize.width +
                          details.delta.dx) /
                      mapSize.width,
                  (point.normalizedPosition.dy * mapSize.height +
                          details.delta.dy) /
                      mapSize.height,
                );
                onMoved(
                  Offset(next.dx.clamp(0.04, 0.96), next.dy.clamp(0.04, 0.96)),
                );
              }
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.35),
                    blurRadius: isSelected ? 14 : 8,
                  ),
                ],
              ),
              child: Icon(_icon, color: Colors.white, size: 18),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xffdfe8e4)),
                ),
                child: Text(
                  point.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff10231d),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
