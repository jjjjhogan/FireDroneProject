import 'package:flutter/material.dart';

import '../../models/scenario.dart';
import '../../models/simulation_point.dart';
import '../../painters/simulation_route_painter.dart';
import '../common/info_card.dart';
import '../common/status_pill.dart';
import 'draggable_simulation_point.dart';

class SimulatorMap extends StatefulWidget {
  const SimulatorMap({
    required this.scenario,
    required this.points,
    required this.selectedPointId,
    required this.onPointMoved,
    required this.onPointSelected,
    super.key,
  });

  final Scenario scenario;
  final List<SimulationPoint> points;
  final String? selectedPointId;
  final void Function(String pointId, Offset normalizedPosition) onPointMoved;
  final ValueChanged<String> onPointSelected;

  @override
  State<SimulatorMap> createState() => _SimulatorMapState();
}

class _SimulatorMapState extends State<SimulatorMap> {
  Size _mapSize = Size.zero;

  SimulationPoint? get _hazardPoint {
    for (final point in widget.points) {
      if (point.type == SimulationPointType.hazard) {
        return point;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _mapSize = Size(constraints.maxWidth, 360);
          return SizedBox(
            height: 360,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      widget.scenario.image,
                      fit: BoxFit.cover,
                      semanticLabel:
                          'Map terrain for ${widget.scenario.name}',
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SimulationRoutePainter(
                        points: widget.points,
                        hazardPoint: _hazardPoint,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: StatusPill(
                      label: widget.scenario.name,
                      color: widget.scenario.color,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: StatusPill(
                      label: 'Drag points to adjust patrol route',
                      color: const Color(0xe6ffffff),
                    ),
                  ),
                  for (final point in widget.points)
                    DraggableSimulationPoint(
                      point: point,
                      isSelected: widget.selectedPointId == point.id,
                      mapSize: _mapSize,
                      onSelect: () => widget.onPointSelected(point.id),
                      onMoved: (position) =>
                          widget.onPointMoved(point.id, position),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
