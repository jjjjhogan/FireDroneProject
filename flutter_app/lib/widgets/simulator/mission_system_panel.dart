import 'package:flutter/material.dart';

import '../../models/mission.dart';
import '../common/info_card.dart';

class MissionSystemPanel extends StatelessWidget {
  const MissionSystemPanel({
    required this.mission,
    this.onPause,
    this.onResume,
    this.onAbort,
    this.onComplete,
    super.key,
  });

  final MissionRecord? mission;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onAbort;
  final VoidCallback? onComplete;

  static const _stages = [
    ('planning', 'Plan'),
    ('preview_ready', 'Preview'),
    ('confirmed', 'Confirm'),
    ('active', 'Active'),
    ('paused', 'Paused'),
    ('completed', 'Complete'),
  ];

  @override
  Widget build(BuildContext context) {
    final record = mission;
    return InfoCard(
      color: const Color(0xff0f241f),
      borderColor: const Color(0xff29423d),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.route, color: Color(0xffb7f1d8)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MISSION SYSTEM',
                      style: TextStyle(
                        color: Color(0xff7cc7ff),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Plan → Preview → Confirm → Active lifecycle with backend persistence.',
                      style: TextStyle(color: Color(0xffd7e7e1), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (record == null)
            const Text(
              'Planning mission package for the selected scenario…',
              style: TextStyle(color: Color(0xffd7e7e1)),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(label: record.missionId),
                _MetaChip(label: record.dataSource),
                _MetaChip(label: '${record.progressPct}% progress'),
                if (record.estimatedDurationMin > 0)
                  _MetaChip(label: '${record.estimatedDurationMin} min est.'),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                return Wrap(
                  spacing: compact ? 8 : 12,
                  runSpacing: 10,
                  children: [
                    for (final stage in _stages)
                      _StageChip(
                        label: stage.$2,
                        active: _isStageActive(record.status, stage.$1),
                        complete: _isStageComplete(record.status, stage.$1),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              record.notes,
              style: const TextStyle(color: Color(0xffaebbb5), height: 1.35),
            ),
            if (!record.isTerminal) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (record.canPause)
                    OutlinedButton.icon(
                      onPressed: onPause,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause mission'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xff314046)),
                      ),
                    ),
                  if (record.status == 'paused')
                    FilledButton.icon(
                      onPressed: onResume,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff16845f),
                      ),
                    ),
                  if (record.canAbort)
                    OutlinedButton.icon(
                      onPressed: onAbort,
                      icon: const Icon(Icons.stop),
                      label: const Text('Abort mission'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffff6157),
                        side: const BorderSide(color: Color(0xffff6157)),
                      ),
                    ),
                  if (record.status == 'active' || record.status == 'paused')
                    OutlinedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark complete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffb7f1d8),
                        side: const BorderSide(color: Color(0xffb7f1d8)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  bool _isStageActive(String current, String stage) => current == stage;

  bool _isStageComplete(String current, String stage) {
    const order = [
      'planning',
      'preview_ready',
      'confirmed',
      'active',
      'paused',
      'completed',
      'aborted',
    ];
    final currentIndex = order.indexOf(current);
    final stageIndex = order.indexOf(stage);
    if (current == 'aborted') {
      return stageIndex <= order.indexOf('confirmed');
    }
    if (currentIndex < 0 || stageIndex < 0) {
      return false;
    }
    return currentIndex > stageIndex;
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xffd7e7e1),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.active,
    required this.complete,
  });

  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xff16845f)
        : complete
        ? const Color(0xff2364aa)
        : const Color(0xff314046);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? color : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete
                ? Icons.check_circle
                : active
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            size: 14,
            color: active ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
