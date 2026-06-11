import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_scenarios.dart';
import '../models/drone_connection.dart';
import '../models/scenario.dart';
import '../models/simulation_layout.dart';
import '../services/drone_api_client.dart';
import '../utils/route_geometry.dart';
import '../widgets/common/info_card.dart';
import '../widgets/common/metric_card.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_pill.dart';
import '../widgets/simulator/simulation_metrics_panel.dart';
import '../widgets/simulator/simulator_map.dart';

class LiveSimulatorScreen extends StatefulWidget {
  const LiveSimulatorScreen({
    required this.scenario,
    required this.droneClient,
    required this.onScenarioChanged,
    super.key,
  });

  final Scenario scenario;
  final DroneApiClient droneClient;
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
  late Future<DjiStatus> _statusFuture;
  late Future<List<DroneSummary>> _fleetFuture;
  late Future<TelemetrySnapshot> _telemetryFuture;
  late Future<MissionPreview> _previewFuture;
  MissionConfirmResult? _confirmResult;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _loadLayoutForScenario(widget.scenario);
    _loadDjiData();
  }

  @override
  void didUpdateWidget(covariant LiveSimulatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scenario != widget.scenario) {
      _stopTimer();
      _loadLayoutForScenario(widget.scenario);
      _loadDjiData();
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

  void _loadDjiData() {
    _statusFuture = widget.droneClient.fetchStatus();
    _fleetFuture = widget.droneClient.fetchFleet();
    _telemetryFuture = widget.droneClient.fetchTelemetry();
    _previewFuture = widget.droneClient.previewMission(
      scenario: widget.scenario,
      layout: _layout,
    );
    _confirmResult = null;
  }

  void _refreshMissionPreview() {
    _previewFuture = widget.droneClient.previewMission(
      scenario: widget.scenario,
      layout: _layout,
    );
    _confirmResult = null;
  }

  void _loadLayoutForScenario(Scenario scenario) {
    _layout = cloneLayout(defaultLayoutForScenario(scenario));
    _progress = 0;
    _runState = SimulationRunState.idle;
    _selectedRoutePointId = _layout.routePoints.isNotEmpty
        ? _layout.routePoints.first.id
        : null;
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
      _progress += elapsed.inMilliseconds / _runDuration.inMilliseconds;
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
      final index = _layout.routePoints.indexWhere(
        (point) => point.id == pointId,
      );
      if (index == -1) {
        return;
      }
      _layout.routePoints[index].normalizedPosition = normalizedPosition;
      _selectedRoutePointId = pointId;
      _thermalFrontSelected = false;
      _refreshMissionPreview();
    });
  }

  void _moveThermalFront(Offset normalizedPosition) {
    setState(() {
      _layout.thermalFront.normalizedPosition = normalizedPosition;
      _thermalFrontSelected = true;
      _selectedRoutePointId = null;
      _refreshMissionPreview();
    });
  }

  Future<void> _confirmMissionPackage() async {
    setState(() => _confirming = true);
    final preview = await _previewFuture;
    final result = await widget.droneClient.confirmMission(preview);
    if (!mounted) {
      return;
    }
    setState(() {
      _confirmResult = result;
      _confirming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Live Simulator',
          subtitle:
              'DJI Mission Preview keeps aircraft commands gated until a human confirms.',
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
                    ? () => setState(() {
                        _loadLayoutForScenario(widget.scenario);
                        _refreshMissionPreview();
                      })
                    : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset layout'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<DjiStatus>(
          future: _statusFuture,
          builder: (context, snapshot) {
            final status = snapshot.data;
            return DjiLinkBanner(
              connector: status?.connector ?? 'mock',
              commandEnabled: status?.commandEnabled ?? false,
              adapters:
                  status?.reservedAdapters ??
                  const ['DJI Cloud API', 'DJI Mobile SDK Bridge'],
            );
          },
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
        FutureBuilder<TelemetrySnapshot>(
          future: _telemetryFuture,
          builder: (context, snapshot) {
            final telemetry =
                snapshot.data?.toSimulationTelemetry(
                  routeCrossesFire: _routeCrossesFire,
                ) ??
                _telemetry;
            return SimulationMetricsPanel(
              scenarioName: widget.scenario.name,
              runState: _runState,
              telemetry: telemetry,
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<DroneSummary>>(
          future: _fleetFuture,
          builder: (context, snapshot) {
            final fleet = snapshot.data ?? const <DroneSummary>[];
            return ResponsiveGrid(
              children: [
                MetricCard(
                  icon: Icons.flight_takeoff,
                  label: 'Connected Drones',
                  value:
                      '${fleet.where((drone) => drone.connection != 'charging').length}',
                  detail: fleet.isEmpty
                      ? 'Waiting for DJI fleet feed'
                      : '${fleet.first.name} · ${fleet.first.batteryPct}% battery',
                ),
                MetricCard(
                  icon: Icons.sensors,
                  label: 'Telemetry Link',
                  value: 'Stable',
                  detail: 'Mock feed mirrors the future DJI adapter contract',
                ),
                MetricCard(
                  icon: Icons.security,
                  label: 'Command Gate',
                  value: 'Locked',
                  detail: 'Mission dispatch requires manual backend enablement',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<MissionPreview>(
          future: _previewFuture,
          builder: (context, snapshot) {
            return MissionPreviewPanel(
              preview: snapshot.data,
              confirmResult: _confirmResult,
              confirming: _confirming,
              onConfirm: _confirmMissionPackage,
            );
          },
        ),
      ],
    );
  }
}

class DjiLinkBanner extends StatelessWidget {
  const DjiLinkBanner({
    required this.connector,
    required this.commandEnabled,
    required this.adapters,
    super.key,
  });

  final String connector;
  final bool commandEnabled;
  final List<String> adapters;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      color: const Color(0xff10231d),
      borderColor: const Color(0xff2b5849),
      child: Row(
        children: [
          const Icon(Icons.radar, color: Color(0xffffc857), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DJI Link',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$connector connector · ${adapters.join(' + ')} reserved',
                  style: const TextStyle(color: Color(0xffc9ddd5)),
                ),
              ],
            ),
          ),
          StatusPill(
            label: commandEnabled ? 'Commands enabled' : 'Command gate locked',
            color: commandEnabled
                ? const Color(0xffb7f1d8)
                : const Color(0xffffc857),
          ),
        ],
      ),
    );
  }
}

class MissionPreviewPanel extends StatelessWidget {
  const MissionPreviewPanel({
    required this.preview,
    required this.confirmResult,
    required this.confirming,
    required this.onConfirm,
    super.key,
  });

  final MissionPreview? preview;
  final MissionConfirmResult? confirmResult;
  final bool confirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final warnings = preview?.warnings ?? const <String>[];
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'DJI Mission Preview',
            subtitle:
                'Review route, altitude, risk, and safety gate before dispatch.',
            trailing: StatusPill(
              label: 'Command gate locked',
              color: const Color(0xffffc857),
            ),
          ),
          const SizedBox(height: 14),
          ResponsiveGrid(
            children: [
              MetricCard(
                icon: Icons.route,
                label: 'Route points',
                value: '${preview?.routePoints.length ?? 0}',
                detail: 'Editable patrol route synced into preview payload',
              ),
              MetricCard(
                icon: Icons.schedule,
                label: 'Estimated time',
                value: '${preview?.estimatedDurationMin ?? 0} min',
                detail: 'Mock DJI package duration estimate',
              ),
              MetricCard(
                icon: Icons.height,
                label: 'Max altitude',
                value: '${preview?.maxAltitudeM ?? 0} m',
                detail: 'Safety ceiling for mission preview',
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Color(0xffc2542d),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(warning)),
                ],
              ),
            ),
          if (confirmResult != null) ...[
            const SizedBox(height: 8),
            Text(
              confirmResult!.accepted
                  ? 'Mission accepted: ${confirmResult!.missionId}'
                  : confirmResult!.blockedReason ?? 'Mission blocked',
              style: const TextStyle(
                color: Color(0xff7c2d12),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(confirmResult!.nextRequiredAction),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: confirming || preview == null ? null : onConfirm,
            icon: Icon(confirming ? Icons.hourglass_top : Icons.lock_outline),
            label: Text(
              confirming ? 'Confirming...' : 'Confirm mission package',
            ),
          ),
        ],
      ),
    );
  }
}
