import 'package:flutter/material.dart';

import '../../models/simulation_layout.dart';

class SimulationControls extends StatelessWidget {
  const SimulationControls({
    required this.runState,
    required this.progress,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    super.key,
  });

  final SimulationRunState runState;
  final double progress;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final isRunning = runState == SimulationRunState.running;
    final isComplete = runState == SimulationRunState.complete;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdfe8e4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: const Color(0xffe6efeb),
                  color: isComplete
                      ? const Color(0xff2f7d9a)
                      : const Color(0xff0e7656),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xff10231d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: isRunning ? null : onStart,
                icon: Icon(isComplete ? Icons.replay : Icons.play_arrow),
                label: Text(isComplete ? 'Run again' : 'Start run'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isRunning ? onPause : null,
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.stop),
                label: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
