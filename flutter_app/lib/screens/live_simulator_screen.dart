import 'package:flutter/material.dart';

import '../data/mock_scenarios.dart';
import '../models/scenario.dart';
import '../models/simulation_point.dart';
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
  late List<SimulationPoint> _points;
  String? _selectedPointId;

  @override
  void initState() {
    super.initState();
    _loadPointsForScenario(widget.scenario);
  }

  @override
  void didUpdateWidget(covariant LiveSimulatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scenario != widget.scenario) {
      _loadPointsForScenario(widget.scenario);
    }
  }

  void _loadPointsForScenario(Scenario scenario) {
    _points = defaultPointsForScenario(scenario)
        .map((point) => point.copyWith())
        .toList();
    _selectedPointId = _points.isNotEmpty ? _points.first.id : null;
  }

  SimulationPoint? get _activePoint {
    if (_selectedPointId == null) {
      return null;
    }
    for (final point in _points) {
      if (point.id == _selectedPointId) {
        return point;
      }
    }
    return null;
  }

  void _movePoint(String pointId, Offset normalizedPosition) {
    setState(() {
      final index = _points.indexWhere((point) => point.id == pointId);
      if (index == -1) {
        return;
      }
      _points[index].normalizedPosition = normalizedPosition;
      _selectedPointId = pointId;
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
                onChanged: (scenario) {
                  if (scenario != null) {
                    widget.onScenarioChanged(scenario);
                  }
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(
                  () => _loadPointsForScenario(widget.scenario),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset points'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SimulatorMap(
          scenario: widget.scenario,
          points: _points,
          selectedPointId: _selectedPointId,
          onPointMoved: _movePoint,
          onPointSelected: (pointId) {
            setState(() => _selectedPointId = pointId);
          },
        ),
        const SizedBox(height: 16),
        SimulationMetricsPanel(
          scenarioName: widget.scenario.name,
          activePoint: _activePoint,
        ),
      ],
    );
  }
}
