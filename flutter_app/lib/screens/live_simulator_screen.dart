import 'package:flutter/material.dart';

import '../data/mock_scenarios.dart';
import '../models/drone_connection.dart';
import '../models/scenario.dart';
import '../models/simulation_layout.dart';
import '../services/dji_fleet_telemetry_adapter.dart';
import '../services/dji_live_feed.dart';
import '../services/drone_api_client.dart';
import '../services/operations_api_client.dart';
import '../widgets/common/info_card.dart';
import '../widgets/simulator/dji_connection_dialog.dart';
import '../models/mission.dart';
import '../services/mission_system_service.dart';
import '../widgets/simulator/mission_command_map.dart';
import '../widgets/simulator/mission_system_panel.dart';
import 'official_dashboard_screen.dart';

class LiveSimulatorScreen extends StatefulWidget {
  const LiveSimulatorScreen({
    required this.scenario,
    required this.droneClient,
    required this.operationsClient,
    required this.onScenarioChanged,
    super.key,
  });

  final Scenario scenario;
  final DroneApiClient droneClient;
  final OperationsApiClient operationsClient;
  final ValueChanged<Scenario> onScenarioChanged;

  @override
  State<LiveSimulatorScreen> createState() => _LiveSimulatorScreenState();
}

class _LiveSimulatorScreenState extends State<LiveSimulatorScreen> {
  late SimulationLayout _layout;
  late DjiLiveFeed _liveFeed;
  final MissionSystemService _missionSystem = ResilientMissionSystemService();
  MissionRecord? _missionRecord;
  late Future<MapProviderConfig> _mapConfigFuture;
  late Future<GeofenceLayer> _geofenceLayerFuture;
  late Future<MapMissionLayer> _mapMissionLayerFuture;
  MissionConfirmResult? _confirmResult;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _liveFeed = DjiLiveFeed(widget.droneClient)..addListener(_onLiveFeedUpdated);
    _loadLayoutForScenario(widget.scenario);
    _loadMapLayers();
    _bootstrapMissionSystem();
  }

  @override
  void didUpdateWidget(covariant LiveSimulatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scenario != widget.scenario) {
      _loadLayoutForScenario(widget.scenario);
      _loadMapLayers();
      _bootstrapMissionSystem(resetMission: true);
    }
  }

  Future<void> _bootstrapMissionSystem({bool resetMission = false}) async {
    if (resetMission) {
      _confirmResult = null;
    }
    await _refreshLiveFeed();
    final assignedDrone = _liveFeed.fleet.isNotEmpty
        ? _liveFeed.fleet.first.id
        : null;
    final record = await _missionSystem.planMission(
      scenario: widget.scenario,
      layout: _layout,
      assignedDroneId: assignedDrone,
      dataSource: missionDataSourceForStatus(_liveFeed.status),
    );
    if (!mounted) {
      return;
    }
    setState(() => _missionRecord = record);
  }

  @override
  void dispose() {
    _liveFeed.removeListener(_onLiveFeedUpdated);
    _liveFeed.dispose();
    super.dispose();
  }

  void _onLiveFeedUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshLiveFeed({bool resetMission = false}) async {
    if (resetMission) {
      _confirmResult = null;
    }
    await _liveFeed.refreshAll(
      scenario: widget.scenario,
      layout: _layout,
    );
  }

  void _loadLayoutForScenario(Scenario scenario) {
    _layout = cloneLayout(defaultLayoutForScenario(scenario));
  }

  void _loadMapLayers() {
    _mapConfigFuture = widget.operationsClient.fetchMapConfig();
    _geofenceLayerFuture = widget.operationsClient.fetchGeofenceLayer();
    _mapMissionLayerFuture = widget.operationsClient.fetchMapMissionLayer();
  }

  void _pauseRun() {
    _transitionMission('paused', notes: 'Mission paused by operator.');
  }

  void _resetRun() {
    _transitionMission('aborted', notes: 'Mission aborted from command map.');
    setState(() => _confirmResult = null);
  }

  Future<void> _transitionMission(
    String status, {
    String? notes,
    int? progressPct,
  }) async {
    final mission = _missionRecord;
    if (mission == null) {
      return;
    }
    final updated = await _missionSystem.transitionMission(
      missionId: mission.missionId,
      status: status,
      notes: notes,
      progressPct: progressPct,
    );
    if (!mounted) {
      return;
    }
    setState(() => _missionRecord = updated);
  }

  Future<void> _resumeMission() {
    return _transitionMission('active', notes: 'Mission resumed by operator.');
  }

  Future<void> _completeMission() {
    return _transitionMission(
      'completed',
      notes: 'Mission marked complete by operator.',
      progressPct: 100,
    );
  }

  Future<void> _openDjiConnectionSetup() async {
    await showDialog<void>(
      context: context,
      builder: (context) => DjiConnectionDialog(
        droneClient: widget.droneClient,
        onSaved: () => _bootstrapMissionSystem(),
      ),
    );
  }

  Future<void> _confirmMissionPackage() async {
    setState(() => _confirming = true);
    final preview = _liveFeed.preview;
    if (preview == null) {
      setState(() => _confirming = false);
      return;
    }
    final result = await widget.droneClient.confirmMission(preview);
    if (!mounted) {
      return;
    }
    setState(() {
      _confirmResult = result;
      _confirming = false;
    });
    await _refreshLiveFeed();
    final active = await _missionSystem.fetchActiveMission();
    if (!mounted) {
      return;
    }
    setState(() => _missionRecord = active ?? _missionRecord);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _mapConfigFuture,
        _geofenceLayerFuture,
        _mapMissionLayerFuture,
      ]),
      builder: (context, mapSnapshot) {
        final mapConfig =
            mapSnapshot.data?[0] as MapProviderConfig? ??
            MapProviderConfig.unavailable();
        final geofenceLayer =
            mapSnapshot.data?[1] as GeofenceLayer? ??
            GeofenceLayer.unavailable();
        final mapMissionLayer =
            mapSnapshot.data?[2] as MapMissionLayer? ??
            MapMissionLayer.unavailable();

        return _buildContent(
          mapConfig: mapConfig,
          geofenceLayer: geofenceLayer,
          mapMissionLayer: mapMissionLayer,
        );
      },
    );
  }

  Widget _buildContent({
    required MapProviderConfig mapConfig,
    required GeofenceLayer geofenceLayer,
    required MapMissionLayer mapMissionLayer,
  }) {
    final status = _liveFeed.status;
    final fleet = _liveFeed.fleet;
    final telemetry = _liveFeed.telemetry;
    final preview = _liveFeed.preview;
    final desktop = MediaQuery.sizeOf(context).width >= 1120;
    final initialLoad =
        _liveFeed.isRefreshing && status == null && _missionRecord == null;

    if (initialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget missionDashboard;
    if (!desktop) {
      missionDashboard = CompactMissionCommandDashboard(
        scenario: widget.scenario,
        status: status,
        fleet: fleet,
        telemetry: telemetry,
        preview: preview,
        confirmResult: _confirmResult,
        confirming: _confirming,
        readinessScore: _liveFeed.readinessScore,
        mapConfig: mapConfig,
        geofenceLayer: geofenceLayer,
        mapMissionLayer: mapMissionLayer,
        operationsClient: widget.operationsClient,
        onStartMission: _confirmMissionPackage,
        onPause: _pauseRun,
        onAbort: _resetRun,
        onConnectDji: _openDjiConnectionSetup,
        onRefreshLive: _refreshLiveFeed,
        isRefreshing: _liveFeed.isRefreshing,
      );
    } else {
      missionDashboard = MissionCommandDashboard(
        scenario: widget.scenario,
        status: status,
        fleet: fleet,
        telemetry: telemetry,
        preview: preview,
        confirmResult: _confirmResult,
        confirming: _confirming,
        readinessScore: _liveFeed.readinessScore,
        mapConfig: mapConfig,
        geofenceLayer: geofenceLayer,
        mapMissionLayer: mapMissionLayer,
        operationsClient: widget.operationsClient,
        onStartMission: _confirmMissionPackage,
        onPause: _pauseRun,
        onAbort: _resetRun,
        onConnectDji: _openDjiConnectionSetup,
        onRefreshLive: _refreshLiveFeed,
        isRefreshing: _liveFeed.isRefreshing,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OfficialDashboardScreen(
            scenario: widget.scenario,
            operationsClient: widget.operationsClient,
            onConnectDji: _openDjiConnectionSetup,
            liveDroneTelemetry: _liveFeed.liveDroneTelemetry,
            liveTelemetryActive: _liveFeed.hasLiveFleet,
            activeMissionRecord: _missionRecord,
          ),
          const SizedBox(height: 12),
          MissionSystemPanel(
            mission: _missionRecord,
            onPause: _pauseRun,
            onResume: _resumeMission,
            onAbort: _resetRun,
            onComplete: _completeMission,
          ),
          const SizedBox(height: 12),
          missionDashboard,
        ],
      ),
    );
  }
}

class MissionCommandDashboard extends StatelessWidget {
  const MissionCommandDashboard({
    required this.scenario,
    required this.status,
    required this.fleet,
    required this.telemetry,
    required this.preview,
    required this.confirmResult,
    required this.confirming,
    required this.readinessScore,
    required this.mapConfig,
    required this.geofenceLayer,
    required this.mapMissionLayer,
    required this.operationsClient,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
    required this.onConnectDji,
    required this.onRefreshLive,
    required this.isRefreshing,
    super.key,
  });

  final Scenario scenario;
  final DjiStatus? status;
  final List<DroneSummary> fleet;
  final TelemetrySnapshot telemetry;
  final MissionPreview? preview;
  final MissionConfirmResult? confirmResult;
  final bool confirming;
  final double readinessScore;
  final MapProviderConfig mapConfig;
  final GeofenceLayer geofenceLayer;
  final MapMissionLayer mapMissionLayer;
  final OperationsApiClient operationsClient;
  final VoidCallback onStartMission;
  final VoidCallback onPause;
  final VoidCallback onAbort;
  final VoidCallback onConnectDji;
  final Future<void> Function() onRefreshLive;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MissionHeroStatus(
          scenario: scenario,
          status: status,
          readinessScore: readinessScore,
          onConnectDji: onConnectDji,
          onRefreshLive: onRefreshLive,
          isRefreshing: isRefreshing,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  MissionCommandMap(
                    missionAvailable: preview?.available ?? false,
                    mapConfig: mapConfig,
                    geofenceLayer: geofenceLayer,
                    mapMissionLayer: mapMissionLayer,
                    operationsClient: operationsClient,
                    status: status,
                    fleet: fleet,
                    onStartMission: onStartMission,
                    onPause: onPause,
                    onAbort: onAbort,
                  ),
                  const SizedBox(height: 8),
                  FleetHealthStrip(fleet: fleet),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 330,
              child: CommandRightRail(
                status: status,
                fleet: fleet,
                telemetry: telemetry,
                preview: preview,
                confirmResult: confirmResult,
                confirming: confirming,
                onStartMission: onStartMission,
                onPause: onPause,
                onAbort: onAbort,
                onRefreshLive: onRefreshLive,
                isRefreshing: isRefreshing,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CompactMissionCommandDashboard extends StatelessWidget {
  const CompactMissionCommandDashboard({
    required this.scenario,
    required this.status,
    required this.fleet,
    required this.telemetry,
    required this.preview,
    required this.confirmResult,
    required this.confirming,
    required this.readinessScore,
    required this.mapConfig,
    required this.geofenceLayer,
    required this.mapMissionLayer,
    required this.operationsClient,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
    required this.onConnectDji,
    required this.onRefreshLive,
    required this.isRefreshing,
    super.key,
  });

  final Scenario scenario;
  final DjiStatus? status;
  final List<DroneSummary> fleet;
  final TelemetrySnapshot telemetry;
  final MissionPreview? preview;
  final MissionConfirmResult? confirmResult;
  final bool confirming;
  final double readinessScore;
  final MapProviderConfig mapConfig;
  final GeofenceLayer geofenceLayer;
  final MapMissionLayer mapMissionLayer;
  final OperationsApiClient operationsClient;
  final VoidCallback onStartMission;
  final VoidCallback onPause;
  final VoidCallback onAbort;
  final VoidCallback onConnectDji;
  final Future<void> Function() onRefreshLive;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MissionHeroStatus(
          scenario: scenario,
          status: status,
          readinessScore: readinessScore,
          onConnectDji: onConnectDji,
          onRefreshLive: onRefreshLive,
          isRefreshing: isRefreshing,
        ),
        const SizedBox(height: 12),
        MissionCommandMap(
          missionAvailable: preview?.available ?? false,
          mapConfig: mapConfig,
          geofenceLayer: geofenceLayer,
          mapMissionLayer: mapMissionLayer,
          operationsClient: operationsClient,
          status: status,
          fleet: fleet,
          onStartMission: onStartMission,
          onPause: onPause,
          onAbort: onAbort,
        ),
        const SizedBox(height: 12),
        CommandRightRail(
          status: status,
          fleet: fleet,
          telemetry: telemetry,
          preview: preview,
          confirmResult: confirmResult,
          confirming: confirming,
          onStartMission: onStartMission,
          onPause: onPause,
          onAbort: onAbort,
          onRefreshLive: onRefreshLive,
          isRefreshing: isRefreshing,
        ),
        const SizedBox(height: 12),
        FleetHealthStrip(fleet: fleet),
      ],
    );
  }
}

String _djiStatusLabel(DjiStatus? status) {
  if (status?.liveData ?? false) return 'LIVE TELEMETRY';
  return switch (status?.connection) {
    'waiting-for-bridge' => 'WAITING FOR BRIDGE',
    'bridge-online' => 'BRIDGE ONLINE',
    'bridge-stale' => 'BRIDGE STALE',
    'configured' => 'CONNECTOR READY',
    _ => 'NOT CONFIGURED',
  };
}

Color _djiStatusColor(DjiStatus? status) {
  if (status?.liveData ?? false) return const Color(0xff42d66b);
  return switch (status?.connection) {
    'waiting-for-bridge' => const Color(0xffffc857),
    'bridge-online' => const Color(0xff27c38c),
    'bridge-stale' => const Color(0xffff7a59),
    'configured' => const Color(0xff7cc7ff),
    _ => const Color(0xffffc857),
  };
}

class MissionHeroStatus extends StatelessWidget {
  const MissionHeroStatus({
    required this.scenario,
    required this.status,
    required this.readinessScore,
    required this.onConnectDji,
    required this.onRefreshLive,
    required this.isRefreshing,
    super.key,
  });

  final Scenario scenario;
  final DjiStatus? status;
  final double readinessScore;
  final VoidCallback onConnectDji;
  final Future<void> Function() onRefreshLive;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final reserveReadiness = constraints.maxWidth < 980;
        final statusLabel = _djiStatusLabel(status);
        final statusColor = _djiStatusColor(status);
        final heroHeight = compact
            ? 214.0
            : (reserveReadiness ? 248.0 : 228.0);
        return Container(
          height: heroHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xff0c1715),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/mission-hero-fire-drone.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.78),
                        Colors.black.withValues(alpha: 0.34),
                        Colors.black.withValues(alpha: compact ? 0.30 : 0.07),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: compact ? 22 : 26,
                right: reserveReadiness ? 14 : 190,
                bottom: compact ? 24 : 28,
                child: SizedBox(
                  width: compact ? null : 520,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        scenario.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 23 : 29,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        scenario.region,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        status?.lastSync == null ||
                                status!.lastSync == 'not configured'
                            ? 'Awaiting DJI bridge sync'
                            : 'Last sync · ${status!.lastSync}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xffe7efea),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      MissionLinkStatus(
                        status: status,
                        compact: compact,
                        onConnectDji: onConnectDji,
                        onRefreshLive: onRefreshLive,
                        isRefreshing: isRefreshing,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: compact ? 14 : 16,
                top: compact ? 14 : 18,
                child: compact
                    ? CompactReadinessBadge(
                        commandEnabled: status?.commandEnabled ?? false,
                        liveData: status?.liveData ?? false,
                        readinessScore: readinessScore,
                      )
                    : MissionReadinessCard(
                        commandEnabled: status?.commandEnabled ?? false,
                        liveData: status?.liveData ?? false,
                        readinessScore: readinessScore,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MissionLinkStatus extends StatelessWidget {
  const MissionLinkStatus({
    required this.status,
    required this.compact,
    required this.onConnectDji,
    required this.onRefreshLive,
    required this.isRefreshing,
    super.key,
  });

  final DjiStatus? status;
  final bool compact;
  final VoidCallback onConnectDji;
  final Future<void> Function() onRefreshLive;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors, color: Color(0xff47d16a), size: 17),
            SizedBox(width: 7),
            Text(
              'DJI Link',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          _linkStatusText(status, compact: compact),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xffffc857),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status?.commandEnabled ?? false
                ? 'Commands enabled'
                : 'Command gate locked',
            style: const TextStyle(
              color: Color(0xff10231d),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: isRefreshing ? null : () => onRefreshLive(),
          icon: Icon(isRefreshing ? Icons.hourglass_top : Icons.refresh, size: 16),
          label: Text(isRefreshing ? 'Syncing' : 'Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
        OutlinedButton.icon(
          onPressed: onConnectDji,
          icon: const Icon(Icons.settings_input_antenna, size: 16),
          label: const Text('Connect DJI'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

String _linkStatusText(DjiStatus? status, {required bool compact}) {
  if (status == null) return 'Reading DJI status';
  if (status.connection == 'not-configured') {
    return 'DJI connector not configured';
  }
  if (status.connection == 'waiting-for-bridge') {
    return 'Waiting for DJI bridge';
  }
  if (status.connection == 'bridge-stale') {
    return compact ? 'Bridge stale' : 'DJI bridge stale, check ingest worker';
  }
  if (status.connection == 'bridge-online' && !status.liveData) {
    return compact ? 'Bridge online' : 'Bridge online, no aircraft telemetry';
  }
  if (status.liveData) {
    return compact
        ? '${status.aircraftCount} aircraft'
        : '${status.source} · ${status.aircraftCount} aircraft';
  }
  return '${status.connector} connector';
}

class CompactReadinessBadge extends StatelessWidget {
  const CompactReadinessBadge({
    required this.commandEnabled,
    required this.liveData,
    required this.readinessScore,
    super.key,
  });

  final bool commandEnabled;
  final bool liveData;
  final double readinessScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff101820).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: liveData ? readinessScore : 0,
              strokeWidth: 6,
              backgroundColor: const Color(0xff2d3740),
              color: commandEnabled
                  ? const Color(0xff47d16a)
                  : const Color(0xff27c38c),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              liveData
                  ? '${(readinessScore * 100).round()}%\nREADY'
                  : '0%\nOFF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MissionReadinessCard extends StatelessWidget {
  const MissionReadinessCard({
    required this.commandEnabled,
    required this.liveData,
    required this.readinessScore,
    super.key,
  });

  final bool commandEnabled;
  final bool liveData;
  final double readinessScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff101820).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: liveData ? readinessScore : 0,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xff2d3740),
                  color: commandEnabled
                      ? const Color(0xff47d16a)
                      : const Color(0xff27c38c),
                ),
                Center(
                  child: Text(
                    liveData ? '${(readinessScore * 100).round()}%' : '0%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MISSION READINESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ReadinessLine(label: 'Drones Online', ok: liveData),
                ReadinessLine(label: 'Telemetry Link', ok: liveData),
                ReadinessLine(label: 'Weather OK', ok: liveData),
                ReadinessLine(label: 'Payload Systems', ok: commandEnabled),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReadinessLine extends StatelessWidget {
  const ReadinessLine({required this.label, required this.ok, super.key});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xffe6eeea), fontSize: 11),
            ),
          ),
          Icon(
            ok ? Icons.check_circle : Icons.warning_amber_rounded,
            color: ok ? const Color(0xff47d16a) : const Color(0xffffa000),
            size: 14,
          ),
        ],
      ),
    );
  }
}

class CommandRightRail extends StatelessWidget {
  const CommandRightRail({
    required this.status,
    required this.fleet,
    required this.telemetry,
    required this.preview,
    required this.confirmResult,
    required this.confirming,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
    required this.onRefreshLive,
    required this.isRefreshing,
    super.key,
  });

  final DjiStatus? status;
  final List<DroneSummary> fleet;
  final TelemetrySnapshot telemetry;
  final MissionPreview? preview;
  final MissionConfirmResult? confirmResult;
  final bool confirming;
  final VoidCallback onStartMission;
  final VoidCallback onPause;
  final VoidCallback onAbort;
  final Future<void> Function() onRefreshLive;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConnectedDronesPanel(fleet: fleet, status: status),
        const SizedBox(height: 8),
        TelemetryLinkPanel(telemetry: telemetry, fleet: fleet, status: status),
        const SizedBox(height: 8),
        MissionActionPanel(
          status: status,
          preview: preview,
          confirmResult: confirmResult,
          confirming: confirming,
          onStartMission: onStartMission,
          onPause: onPause,
          onAbort: onAbort,
        ),
        const SizedBox(height: 8),
        WeatherConditionsPanel(telemetry: telemetry),
      ],
    );
  }
}

class ConnectedDronesPanel extends StatelessWidget {
  const ConnectedDronesPanel({
    required this.fleet,
    required this.status,
    super.key,
  });

  final List<DroneSummary> fleet;
  final DjiStatus? status;

  @override
  Widget build(BuildContext context) {
    final onlineCount = fleet
        .where((drone) => drone.connection != 'charging')
        .length;
    return InfoCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'CONNECTED DRONES',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xff263330),
                  ),
                ),
              ),
              Text(
                '$onlineCount / ${fleet.length} Online',
                style: const TextStyle(
                  color: Color(0xff16845f),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          if (fleet.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                switch (status?.connection) {
                  'waiting-for-bridge' =>
                    'Ingest configured. Start Cloud API MQTT or Mobile SDK bridge to receive aircraft.',
                  'bridge-stale' =>
                    'Bridge feed stale. Restart the Cloud API worker or Mobile SDK bridge.',
                  'configured' =>
                    'Connector ready. Publish aircraft state through the bridge ingest endpoint.',
                  _ => 'No real DJI aircraft connected',
                },
                style: const TextStyle(
                  color: Color(0xff62716c),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            )
          else
            for (var i = 0; i < fleet.length; i++)
              DroneListRow(index: i + 1, drone: fleet[i]),
        ],
      ),
    );
  }
}

class DroneListRow extends StatelessWidget {
  const DroneListRow({required this.index, required this.drone, super.key});

  final int index;
  final DroneSummary drone;

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (drone.connection) {
      'online' => const Color(0xff4e9e40),
      'standby' => const Color(0xffff9f1c),
      _ => const Color(0xff9fa7a3),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drone.id.length > 10
                      ? drone.id.substring(0, 10)
                      : drone.id,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  drone.name.replaceAll('DJI ', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff4f5f5a),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.battery_full,
            size: 15,
            color: drone.batteryPct > 0
                ? const Color(0xff16845f)
                : const Color(0xff9fa7a3),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            child: Text(
              drone.batteryPct > 0 ? '${drone.batteryPct}%' : '--',
              style: TextStyle(
                color: drone.batteryPct > 0
                    ? const Color(0xff16845f)
                    : const Color(0xff9fa7a3),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xff98a39f)),
        ],
      ),
    );
  }
}

class TelemetryLinkPanel extends StatelessWidget {
  const TelemetryLinkPanel({
    required this.telemetry,
    required this.fleet,
    required this.status,
    super.key,
  });

  final TelemetrySnapshot telemetry;
  final List<DroneSummary> fleet;
  final DjiStatus? status;

  @override
  Widget build(BuildContext context) {
    final configured = telemetry.linkHealth != 'not-configured';
    final signal = averageFleetSignal(fleet);
    final latencyMs = configured ? (140 - signal).clamp(35, 120) : null;
    final dataRateMbps = configured
        ? (4 + telemetry.routeProgressPct / 25).toStringAsFixed(1)
        : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff111a1d),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TELEMETRY LINK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                telemetry.linkHealth == 'not-configured'
                    ? 'Not configured'
                    : telemetry.missionState == 'device-online'
                    ? signalQualityLabel(signal)
                    : telemetry.linkHealth == 'stable'
                    ? signalQualityLabel(signal)
                    : telemetry.linkHealth,
                style: const TextStyle(
                  color: Color(0xff47d16a),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xff28353a), height: 18),
          Row(
            children: [
              Expanded(
                child: TelemetryMetric(
                  label: 'Link Quality',
                  value: configured ? '$signal%' : '--',
                ),
              ),
              Expanded(
                child: TelemetryMetric(
                  label: 'Latency',
                  value: configured ? '$latencyMs ms' : '--',
                ),
              ),
              Expanded(
                child: TelemetryMetric(
                  label: 'Data Rate',
                  value: configured ? '$dataRateMbps Mbps' : '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (configured)
            SizedBox(
              height: 36,
              child: CustomPaint(painter: TelemetrySparklinePainter()),
            )
          else
            Text(
              switch (status?.connection) {
                'waiting-for-bridge' =>
                  'Bridge token saved. Start Cloud API MQTT or Mobile SDK ingest to populate telemetry.',
                'bridge-stale' =>
                  'Last bridge packet expired. Restart ingest to restore live telemetry.',
                _ =>
                  'Connect DJI Cloud API or Mobile SDK bridge to receive live telemetry.',
              },
              style: const TextStyle(color: Color(0xffaebbb5), height: 1.35),
            ),
        ],
      ),
    );
  }
}

class TelemetryMetric extends StatelessWidget {
  const TelemetryMetric({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xffaebbb5), fontSize: 11),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xff47d16a),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class TelemetrySparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      .38,
      .58,
      .50,
      .66,
      .54,
      .70,
      .61,
      .64,
      .50,
      .44,
      .57,
      .47,
      .62,
      .68,
      .54,
      .60,
      .48,
      .63,
      .56,
      .66,
      .51,
    ];
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xff47d16a)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MissionActionPanel extends StatelessWidget {
  const MissionActionPanel({
    required this.status,
    required this.preview,
    required this.confirmResult,
    required this.confirming,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
    super.key,
  });

  final DjiStatus? status;
  final MissionPreview? preview;
  final MissionConfirmResult? confirmResult;
  final bool confirming;
  final VoidCallback onStartMission;
  final VoidCallback onPause;
  final VoidCallback onAbort;

  @override
  Widget build(BuildContext context) {
    final previewAvailable = preview?.available ?? false;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff111a1d),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff16845f),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: !previewAvailable || confirming
                  ? null
                  : onStartMission,
              icon: Icon(confirming ? Icons.hourglass_top : Icons.play_arrow),
              label: Text(confirming ? 'CONFIRMING' : 'START MISSION'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xff314046)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: onPause,
                  icon: const Icon(Icons.pause),
                  label: const Text('PAUSE'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xffff6157),
                    side: const BorderSide(color: Color(0xffff6157)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: onAbort,
                  icon: const Icon(Icons.stop),
                  label: const Text('ABORT'),
                ),
              ),
            ],
          ),
          if (!previewAvailable) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                switch (status?.connection) {
                  'waiting-for-bridge' =>
                    'Waiting for bridge aircraft before mission preview unlocks.',
                  'bridge-stale' => 'Bridge feed stale · refresh ingest worker',
                  'bridge-online' when !(status?.liveData ?? false) =>
                    'Bridge online · waiting for aircraft telemetry',
                  _ => 'Connect DJI bridge or Cloud API to unlock mission preview',
                },
                style: const TextStyle(
                  color: Color(0xffffc857),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (confirmResult != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                confirmResult!.accepted
                    ? 'Mission accepted'
                    : 'Command gate locked',
                style: const TextStyle(
                  color: Color(0xffffc857),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WeatherConditionsPanel extends StatelessWidget {
  const WeatherConditionsPanel({required this.telemetry, super.key});

  final TelemetrySnapshot telemetry;

  @override
  Widget build(BuildContext context) {
    final configured = telemetry.linkHealth != 'not-configured';
    return InfoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WEATHER & CONDITIONS',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              WeatherChip(
                icon: Icons.thermostat,
                value: configured
                    ? '${telemetry.temperatureF.round()}°F'
                    : '--',
                label: 'Temp',
              ),
              WeatherChip(
                icon: Icons.air,
                value: configured ? '${telemetry.windMph.round()} mph' : '--',
                label: 'Wind',
              ),
              WeatherChip(
                icon: Icons.water_drop_outlined,
                value: configured ? 'Live feed' : '--',
                label: 'Humidity',
              ),
              WeatherChip(
                icon: Icons.visibility_outlined,
                value: configured ? 'Live feed' : '--',
                label: 'Visibility',
              ),
              WeatherChip(
                icon: Icons.local_fire_department_outlined,
                value: configured ? telemetry.firePerimeterRisk : '--',
                label: 'Fire Behavior',
              ),
              WeatherChip(
                icon: Icons.gps_fixed,
                value: configured ? 'Stable' : 'No feed',
                label: 'Atmosphere',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeatherChip extends StatelessWidget {
  const WeatherChip({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff263330), size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff62716c),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FleetHealthStrip extends StatelessWidget {
  const FleetHealthStrip({required this.fleet, super.key});

  final List<DroneSummary> fleet;

  @override
  Widget build(BuildContext context) {
    final display = fleet.take(4).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 700;
        return InfoCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FLEET HEALTH',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 10),
              if (display.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Text(
                    'No real DJI aircraft connected',
                    style: TextStyle(
                      color: Color(0xff62716c),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (stacked)
                Column(
                  children: [
                    for (var i = 0; i < display.length; i++) ...[
                      FleetHealthCard(index: i + 1, drone: display[i]),
                      if (i != display.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    for (var i = 0; i < display.length; i++) ...[
                      Expanded(
                        child: FleetHealthCard(index: i + 1, drone: display[i]),
                      ),
                      if (i != display.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class FleetHealthCard extends StatelessWidget {
  const FleetHealthCard({required this.index, required this.drone, super.key});

  final int index;
  final DroneSummary drone;

  @override
  Widget build(BuildContext context) {
    final status = switch (drone.connection) {
      'online' => 'In Mission',
      'standby' => 'Returning',
      _ => 'Standby',
    };
    final accent = drone.connection == 'standby'
        ? const Color(0xffff9f1c)
        : const Color(0xff16845f);
    return Container(
      width: double.infinity,
      height: 198,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: drone.connection == 'standby'
              ? const Color(0xffffd08a)
              : const Color(0xffdfe8e4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  drone.id.length > 10
                      ? drone.id.substring(0, 10)
                      : drone.id,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const Icon(Icons.more_vert, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.flight, size: 34, color: Color(0xff1a2b2a)),
              const Spacer(),
              Flexible(
                child: Text(
                  '${drone.batteryPct}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  drone.connection == 'charging' ? '--' : '28:14',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FleetHealthLine(
            label: 'GPS',
            value: gpsQualityLabel(drone),
          ),
          FleetHealthLine(
            label: 'Link',
            value: signalQualityLabel(drone.signalPct),
          ),
          FleetHealthLine(
            label: 'Payload',
            value: drone.connection == 'standby' ? 'Thermal Active' : 'Normal',
          ),
          const Spacer(),
          Center(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: accent, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class FleetHealthLine extends StatelessWidget {
  const FleetHealthLine({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            label == 'GPS'
                ? Icons.location_on_outlined
                : label == 'Link'
                ? Icons.sensors
                : Icons.cases_outlined,
            size: 14,
            color: const Color(0xff62716c),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
