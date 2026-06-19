import 'package:flutter/material.dart';

import '../services/operations_api_client.dart';
import '../widgets/common/info_card.dart';
import '../widgets/common/metric_card.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_pill.dart';

class AboutDocsScreen extends StatelessWidget {
  const AboutDocsScreen({required this.operationsClient, super.key});

  final OperationsApiClient operationsClient;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BackendIntegrationStatus>(
      future: operationsClient.fetchIntegrationStatus(),
      builder: (context, snapshot) {
        final status = snapshot.data ?? BackendIntegrationStatus.unavailable();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AboutHero(),
            const SizedBox(height: 14),
            const _PurposePanel(),
            const SizedBox(height: 14),
            ResponsiveGrid(
              children: [
                const MetricCard(
                  icon: Icons.science_outlined,
                  label: 'Simulation Mode',
                  value: 'Default',
                  detail:
                      'The prototype uses simulated mission, alert, and telemetry data unless a read-only adapter is configured.',
                  accent: Color(0xff2364aa),
                ),
                MetricCard(
                  icon: Icons.lock_outline,
                  label: 'Real Hardware Disabled',
                  value: status.hardwareCommandsEnabled
                      ? 'Review required'
                      : 'Locked',
                  detail:
                      'No aircraft arm, takeoff, mission upload, or flight command is dispatched by this interface.',
                  accent: const Color(0xffa63d40),
                ),
                const MetricCard(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Operator Review',
                  value: 'Required',
                  detail:
                      'Fire and smoke detections stay unconfirmed until an operator reviews and records a decision.',
                  accent: Color(0xff0e7656),
                ),
                MetricCard(
                  icon: Icons.storage_outlined,
                  label: 'Backend Persistence',
                  value: status.available
                      ? status.persistenceEngine
                      : 'Local fallback',
                  detail:
                      'Audit ${status.auditPersistence}; alerts ${status.alertPersistence}; RBAC ${status.rbacEnabled ? "enabled" : "offline/dev"}',
                  accent: const Color(0xff456990),
                ),
                MetricCard(
                  icon: Icons.map_outlined,
                  label: 'Map Provider',
                  value: status.mapProvider,
                  detail: status.mapConfigured
                      ? 'Tile provider and GeoJSON layer configured by backend'
                      : 'Using local map placeholder',
                  accent: const Color(0xff0e7656),
                ),
                MetricCard(
                  icon: Icons.hub_outlined,
                  label: 'PX4/MAVLink',
                  value: '${status.px4Sitl} / ${status.mavlink}',
                  detail:
                      'ArduPilot ${status.ardupilot}; YOLO/Thermal ${status.yoloThermal}',
                  accent: const Color(0xff725ac1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _CommandFlowPanel(),
            const SizedBox(height: 14),
            const _SafetyRulesPanel(),
            const SizedBox(height: 14),
            const _OperatorDutiesPanel(),
            const SizedBox(height: 14),
            const _ProhibitedUsesPanel(),
            const SizedBox(height: 14),
            const _ReferencePanel(),
            const SizedBox(height: 14),
            const _RoadmapPanel(),
            const SizedBox(height: 14),
            const _DocumentationPanel(),
          ],
        );
      },
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff071512), Color(0xff101820), Color(0xff142f28)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff29423d)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Official/Public-Safety Prototype',
            style: TextStyle(
              color: Color(0xff7cc7ff),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'About & Safety',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'AeroScout Command',
            style: TextStyle(
              color: Color(0xffb7f1d8),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Agency-grade wildfire drone operations prototype for simulated mission planning, alert review, safety gating, and integration planning.',
            style: TextStyle(color: Color(0xffd7e7e1), height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              StatusPill(label: 'Simulation Mode', color: Color(0xff2364aa)),
              StatusPill(
                label: 'Real Hardware Disabled',
                color: Color(0xffa63d40),
              ),
              StatusPill(label: 'Not production ready', color: Color(0xffffc857)),
            ],
          ),
          const SizedBox(height: 14),
          const _NoticeRow(
            icon: Icons.warning_amber_outlined,
            title: 'Not production ready',
            body:
                'Use this interface for prototype review and simulation only. Real wildfire-area drone operations require authorization, trained operators, compliant hardware, airspace clearance, and agency procedures.',
          ),
        ],
      ),
    );
  }
}

class _PurposePanel extends StatelessWidget {
  const _PurposePanel();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        final designedFor = _PurposeColumn(
          title: 'Designed for',
          icon: Icons.check_circle_outline,
          accent: const Color(0xff0e7656),
          items: const [
            'Incident command dashboard review and training',
            'Simulated mission planning and scenario rehearsal',
            'Fire/smoke alert triage with human confirmation',
            'Safety-gated command workflow prototyping',
            'DJI, PX4, and vision-system integration design',
          ],
        );
        final notDesignedFor = _PurposeColumn(
          title: 'Not designed for',
          icon: Icons.block_outlined,
          accent: const Color(0xffa63d40),
          items: const [
            'Live emergency response without agency authorization',
            'Unsupervised autonomous fire attack',
            'Replacing certified GCS or pilot-in-command authority',
            'Regulatory compliance or airspace approval proof',
            'Dispatching real aircraft commands from this UI',
          ],
        );

        if (stacked) {
          return Column(
            children: [
              designedFor,
              const SizedBox(height: 12),
              notDesignedFor,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: designedFor),
            const SizedBox(width: 14),
            Expanded(child: notDesignedFor),
          ],
        );
      },
    );
  }
}

class _PurposeColumn extends StatelessWidget {
  const _PurposeColumn({
    required this.title,
    required this.icon,
    required this.accent,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 7, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xff53615d),
                        height: 1.35,
                      ),
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

class _CommandFlowPanel extends StatelessWidget {
  const _CommandFlowPanel();

  static const _steps = [
    'Operator confirmation',
    'CommandRequest built in UI',
    'SafetyGateService evaluation',
    'CommandResult accepted or blocked',
    'AuditLogEntry recorded',
    'UI status update (no hardware dispatch)',
  ];

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      color: const Color(0xfff8fbfa),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Command Safety Flow',
            subtitle:
                'Every simulated command follows the same conservative path before any UI success message appears.',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    SizedBox(
                      width: compact ? double.infinity : 190,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xffdfe8e4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xff0e7656),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _steps[i],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SafetyRulesPanel extends StatelessWidget {
  const _SafetyRulesPanel();

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: 'Safety Rules',
            subtitle:
                'The current app keeps every control in simulation mode and preserves an operator-visible audit trail.',
          ),
          SizedBox(height: 12),
          _ChecklistLine(
            'Human confirmation is required before a command is simulated.',
          ),
          _ChecklistLine('SafetyGateService evaluates every command request.'),
          _ChecklistLine('CommandResult records accepted or blocked outcomes.'),
          _ChecklistLine(
            'AuditLogEntry is created for alert reviews and command attempts.',
          ),
          _ChecklistLine(
            'Emergency Stop is a simulation lock placeholder, not a hardware kill switch.',
          ),
          _ChecklistLine(
            'Geofence, Remote ID, and airspace approval are backend checklist records, not automatic compliance proof.',
          ),
        ],
      ),
    );
  }
}

class _OperatorDutiesPanel extends StatelessWidget {
  const _OperatorDutiesPanel();

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: 'Operator Responsibilities',
            subtitle:
                'Even in simulation, the workflow models the habits expected in a real public-safety drone program.',
          ),
          SizedBox(height: 12),
          _ChecklistLine(
            'Review every fire/smoke alert before treating it as actionable intelligence.',
          ),
          _ChecklistLine(
            'Confirm checklist items for geofence, Remote ID, and airspace approval before simulating dispatch.',
          ),
          _ChecklistLine(
            'Treat DJI and telemetry feeds as decision support until verified by trained personnel.',
          ),
          _ChecklistLine(
            'Record rationale in the audit trail when confirming, rejecting, or resolving alerts.',
          ),
          _ChecklistLine(
            'Escalate to incident command before assuming this dashboard authorizes real flight.',
          ),
        ],
      ),
    );
  }
}

class _ProhibitedUsesPanel extends StatelessWidget {
  const _ProhibitedUsesPanel();

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      color: const Color(0xfffff4ef),
      borderColor: const Color(0xffffb199),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: 'Prohibited Uses',
            subtitle:
                'Do not use AeroScout Command for real wildfire response without a separate authorized operations program.',
          ),
          SizedBox(height: 12),
          _WarningLine(
            'Flying drones in active wildfire airspace without agency authorization and airspace clearance.',
          ),
          _WarningLine(
            'Treating simulated detections as official fire confirmations or evacuation triggers.',
          ),
          _WarningLine(
            'Bypassing SafetyGateService or hiding simulation labels from operators or reviewers.',
          ),
          _WarningLine(
            'Enabling hardware command gates without legal, aviation, and agency review.',
          ),
        ],
      ),
    );
  }
}

class _ReferencePanel extends StatelessWidget {
  const _ReferencePanel();

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: 'GitHub Integration References',
            subtitle:
                'External projects influenced architecture and UX patterns only; no unrelated source code was copied.',
          ),
          SizedBox(height: 12),
          _InfoPair(
            icon: Icons.dashboard_customize_outlined,
            title: 'ADOSMissionControl',
            body:
                'Inspired the command-center information architecture, fleet telemetry grouping, and safety-gate separation.',
          ),
          _InfoPair(
            icon: Icons.local_fire_department_outlined,
            title: 'wildfire-detection',
            body:
                'Influenced fire/smoke confidence, severity, image-frame, and human review language.',
          ),
          _InfoPair(
            icon: Icons.videocam_outlined,
            title: 'Real-Time-Fire-Smoke-Detection-Drone',
            body:
                'Informed the future edge-inference ingest path while keeping autonomous flight behavior out of this MVP.',
          ),
          _InfoPair(
            icon: Icons.hub_outlined,
            title: 'PX4, MAVSDK, MAVLink, ArduPilot',
            body:
                'Shape future simulation and read-only telemetry adapters behind the backend boundary.',
          ),
        ],
      ),
    );
  }
}

class _RoadmapPanel extends StatelessWidget {
  const _RoadmapPanel();

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Future Integration Roadmap',
            subtitle:
                'Next phases should prove simulation and security paths before any hardware command channel is considered.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              StatusPill(label: 'Phase 1 · Simulation', color: Color(0xffb7f1d8)),
              StatusPill(label: 'Phase 2 · Read-only feeds', color: Color(0xffd7ecff)),
              StatusPill(label: 'Phase 3 · Hardened ops', color: Color(0xffffd9a8)),
            ],
          ),
          const SizedBox(height: 14),
          const _ChecklistLine(
            'PX4 SITL and MAVSDK/MAVLink read-only telemetry adapters.',
          ),
          const _ChecklistLine(
            'ArduPilot compatibility through the backend adapter layer.',
          ),
          const _ChecklistLine(
            'Drone camera and thermal stream ingest with a YOLO fire/smoke API.',
          ),
          const _ChecklistLine(
            'Authoritative GIS import, terrain overlays, and airspace/TFR validation.',
          ),
          const _ChecklistLine(
            'Real map provider, incident layers, geofences, and no-fly overlays.',
          ),
          const _ChecklistLine(
            'Authentication, RBAC, secure deployment, and incident command workflow.',
          ),
        ],
      ),
    );
  }
}

class _DocumentationPanel extends StatelessWidget {
  const _DocumentationPanel();

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      color: const Color(0xfff8fbfa),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: 'Repository Documentation',
            subtitle:
                'Additional safety, integration, and roadmap detail lives in the project docs folder.',
          ),
          SizedBox(height: 12),
          _InfoPair(
            icon: Icons.policy_outlined,
            title: 'docs/SAFETY.md',
            body: 'Command flow, audit logging, alert review, and safety policy.',
          ),
          _InfoPair(
            icon: Icons.integration_instructions_outlined,
            title: 'docs/DJI_REAL_INTEGRATION.md',
            body: 'DJI Cloud API and Mobile SDK bridge boundaries.',
          ),
          _InfoPair(
            icon: Icons.route_outlined,
            title: 'docs/FUTURE_INTEGRATION.md',
            body: 'Long-term adapter and deployment roadmap.',
          ),
        ],
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffffc857).withValues(alpha: 0.12),
        border: Border.all(
          color: const Color(0xffffc857).withValues(alpha: 0.45),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xffffc857), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xffd7e7e1),
                    height: 1.35,
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

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: Color(0xff0e7656),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xff53615d), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningLine extends StatelessWidget {
  const _WarningLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, size: 18, color: Color(0xffa63d40)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xff7c2d12), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPair extends StatelessWidget {
  const _InfoPair({
    required this.title,
    required this.body,
    this.icon,
  });

  final String title;
  final String body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xff0e7656)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xff53615d),
                    height: 1.35,
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
