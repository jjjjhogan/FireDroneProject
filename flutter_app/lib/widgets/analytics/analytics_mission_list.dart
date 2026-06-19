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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff0e7656).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_toggle_off,
                  size: 18,
                  color: Color(0xff0e7656),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Missions',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Historical sortie records ready for backend sync.',
                      style: TextStyle(color: Color(0xff62716c), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (missions.isEmpty)
            const Text(
              'No recent missions available.',
              style: TextStyle(
                color: Color(0xff62716c),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (var i = 0; i < missions.length; i++) ...[
              _MissionRow(mission: missions[i], index: i + 1),
              if (i != missions.length - 1)
                const Divider(height: 22, color: Color(0xffe5ece8)),
            ],
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission, required this.index});

  final AnalyticsMissionRecord mission;
  final int index;

  @override
  Widget build(BuildContext context) {
    final completed = mission.outcome == 'completed';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: completed
              ? const Color(0xffeef8f2)
              : const Color(0xfffff4ef),
          child: Text(
            '$index',
            style: TextStyle(
              color: completed
                  ? const Color(0xff0e7656)
                  : const Color(0xff9a3412),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
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
        ),
        StatusPill(
          label: mission.outcome,
          color: completed
              ? const Color(0xffb7f1d8)
              : const Color(0xffffd9a8),
        ),
      ],
    );
  }
}
