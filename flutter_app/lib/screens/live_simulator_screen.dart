import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_scenarios.dart';
import '../models/scenario.dart';
import '../models/simulation_layout.dart';
import '../utils/route_geometry.dart';
import '../widgets/common/section_header.dart';
import '../widgets/simulator/simulation_metrics_panel.dart';
import '../widgets/simulator/simulator_map.dart';

class LiveSimulatorScreen extends StatefulWidget {
  const LiveSimulatorScreen({
    required this.scenario,
    required this.onScenarioChanged,
    super.key,
  });

  final Scenario scenario;
  final ValueChanged<Scenario> onScenarioChanged;

  @override
  State<LiveSimulatorScreen> createState() => _LiveSimulatorScreenState();
}

class _LiveSimulatorScreenState extends State<LiveSimulatorScreen> {
  static const _runDuration = Duration(seconds: 12);

  late SimulationLayout _layout;
  SimulationRunState _runState = SimulationRunState.idle;
  double _progress = 0;
  String? _selectedRoutePointId;
  bool _thermalFrontSelected = false;
  Timer? _timer;
  DateTime? _lastTick;

  @override
  void initState() {
    super.initState();
    _loadLayoutForScenario(widget.scenario);
  }

  @override
  void didUpdateWidget(covariant LiveSimulatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scenario != widget.scenario) {
      _stopTimer();
      _loadLayoutForScenario(widget.scenario);
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  bool get _editingEnabled =>
      _runState == SimulationRunState.idle ||
      _runState == SimulationRunState.paused ||
      _runState == SimulationRunState.complete;

  bool get _routeCrossesFire => RouteGeometry.routeCrossesThermalFront(
        _layout.routePoints,
        _layout.thermalFront,
      );

  Offset? get _playbackPosition {
    if (_runState == SimulationRunState.idle && _progress == 0) {
      return null;
    }
    return RouteGeometry.positionAtProgress(_layout.routePoints, _progress);
  }

  SimulationTelemetry get _telemetry {
    final progress = _runState == SimulationRunState.idle && _progress == 0
        ? 0.0
        : _progress;
    return RouteGeometry.telemetryAtProgress(
      route: _layout.routePoints,
      thermalFront: _layout.thermalFront,
      progress: progress,
      routeCrossesFire: _routeCrossesFire,
    );
  }

  void _loadLayoutForScenario(Scenario scenario) {
    _layout = cloneLayout(defaultLayoutForScenario(scenario));
    _progress = 0;
    _runState = SimulationRunState.idle;
    _selectedRoutePointId =
        _layout.routePoints.isNotEmpty ? _layout.routePoints.first.id : null;
    _thermalFrontSelected = false;
  }

  void _startRun() {
    if (_runState == SimulationRunState.complete) {
      _progress = 0;
    }
    _lastTick = DateTime.now();
    _runState = SimulationRunState.running;
    _thermalFrontSelected = false;
    _timer ??= Timer.periodic(const Duration(milliseconds: 50), _onTick);
    setState(() {});
  }

  void _pauseRun() {
    _runState = SimulationRunState.paused;
    _stopTimer();
    setState(() {});
  }

  void _resetRun() {
    _stopTimer();
    setState(() {
      _progress = 0;
      _runState = SimulationRunState.idle;
    });
  }

  void _onTick(Timer timer) {
    final now = DateTime.now();
    final elapsed = _lastTick == null
        ? Duration.zero
        : now.difference(_lastTick!);
    _lastTick = now;

    setState(() {
      _progress +=
          elapsed.inMilliseconds / _runDuration.inMilliseconds;
      if (_progress >= 1) {
        _progress = 1;
        _runState = SimulationRunState.complete;
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _lastTick = null;
  }

  void _moveRoutePoint(String pointId, Offset normalizedPosition) {
    setState(() {
      final index =
          _layout.routePoints.indexWhere((point) => point.id == pointId);
      if (index == -1) {
        return;
      }
      _layout.routePoints[index].normalizedPosition = normalizedPosition;
      _selectedRoutePointId = pointId;
      _thermalFrontSelected = false;
    });
  }

  void _moveThermalFront(Offset normalizedPosition) {
    setState(() {
      _layout.thermalFront.normalizedPosition = normalizedPosition;
      _thermalFrontSelected = true;
      _selectedRoutePointId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Live Simulator',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Scenario>(
                value: widget.scenario,
                items: scenarios
                    .map(
                      (scenario) => DropdownMenuItem(
                        value: scenario,
                        child: Text(scenario.name),
                      ),
                    )
                    .toList(),
                onChanged: _editingEnabled
                    ? (scenario) {
                        if (scenario != null) {
                          widget.onScenarioChanged(scenario);
                        }
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _editingEnabled
                    ? () => setState(
                          () => _loadLayoutForScenario(widget.scenario),
                        )
                    : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset layout'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SimulatorMap(
          scenarioName: widget.scenario.name,
          scenarioColor: widget.scenario.color,
          scenarioImage: widget.scenario.image,
          layout: _layout,
          runState: _runState,
          progress: _progress,
          playbackPosition: _playbackPosition,
          selectedRoutePointId: _selectedRoutePointId,
          thermalFrontSelected: _thermalFrontSelected,
          editingEnabled: _editingEnabled,
          onStartRun: _startRun,
          onPauseRun: _pauseRun,
          onResetRun: _resetRun,
          onRoutePointMoved: _moveRoutePoint,
          onThermalFrontMoved: _moveThermalFront,
          onRoutePointSelected: (pointId) {
            setState(() {
              _selectedRoutePointId = pointId;
              _thermalFrontSelected = false;
            });
          },
          onThermalFrontSelected: () {
            setState(() {
              _thermalFrontSelected = true;
              _selectedRoutePointId = null;
            });
          },
        ),
        const SizedBox(height: 16),
        SimulationMetricsPanel(
          scenarioName: widget.scenario.name,
          runState: _runState,
          telemetry: _telemetry,
        ),
      ],
    );
  }
}
