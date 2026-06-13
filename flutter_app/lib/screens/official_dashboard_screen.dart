import 'package:flutter/material.dart';

import '../models/audit_log_entry.dart';
import '../models/command.dart';
import '../models/drone_telemetry.dart';
import '../models/fire_detection_event.dart';
import '../models/mission.dart';
import '../models/operations_enums.dart';
import '../models/scenario.dart';
import '../models/safety_gate_status.dart';
import '../safety/safety_gate_service.dart';
import '../services/audit_log_service.dart';
import '../services/drone_telemetry_service.dart';
import '../services/fire_detection_service.dart';
import '../services/mission_service.dart';
import '../services/operations_api_client.dart';
import '../widgets/common/info_card.dart';
import '../widgets/common/metric_card.dart';
import '../widgets/common/responsive_grid.dart';

class OfficialDashboardScreen extends StatefulWidget {
  const OfficialDashboardScreen({
    required this.scenario,
    required this.operationsClient,
    required this.onConnectDji,
    super.key,
  });

  final Scenario scenario;
  final OperationsApiClient operationsClient;
  final VoidCallback onConnectDji;

  @override
  State<OfficialDashboardScreen> createState() =>
      _OfficialDashboardScreenState();
}

class _OfficialDashboardScreenState extends State<OfficialDashboardScreen> {
  final DroneTelemetryService _telemetryService =
      const MockDroneTelemetryService();
  final FireDetectionService _fireDetectionService =
      const MockFireDetectionService();
  final MissionService _missionService = const MockMissionService();
  final InMemoryAuditLogService _auditLogService = InMemoryAuditLogService();
  final SafetyGateService _safetyGateService = SafetyGateService();
  final TextEditingController _notesController = TextEditingController();

  var _loading = true;
  List<DroneTelemetry> _telemetry = const [];
  List<FireDetectionEvent> _events = const [];
  List<AuditLogEntry> _auditEntries = const [];
  BackendIntegrationStatus _integrationStatus =
      BackendIntegrationStatus.unavailable();
  SafetyChecklist _safetyChecklist = SafetyChecklist.unavailable();
  Mission? _mission;
  int _selectedAlertIndex = 0;
  String? _reviewMessage;
  String? _commandMessage;
  bool _commandConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadOperationsData();
  }

  @override
  void didUpdateWidget(covariant OfficialDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scenario.scenarioId != widget.scenario.scenarioId) {
      _selectedAlertIndex = 0;
      _reviewMessage = null;
      _commandMessage = null;
      _commandConfirmed = false;
      _loadOperationsData();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOperationsData() async {
    final telemetry = await _telemetryService.fetchTelemetry();
    final backendEvents = await widget.operationsClient.fetchAlerts();
    final events = backendEvents.isEmpty
        ? await _fireDetectionService.fetchDetections()
        : backendEvents;
    final mission = await _missionService.fetchActiveMission();
    final backendAuditEntries = await widget.operationsClient
        .fetchAuditEntries();
    final auditEntries = backendAuditEntries.isEmpty
        ? await _auditLogService.entries()
        : backendAuditEntries;
    final integrationStatus = await widget.operationsClient
        .fetchIntegrationStatus();
    final safetyChecklist = await widget.operationsClient
        .fetchSafetyChecklist();

    if (!mounted) return;

    _notesController.text = events.isEmpty ? '' : events.first.notes;
    setState(() {
      _telemetry = telemetry;
      _events = events;
      _mission = mission;
      _auditEntries = auditEntries;
      _integrationStatus = integrationStatus;
      _safetyChecklist = safetyChecklist;
      _loading = false;
    });
  }

  FireDetectionEvent? get _selectedAlert {
    if (_events.isEmpty) return null;
    final index = _selectedAlertIndex >= _events.length
        ? _events.length - 1
        : _selectedAlertIndex;
    return _events[index];
  }

  Future<void> _selectAlert(int index) async {
    final event = _events[index];
    _notesController.text = event.notes;
    setState(() {
      _selectedAlertIndex = index;
      _reviewMessage = null;
    });
  }

  Future<void> _reviewAlert({
    required AlertStatus status,
    required String action,
    required String visibleMessage,
  }) async {
    final event = _selectedAlert;
    if (event == null) return;

    late FireDetectionEvent updated;
    var auditEntries = const <AuditLogEntry>[];
    try {
      updated = await widget.operationsClient.reviewAlert(
        event: event,
        status: status,
        notes: _notesController.text.trim(),
      );
      auditEntries = await widget.operationsClient.fetchAuditEntries();
    } catch (_) {
      updated = await _fireDetectionService.updateStatus(
        event: event,
        status: status,
        reviewer: 'Simulation Operator',
        notes: _notesController.text.trim(),
      );
      await _auditLogService.record(
        actor: 'Simulation Operator',
        action: action,
        targetId: event.eventId,
        details:
            '${event.detectionType.label} at ${_coordLabel(event.lat, event.lon)} marked ${status.label}',
      );
      auditEntries = await _auditLogService.entries();
    }

    if (!mounted) return;

    _notesController.text = updated.notes;
    setState(() {
      _events = [
        for (final item in _events)
          if (item.eventId == updated.eventId) updated else item,
      ];
      _reviewMessage = visibleMessage;
      _auditEntries = auditEntries;
    });
  }

  Future<void> _submitCommand(DroneCommandType commandType) async {
    final targetDroneId = _telemetry.isEmpty
        ? 'simulated-fleet'
        : _telemetry.first.droneId;
    final request = CommandRequest(
      requestId: 'cmd-${DateTime.now().microsecondsSinceEpoch}',
      commandType: commandType,
      requestedBy: 'Simulation Operator',
      targetDroneId: targetDroneId,
      timestamp: DateTime.now().toUtc(),
      confirmationProvided:
          _commandConfirmed || commandType == DroneCommandType.emergencyStop,
      notes: 'Simulation dashboard command panel',
    );
    final localGateResult = await _safetyGateService.submitCommand(request);
    var result = localGateResult;
    var auditEntries = const <AuditLogEntry>[];
    var safetyChecklist = _safetyChecklist;
    if (localGateResult.accepted) {
      try {
        result = await widget.operationsClient.simulateCommand(request);
        auditEntries = await widget.operationsClient.fetchAuditEntries();
        safetyChecklist = await widget.operationsClient.fetchSafetyChecklist();
      } catch (_) {
        auditEntries = const [];
      }
    }
    final action = commandType == DroneCommandType.emergencyStop
        ? 'Emergency stop engaged'
        : result.accepted
        ? 'Simulated command ${commandType.label}'
        : 'Blocked command ${commandType.label}';

    if (auditEntries.isEmpty) {
      await _auditLogService.record(
        actor: 'Simulation Operator',
        action: action,
        targetId: targetDroneId,
        details: result.message,
      );
      auditEntries = await _auditLogService.entries();
    }

    if (!mounted) return;

    setState(() {
      _commandMessage = commandType == DroneCommandType.emergencyStop
          ? 'Emergency stop engaged'
          : result.accepted
          ? 'Simulated command accepted'
          : result.blockedReason;
      _auditEntries = auditEntries;
      _safetyChecklist = safetyChecklist;
      if (commandType == DroneCommandType.emergencyStop) {
        _commandConfirmed = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _mission == null) {
      return const InfoCard(
        child: Text(
          'Loading official operations dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }

    final mission = _mission!;
    final safetyStatus = _safetyGateService.status;
    final activeEvents = _events.where((event) => event.isOpen).length;
    final confirmed = _events
        .where((event) => event.status == AlertStatus.confirmed)
        .length;
    final unconfirmed = _events
        .where((event) => event.status == AlertStatus.unconfirmed)
        .length;
    final latestTelemetry = _telemetry.isEmpty ? null : _telemetry.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardHero(
          scenario: widget.scenario,
          mission: mission,
          safetyStatus: safetyStatus,
          onConnectDji: widget.onConnectDji,
        ),
        const SizedBox(height: 12),
        ResponsiveGrid(
          children: [
            MetricCard(
              icon: Icons.admin_panel_settings_outlined,
              label: 'System Mode',
              value: 'Simulation Mode',
              detail: 'Official/Public-Safety Prototype. Not production ready.',
              accent: const Color(0xff2364aa),
            ),
            MetricCard(
              icon: Icons.flight_outlined,
              label: 'Active Drones',
              value: '${_telemetry.length}',
              detail: 'Mock telemetry normalized behind service models',
              accent: const Color(0xff0e7656),
            ),
            MetricCard(
              icon: Icons.local_fire_department_outlined,
              label: 'Active Detections',
              value: '$activeEvents',
              detail: 'Fire and smoke detections require human review',
              accent: const Color(0xffc4492d),
            ),
            MetricCard(
              icon: Icons.fact_check_outlined,
              label: 'Confirmed / Unconfirmed',
              value: '$confirmed / $unconfirmed',
              detail: 'Operator review status for current alert queue',
              accent: const Color(0xff725ac1),
            ),
            MetricCard(
              icon: Icons.track_changes_outlined,
              label: 'Mission Status',
              value: mission.status.label,
              detail: mission.area,
              accent: const Color(0xff456990),
            ),
            MetricCard(
              icon: Icons.schedule_outlined,
              label: 'Latest Telemetry Time',
              value: latestTelemetry == null
                  ? 'No feed'
                  : _timeLabel(latestTelemetry.timestamp),
              detail: latestTelemetry == null
                  ? 'No drone telemetry loaded'
                  : '${latestTelemetry.droneId} reporting ${latestTelemetry.linkStatus.label}',
              accent: const Color(0xff27a2a0),
            ),
            MetricCard(
              icon: Icons.lock_outline,
              label: 'Safety Lock',
              value: safetyStatus.commandLocked ? 'Locked' : 'Unlocked',
              detail: safetyStatus.statusMessage,
              accent: const Color(0xffa63d40),
            ),
            const MetricCard(
              icon: Icons.dataset_outlined,
              label: 'Data Source',
              value: 'Mock simulation',
              detail: 'No real DJI aircraft command is sent from this panel',
              accent: Color(0xff6c757d),
            ),
            MetricCard(
              icon: Icons.storage_outlined,
              label: 'Backend Persistence',
              value: _integrationStatus.available
                  ? _integrationStatus.persistenceEngine
                  : 'Local fallback',
              detail:
                  'Alerts: ${_integrationStatus.alertPersistence}; audit: ${_integrationStatus.auditPersistence}',
              accent: const Color(0xff456990),
            ),
            MetricCard(
              icon: Icons.map_outlined,
              label: 'Map Provider',
              value: _integrationStatus.mapProvider,
              detail:
                  'PX4 ${_integrationStatus.px4Sitl}; YOLO/Thermal ${_integrationStatus.yoloThermal}',
              accent: const Color(0xff0e7656),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ResponsivePair(
          left: _MissionOverviewPanel(
            mission: mission,
            scenario: widget.scenario,
            safetyStatus: safetyStatus,
          ),
          right: _TelemetryPanel(telemetry: _telemetry),
        ),
        const SizedBox(height: 12),
        _ResponsivePair(
          left: _OperationsMapPanel(
            telemetry: _telemetry,
            events: _events,
            scenario: widget.scenario,
          ),
          right: _AlertReviewPanel(
            events: _events,
            selectedAlert: _selectedAlert,
            selectedAlertIndex: _selectedAlertIndex,
            notesController: _notesController,
            reviewMessage: _reviewMessage,
            onSelectAlert: _selectAlert,
            onConfirm: () => _reviewAlert(
              status: AlertStatus.confirmed,
              action: 'Confirmed alert',
              visibleMessage: 'Alert confirmed',
            ),
            onFalsePositive: () => _reviewAlert(
              status: AlertStatus.falsePositive,
              action: 'Marked false positive',
              visibleMessage: 'Alert marked false positive',
            ),
            onResolved: () => _reviewAlert(
              status: AlertStatus.resolved,
              action: 'Resolved alert',
              visibleMessage: 'Alert resolved',
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ResponsivePair(
          left: _SafetyCommandPanel(
            status: safetyStatus,
            checklist: _safetyChecklist,
            commandConfirmed: _commandConfirmed,
            commandMessage: _commandMessage,
            onConfirmationChanged: (value) {
              setState(() => _commandConfirmed = value ?? false);
            },
            onSubmitCommand: _submitCommand,
          ),
          right: _AuditLogPanel(entries: _auditEntries),
        ),
      ],
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(children: [left, const SizedBox(height: 12), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff24322f),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.scenario,
    required this.mission,
    required this.safetyStatus,
    required this.onConnectDji,
  });

  final Scenario scenario;
  final Mission mission;
  final SafetyGateStatus safetyStatus;
  final VoidCallback onConnectDji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff101820),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff29423d)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 740;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OFFICIAL WILDFIRE OPERATIONS',
                style: TextStyle(
                  color: Color(0xff7cc7ff),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Official/Public-Safety Prototype',
                style: TextStyle(
                  color: Color(0xffffc857),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mission.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${scenario.title} | ${mission.area}',
                style: const TextStyle(color: Color(0xffd7e7e1), height: 1.35),
              ),
              const SizedBox(height: 8),
              const Text(
                'Not production ready',
                style: TextStyle(
                  color: Color(0xffffc857),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );
          final statusPills = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                label: 'Simulation Mode',
                color: const Color(0xff7cc7ff),
              ),
              _StatusPill(
                label: safetyStatus.realHardwareDisabled
                    ? 'Real Hardware Disabled'
                    : 'Real Hardware Enabled',
                color: safetyStatus.realHardwareDisabled
                    ? const Color(0xffffc857)
                    : const Color(0xffff7a59),
              ),
              _StatusPill(
                label: safetyStatus.commandLocked
                    ? 'Command lock active'
                    : 'Command gate open',
                color: const Color(0xfff4a261),
              ),
              OutlinedButton.icon(
                onPressed: onConnectDji,
                icon: const Icon(Icons.settings_input_antenna, size: 17),
                label: const Text('Connect DJI Drone'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [summary, const SizedBox(height: 14), statusPills],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: summary),
              const SizedBox(width: 14),
              statusPills,
            ],
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MissionOverviewPanel extends StatelessWidget {
  const _MissionOverviewPanel({
    required this.mission,
    required this.scenario,
    required this.safetyStatus,
  });

  final Mission mission;
  final Scenario scenario;
  final SafetyGateStatus safetyStatus;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'MISSION OVERVIEW',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Incident', value: mission.name),
          _InfoRow(label: 'Scenario', value: scenario.title),
          _InfoRow(label: 'Area', value: mission.area),
          _InfoRow(label: 'Assigned drone', value: mission.assignedDroneId),
          _InfoRow(label: 'Operator', value: mission.operatorName),
          _InfoRow(label: 'Mission state', value: mission.status.label),
          _InfoRow(label: 'Geofence', value: safetyStatus.geofenceStatus.label),
          const SizedBox(height: 8),
          Text(
            mission.notes,
            style: const TextStyle(color: Color(0xff53615d), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _TelemetryPanel extends StatelessWidget {
  const _TelemetryPanel({required this.telemetry});

  final List<DroneTelemetry> telemetry;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'DRONE TELEMETRY',
      child: Column(
        children: [
          for (final item in telemetry) ...[
            _DroneTelemetryRow(item: item),
            if (item != telemetry.last) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _DroneTelemetryRow extends StatelessWidget {
  const _DroneTelemetryRow({required this.item});

  final DroneTelemetry item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 54,
          decoration: BoxDecoration(
            color: _linkColor(item.linkStatus),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.droneId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.altitudeMeters.toStringAsFixed(0)} m alt | ${item.speedMps.toStringAsFixed(1)} m/s | ${item.headingDeg.toStringAsFixed(0)} deg',
                style: const TextStyle(color: Color(0xff65736f)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.batteryPercent}%',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              item.linkStatus.label,
              style: TextStyle(
                color: _linkColor(item.linkStatus),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OperationsMapPanel extends StatelessWidget {
  const _OperationsMapPanel({
    required this.telemetry,
    required this.events,
    required this.scenario,
  });

  final List<DroneTelemetry> telemetry;
  final List<FireDetectionEvent> events;
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'OPERATIONS MAP',
      trailing: Text(
        scenario.region,
        style: const TextStyle(
          color: Color(0xff60716b),
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CustomPaint(
              painter: _OperationsMapPainter(
                telemetry: telemetry,
                events: events,
                baseColor: scenario.color,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LegendChip(color: const Color(0xff31a354), label: 'Drone'),
              _LegendChip(color: const Color(0xfff15a24), label: 'Alert'),
              _LegendChip(color: scenario.color, label: 'Route'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationsMapPainter extends CustomPainter {
  const _OperationsMapPainter({
    required this.telemetry,
    required this.events,
    required this.baseColor,
  });

  final List<DroneTelemetry> telemetry;
  final List<FireDetectionEvent> events;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xff13211d);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      background,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i += 1) {
      final x = size.width * i / 6;
      final y = size.height * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.95)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(size.width * 0.13, size.height * 0.74)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.56,
        size.width * 0.38,
        size.height * 0.34,
        size.width * 0.52,
        size.height * 0.46,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.58,
        size.width * 0.75,
        size.height * 0.27,
        size.width * 0.88,
        size.height * 0.35,
      );
    canvas.drawPath(route, routePaint);

    final firePaint = Paint()
      ..color = const Color(0xfff15a24).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.67, size.height * 0.45),
        width: size.width * 0.28,
        height: size.height * 0.22,
      ),
      firePaint,
    );

    for (var i = 0; i < telemetry.length; i += 1) {
      final point = Offset(
        size.width * (0.23 + i * 0.22),
        size.height * (0.65 - i * 0.12),
      );
      canvas.drawCircle(point, 7, Paint()..color = const Color(0xff31a354));
      canvas.drawCircle(
        point,
        13,
        Paint()
          ..color = const Color(0xff31a354).withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
    }

    for (var i = 0; i < events.length; i += 1) {
      final event = events[i];
      final point = Offset(
        size.width * (0.56 + (i % 2) * 0.18),
        size.height * (0.42 + i * 0.09),
      );
      canvas.drawCircle(
        point,
        event.status == AlertStatus.resolved ? 5 : 8,
        Paint()
          ..color = event.status == AlertStatus.resolved
              ? const Color(0xff8b9a96)
              : const Color(0xffff6b35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OperationsMapPainter oldDelegate) {
    return telemetry != oldDelegate.telemetry ||
        events != oldDelegate.events ||
        baseColor != oldDelegate.baseColor;
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff60716b),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AlertReviewPanel extends StatelessWidget {
  const _AlertReviewPanel({
    required this.events,
    required this.selectedAlert,
    required this.selectedAlertIndex,
    required this.notesController,
    required this.reviewMessage,
    required this.onSelectAlert,
    required this.onConfirm,
    required this.onFalsePositive,
    required this.onResolved,
  });

  final List<FireDetectionEvent> events;
  final FireDetectionEvent? selectedAlert;
  final int selectedAlertIndex;
  final TextEditingController notesController;
  final String? reviewMessage;
  final ValueChanged<int> onSelectAlert;
  final VoidCallback onConfirm;
  final VoidCallback onFalsePositive;
  final VoidCallback onResolved;

  @override
  Widget build(BuildContext context) {
    final event = selectedAlert;
    return _Panel(
      title: 'FIRE / SMOKE ALERTS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < events.length; i += 1)
                ChoiceChip(
                  label: Text('${events[i].detectionType.label} ${i + 1}'),
                  selected: i == selectedAlertIndex,
                  onSelected: (_) => onSelectAlert(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (event == null)
            const Text('No active alerts in this scenario.')
          else ...[
            Row(
              children: [
                Icon(
                  event.detectionType == DetectionType.fire
                      ? Icons.local_fire_department
                      : Icons.cloud_queue,
                  color: _severityColor(event.severity),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${event.detectionType.label} detection | ${event.severity.label}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${(event.confidence * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Confidence',
              value: '${(event.confidence * 100).round()}%',
            ),
            _InfoRow(label: 'Severity', value: event.severity.label),
            _InfoRow(label: 'Source', value: event.sourceDroneId),
            _InfoRow(
              label: 'Location',
              value: _coordLabel(event.lat, event.lon),
            ),
            _InfoRow(label: 'Frame', value: event.imagePlaceholder),
            _InfoRow(label: 'Status', value: event.status.label),
            const SizedBox(height: 10),
            TextField(
              controller: notesController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Review notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_circle_outline, size: 17),
                  label: const Text('Confirm'),
                ),
                OutlinedButton.icon(
                  onPressed: onFalsePositive,
                  icon: const Icon(Icons.report_gmailerrorred, size: 17),
                  label: const Text('False Positive'),
                ),
                OutlinedButton.icon(
                  onPressed: onResolved,
                  icon: const Icon(Icons.task_alt, size: 17),
                  label: const Text('Resolved'),
                ),
              ],
            ),
          ],
          if (reviewMessage != null) ...[
            const SizedBox(height: 10),
            _InlineNotice(
              icon: Icons.verified_outlined,
              color: const Color(0xff0e7656),
              message: reviewMessage!,
            ),
          ],
        ],
      ),
    );
  }
}

class _SafetyCommandPanel extends StatelessWidget {
  const _SafetyCommandPanel({
    required this.status,
    required this.checklist,
    required this.commandConfirmed,
    required this.commandMessage,
    required this.onConfirmationChanged,
    required this.onSubmitCommand,
  });

  final SafetyGateStatus status;
  final SafetyChecklist checklist;
  final bool commandConfirmed;
  final String? commandMessage;
  final ValueChanged<bool?> onConfirmationChanged;
  final ValueChanged<DroneCommandType> onSubmitCommand;

  @override
  Widget build(BuildContext context) {
    final commands = [
      DroneCommandType.arm,
      DroneCommandType.takeoff,
      DroneCommandType.land,
      DroneCommandType.rtl,
      DroneCommandType.start,
      DroneCommandType.pause,
      DroneCommandType.stop,
    ];
    return _Panel(
      title: 'SAFETY-GATED COMMANDS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'System mode', value: status.systemMode.label),
          _InfoRow(
            label: 'Hardware',
            value: status.realHardwareDisabled
                ? 'Real Hardware Disabled'
                : 'Real Hardware Enabled',
          ),
          _InfoRow(
            label: 'Operator confirmation',
            value: status.confirmationRequired ? 'Required' : 'Not required',
          ),
          _InfoRow(
            label: 'Geofence checklist',
            value: checklist.geofence.commandPanelValue,
          ),
          _InfoRow(
            label: 'Local geofence model',
            value: status.geofenceStatus.label,
          ),
          _InfoRow(
            label: 'Remote ID checklist',
            value: checklist.remoteId.commandPanelValue,
          ),
          _InfoRow(
            label: 'Airspace approval',
            value: checklist.airspaceApproval.commandPanelValue,
          ),
          _InfoRow(
            label: 'Emergency stop',
            value: checklist.emergencyStop.commandPanelValue,
          ),
          _InfoRow(
            label: 'Backend gate',
            value: status.commandLocked
                ? 'ALLOW_DJI_COMMANDS=false'
                : 'Command flow enabled',
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: commandConfirmed,
              onChanged: status.emergencyStopEngaged
                  ? null
                  : onConfirmationChanged,
              title: const Text(
                'I confirm this simulated command',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'No real aircraft command will be sent from this MVP.',
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final command in commands)
                FilledButton.tonal(
                  onPressed: commandConfirmed && !status.emergencyStopEngaged
                      ? () => onSubmitCommand(command)
                      : null,
                  child: Text(command.label),
                ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xffa63d40),
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    onSubmitCommand(DroneCommandType.emergencyStop),
                icon: const Icon(Icons.stop_circle_outlined, size: 17),
                label: const Text('Emergency Stop'),
              ),
            ],
          ),
          if (commandMessage != null) ...[
            const SizedBox(height: 10),
            _InlineNotice(
              icon: status.emergencyStopEngaged
                  ? Icons.warning_amber_outlined
                  : Icons.shield_outlined,
              color: status.emergencyStopEngaged
                  ? const Color(0xffa63d40)
                  : const Color(0xff0e7656),
              message: commandMessage!,
            ),
          ],
        ],
      ),
    );
  }
}

class _AuditLogPanel extends StatelessWidget {
  const _AuditLogPanel({required this.entries});

  final List<AuditLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'AUDIT LOG',
      child: entries.isEmpty
          ? const Text(
              'No operator actions recorded yet.',
              style: TextStyle(color: Color(0xff65736f)),
            )
          : Column(
              children: [
                for (final entry in entries.take(6)) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 18,
                        color: Color(0xff0e7656),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.action,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${entry.actor} | ${entry.targetId} | ${_timeLabel(entry.timestamp)}',
                              style: const TextStyle(
                                color: Color(0xff65736f),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              entry.details,
                              style: const TextStyle(
                                color: Color(0xff53615d),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (entry != entries.take(6).last) const Divider(height: 18),
                ],
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff65736f),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

Color _severityColor(AlertSeverity severity) {
  return switch (severity) {
    AlertSeverity.low => const Color(0xff31a354),
    AlertSeverity.medium => const Color(0xffffc857),
    AlertSeverity.high => const Color(0xffff7a59),
    AlertSeverity.critical => const Color(0xffa63d40),
  };
}

Color _linkColor(LinkStatus status) {
  return switch (status) {
    LinkStatus.simulated => const Color(0xff2364aa),
    LinkStatus.stable => const Color(0xff31a354),
    LinkStatus.degraded => const Color(0xffffc857),
    LinkStatus.offline => const Color(0xffa63d40),
    LinkStatus.notConfigured => const Color(0xff8b9a96),
  };
}

String _timeLabel(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _coordLabel(double lat, double lon) {
  return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
}
