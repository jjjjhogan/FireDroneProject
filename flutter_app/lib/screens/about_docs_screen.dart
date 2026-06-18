import 'package:flutter/material.dart';

import '../services/operations_api_client.dart';
import '../widgets/common/info_card.dart';
import '../widgets/common/metric_card.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/common/section_header.dart';

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
            const _SafetyRulesPanel(),
            const SizedBox(height: 14),
            const _ReferencePanel(),
            const SizedBox(height: 14),
            const _RoadmapPanel(),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff101820),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff29423d)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Official/Public-Safety Prototype',
            style: TextStyle(
              color: Color(0xff7cc7ff),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'AeroScout Command',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agency-grade wildfire drone operations prototype for simulated mission planning, alert review, safety gating, and integration planning.',
            style: TextStyle(color: Color(0xffd7e7e1), height: 1.4),
          ),
          SizedBox(height: 12),
          _NoticeRow(
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
            title: 'ADOSMissionControl',
            body:
                'Inspired the command-center information architecture, fleet telemetry grouping, and safety-gate separation.',
          ),
          _InfoPair(
            title: 'wildfire-detection',
            body:
                'Influenced fire/smoke confidence, severity, image-frame, and human review language.',
          ),
          _InfoPair(
            title: 'Real-Time-Fire-Smoke-Detection-Drone',
            body:
                'Informed the future edge-inference ingest path while keeping autonomous flight behavior out of this MVP.',
          ),
          _InfoPair(
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
        children: const [
          SectionHeader(
            title: 'Future Integration Roadmap',
            subtitle:
                'Next phases should prove simulation and security paths before any hardware command channel is considered.',
          ),
          SizedBox(height: 12),
          _ChecklistLine(
            'PX4 SITL and MAVSDK/MAVLink read-only telemetry adapters.',
          ),
          _ChecklistLine(
            'ArduPilot compatibility through the backend adapter layer.',
          ),
          _ChecklistLine(
            'Drone camera and thermal stream ingest with a YOLO fire/smoke API.',
          ),
          _ChecklistLine(
            'Authoritative GIS import, terrain overlays, and airspace/TFR validation.',
          ),
          _ChecklistLine(
            'Authentication, RBAC, secure deployment, and incident command workflow.',
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

class _InfoPair extends StatelessWidget {
  const _InfoPair({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(
            body,
            style: const TextStyle(color: Color(0xff53615d), height: 1.35),
          ),
        ],
      ),
    );
  }
}
