import 'package:flutter/material.dart';

import '../../models/analytics_snapshot.dart';
import '../common/info_card.dart';
import '../common/status_pill.dart';

class AnalyticsMissionList extends StatelessWidget {
  const AnalyticsMissionList({required this.missions, super.key});

  final List<AnalyticsMissionRecord> missions;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Missions',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Historical sortie records ready for backend sync.',
            style: TextStyle(color: Color(0xff62716c), height: 1.35),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < missions.length; i++) ...[
            _MissionRow(mission: missions[i]),
            if (i != missions.length - 1)
              const Divider(height: 22, color: Color(0xffe5ece8)),
          ],
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission});

  final AnalyticsMissionRecord mission;

  @override
  Widget build(BuildContext context) {
    final completed = mission.outcome == 'completed';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mission.scenarioName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${mission.missionId} · ${mission.completedAt}',
                style: const TextStyle(color: Color(0xff62716c), fontSize: 12),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusPill(
              label: mission.outcome,
              color: completed
                  ? const Color(0xffb7f1d8)
                  : const Color(0xffffd9a8),
            ),
            const SizedBox(height: 8),
            Text(
              '${mission.durationMin} min · ${mission.hotspotsDetected} hotspots',
              style: const TextStyle(
                color: Color(0xff60716b),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
