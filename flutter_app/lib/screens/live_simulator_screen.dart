import 'package:flutter/material.dart';

import '../data/mock_scenarios.dart';
import '../models/scenario.dart';
import '../models/simulation_layout.dart';
import '../services/drone_api_client.dart';
import '../widgets/common/info_card.dart';
import '../widgets/simulator/mission_command_map.dart';

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
  late SimulationLayout _layout;
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
  }

  @override
  void didUpdateWidget(covariant LiveSimulatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scenario != widget.scenario) {
      _loadLayoutForScenario(widget.scenario);
    }
  }

  @override
  void dispose() {
    super.dispose();
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

  void _loadLayoutForScenario(Scenario scenario) {
    _layout = cloneLayout(defaultLayoutForScenario(scenario));
  }

  void _pauseRun() {
    setState(() {});
  }

  void _resetRun() {
    setState(() {
      _confirmResult = null;
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
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _statusFuture,
        _fleetFuture,
        _telemetryFuture,
        _previewFuture,
      ]),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final status = data?[0] as DjiStatus?;
        final fleet = data?[1] as List<DroneSummary>? ?? const [];
        final telemetry =
            data?[2] as TelemetrySnapshot? ??
            const TelemetrySnapshot(
              activeDroneId: 'dji-thermal-01',
              missionState: 'preview-ready',
              routeProgressPct: 0,
              windMph: 14,
              temperatureF: 73,
              firePerimeterRisk: 'elevated',
              linkHealth: 'stable',
            );
        final preview = data?[3] as MissionPreview?;
        final desktop = MediaQuery.sizeOf(context).width >= 1120;

        if (!desktop) {
          return CompactMissionCommandDashboard(
            status: status,
            fleet: fleet,
            telemetry: telemetry,
            preview: preview,
            confirmResult: _confirmResult,
            confirming: _confirming,
            onStartMission: _confirmMissionPackage,
            onPause: _pauseRun,
            onAbort: _resetRun,
          );
        }

        return MissionCommandDashboard(
          status: status,
          fleet: fleet,
          telemetry: telemetry,
          preview: preview,
          confirmResult: _confirmResult,
          confirming: _confirming,
          onStartMission: _confirmMissionPackage,
          onPause: _pauseRun,
          onAbort: _resetRun,
        );
      },
    );
  }
}

class MissionCommandDashboard extends StatelessWidget {
  const MissionCommandDashboard({
    required this.status,
    required this.fleet,
    required this.telemetry,
    required this.preview,
    required this.confirmResult,
    required this.confirming,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MissionHeroStatus(status: status),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  MissionCommandMap(
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
    required this.status,
    required this.fleet,
    required this.telemetry,
    required this.preview,
    required this.confirmResult,
    required this.confirming,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MissionHeroStatus(status: status),
        const SizedBox(height: 12),
        MissionCommandMap(
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
        ),
        const SizedBox(height: 12),
        FleetHealthStrip(fleet: fleet),
      ],
    );
  }
}

class MissionHeroStatus extends StatelessWidget {
  const MissionHeroStatus({required this.status, super.key});

  final DjiStatus? status;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return Container(
          height: compact ? 214 : 228,
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
                right: compact ? 18 : null,
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
                            decoration: const BoxDecoration(
                              color: Color(0xff42d66b),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Color(0xff42d66b),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Canyon Ridge Fire',
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
                      const Text(
                        'Los Padres National Forest, CA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Mon, Jun 10, 2026 09:42 AM PDT',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xffe7efea),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      MissionLinkStatus(status: status, compact: compact),
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
                      )
                    : MissionReadinessCard(
                        commandEnabled: status?.commandEnabled ?? false,
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
    super.key,
  });

  final DjiStatus? status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sensors, color: Color(0xff47d16a), size: 17),
            const SizedBox(width: 7),
            const Text(
              'DJI Link',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 3),
              Text(
                '· ${status?.connector ?? 'mock'} connector',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
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
      ],
    );
  }
}

class CompactReadinessBadge extends StatelessWidget {
  const CompactReadinessBadge({required this.commandEnabled, super.key});

  final bool commandEnabled;

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
              value: 0.82,
              strokeWidth: 6,
              backgroundColor: const Color(0xff2d3740),
              color: commandEnabled
                  ? const Color(0xff47d16a)
                  : const Color(0xff27c38c),
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              '82%\nREADY',
              style: TextStyle(
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
  const MissionReadinessCard({required this.commandEnabled, super.key});

  final bool commandEnabled;

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
                  value: 0.82,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xff2d3740),
                  color: commandEnabled
                      ? const Color(0xff47d16a)
                      : const Color(0xff27c38c),
                ),
                const Center(
                  child: Text(
                    '82%',
                    style: TextStyle(
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MISSION READINESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                ReadinessLine(label: 'Drones Online', ok: true),
                ReadinessLine(label: 'Telemetry Link', ok: true),
                ReadinessLine(label: 'Weather OK', ok: true),
                ReadinessLine(label: 'Payload Systems', ok: false),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConnectedDronesPanel(fleet: fleet),
        const SizedBox(height: 8),
        TelemetryLinkPanel(telemetry: telemetry),
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
        const WeatherConditionsPanel(),
      ],
    );
  }
}

class ConnectedDronesPanel extends StatelessWidget {
  const ConnectedDronesPanel({required this.fleet, super.key});

  final List<DroneSummary> fleet;

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
                  'DRN-0$index',
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
  const TelemetryLinkPanel({required this.telemetry, super.key});

  final TelemetrySnapshot telemetry;

  @override
  Widget build(BuildContext context) {
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
                telemetry.linkHealth == 'stable'
                    ? 'Excellent'
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
                child: TelemetryMetric(label: 'Link Quality', value: '98%'),
              ),
              Expanded(
                child: TelemetryMetric(label: 'Latency', value: '120 ms'),
              ),
              Expanded(
                child: TelemetryMetric(label: 'Data Rate', value: '8.6 Mbps'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: CustomPaint(painter: TelemetrySparklinePainter()),
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
              onPressed: preview == null || confirming ? null : onStartMission,
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
  const WeatherConditionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'WEATHER & CONDITIONS',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              WeatherChip(icon: Icons.thermostat, value: '24°C', label: 'Temp'),
              WeatherChip(icon: Icons.air, value: 'WNW 6 m/s', label: 'Wind'),
              WeatherChip(
                icon: Icons.water_drop_outlined,
                value: '55%',
                label: 'Humidity',
              ),
              WeatherChip(
                icon: Icons.visibility_outlined,
                value: '16 km',
                label: 'Visibility',
              ),
              WeatherChip(
                icon: Icons.local_fire_department_outlined,
                value: 'High',
                label: 'Fire Behavior',
              ),
              WeatherChip(
                icon: Icons.gps_fixed,
                value: 'Stable',
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
              if (stacked)
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
                  'DRN-0$index',
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
          const FleetHealthLine(label: 'GPS', value: 'Strong'),
          const FleetHealthLine(label: 'Link', value: 'Excellent'),
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
