import 'package:flutter/material.dart';

import '../../models/simulation_layout.dart';
import '../../painters/simulation_route_painter.dart';
import '../common/info_card.dart';
import '../common/status_pill.dart';
import 'draggable_route_point.dart';
import 'draggable_thermal_front.dart';
import 'simulation_controls.dart';

class SimulatorMap extends StatefulWidget {
  const SimulatorMap({
    required this.scenarioName,
    required this.scenarioColor,
    required this.scenarioImage,
    required this.layout,
    required this.runState,
    required this.progress,
    required this.playbackPosition,
    required this.selectedRoutePointId,
    required this.thermalFrontSelected,
    required this.editingEnabled,
    required this.onStartRun,
    required this.onPauseRun,
    required this.onResetRun,
    required this.onRoutePointMoved,
    required this.onThermalFrontMoved,
    required this.onRoutePointSelected,
    required this.onThermalFrontSelected,
    super.key,
  });

  final String scenarioName;
  final Color scenarioColor;
  final String scenarioImage;
  final SimulationLayout layout;
  final SimulationRunState runState;
  final double progress;
  final Offset? playbackPosition;
  final String? selectedRoutePointId;
  final bool thermalFrontSelected;
  final bool editingEnabled;
  final VoidCallback onStartRun;
  final VoidCallback onPauseRun;
  final VoidCallback onResetRun;
  final void Function(String pointId, Offset normalizedPosition) onRoutePointMoved;
  final ValueChanged<Offset> onThermalFrontMoved;
  final ValueChanged<String> onRoutePointSelected;
  final VoidCallback onThermalFrontSelected;

  @override
  State<SimulatorMap> createState() => _SimulatorMapState();
}

class _SimulatorMapState extends State<SimulatorMap> {
  Size _mapSize = Size.zero;

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
                      widget.scenarioImage,
                      fit: BoxFit.cover,
                      semanticLabel: 'Map terrain for ${widget.scenarioName}',
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
                        routePoints: widget.layout.routePoints,
                        thermalFront: widget.layout.thermalFront,
                        playbackPosition: widget.playbackPosition,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: StatusPill(
                      label: widget.scenarioName,
                      color: widget.scenarioColor,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 52,
                    child: StatusPill(
                      label: 'Fire zone is independent of patrol route',
                      color: const Color(0xe6fff4ef),
                    ),
                  ),
                  for (final point in widget.layout.routePoints)
                    DraggableRoutePoint(
                      point: point,
                      isSelected: widget.selectedRoutePointId == point.id &&
                          !widget.thermalFrontSelected,
                      mapSize: _mapSize,
                      draggable: widget.editingEnabled,
                      onSelect: () => widget.onRoutePointSelected(point.id),
                      onMoved: (position) =>
                          widget.onRoutePointMoved(point.id, position),
                    ),
                  DraggableThermalFront(
                    thermalFront: widget.layout.thermalFront,
                    isSelected: widget.thermalFrontSelected,
                    mapSize: _mapSize,
                    draggable: widget.editingEnabled,
                    onSelect: widget.onThermalFrontSelected,
                    onMoved: widget.onThermalFrontMoved,
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: SimulationControls(
                      runState: widget.runState,
                      progress: widget.progress,
                      onStart: widget.onStartRun,
                      onPause: widget.onPauseRun,
                      onReset: widget.onResetRun,
                    ),
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
