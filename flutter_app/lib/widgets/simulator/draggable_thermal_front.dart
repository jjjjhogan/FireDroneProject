import 'package:flutter/material.dart';

import '../../models/thermal_front.dart';

class DraggableThermalFront extends StatelessWidget {
  const DraggableThermalFront({
    required this.thermalFront,
    required this.isSelected,
    required this.mapSize,
    required this.draggable,
    required this.onSelect,
    required this.onMoved,
    super.key,
  });

  final ThermalFront thermalFront;
  final bool isSelected;
  final Size mapSize;
  final bool draggable;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMoved;

  @override
  Widget build(BuildContext context) {
    final left = thermalFront.normalizedPosition.dx * mapSize.width - 20;
    final top = thermalFront.normalizedPosition.dy * mapSize.height - 20;

    return Positioned(
      left: left.clamp(0, mapSize.width - 40),
      top: top.clamp(0, mapSize.height - 40),
      child: GestureDetector(
        onTap: onSelect,
        onPanUpdate: draggable
            ? (details) {
                final next = Offset(
                  (thermalFront.normalizedPosition.dx * mapSize.width +
                          details.delta.dx) /
                      mapSize.width,
                  (thermalFront.normalizedPosition.dy * mapSize.height +
                          details.delta.dy) /
                      mapSize.height,
                );
                onMoved(
                  Offset(
                    next.dx.clamp(0.06, 0.94),
                    next.dy.clamp(0.06, 0.94),
                  ),
                );
              }
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xffc2542d),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xffffd166),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffc2542d).withValues(alpha: 0.45),
                    blurRadius: isSelected ? 16 : 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 22,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xfffff4ef),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xfff0c4b4)),
                ),
                child: Text(
                  thermalFront.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff8a3b1f),
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
