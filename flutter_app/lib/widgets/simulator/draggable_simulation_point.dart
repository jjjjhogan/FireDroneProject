import 'package:flutter/material.dart';

import '../../models/simulation_point.dart';

class DraggableSimulationPoint extends StatelessWidget {
  const DraggableSimulationPoint({
    required this.point,
    required this.isSelected,
    required this.mapSize,
    required this.onSelect,
    required this.onMoved,
    super.key,
  });

  final SimulationPoint point;
  final bool isSelected;
  final Size mapSize;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMoved;

  Color get _color => switch (point.type) {
        SimulationPointType.drone => const Color(0xff10231d),
        SimulationPointType.checkpoint => const Color(0xff0e7656),
        SimulationPointType.hazard => const Color(0xffc2542d),
      };

  IconData get _icon => switch (point.type) {
        SimulationPointType.drone => Icons.flight,
        SimulationPointType.checkpoint => Icons.flag_outlined,
        SimulationPointType.hazard => Icons.local_fire_department_outlined,
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
        onPanUpdate: (details) {
          final next = Offset(
            (point.normalizedPosition.dx * mapSize.width + details.delta.dx) /
                mapSize.width,
            (point.normalizedPosition.dy * mapSize.height + details.delta.dy) /
                mapSize.height,
          );
          onMoved(
            Offset(
              next.dx.clamp(0.04, 0.96),
              next.dy.clamp(0.04, 0.96),
            ),
          );
        },
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
