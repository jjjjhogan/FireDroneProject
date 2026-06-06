import 'package:flutter/material.dart';

import '../../models/scenario.dart';
import '../common/info_card.dart';
import '../common/status_pill.dart';

class ScenarioCard extends StatelessWidget {
  const ScenarioCard({
    required this.scenario,
    required this.onOpenSimulator,
    super.key,
  });

  final Scenario scenario;
  final VoidCallback onOpenSimulator;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.65,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      scenario.image,
                      fit: BoxFit.cover,
                      semanticLabel: 'Generated landscape for ${scenario.name}',
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x22000000),
                            Color(0x88000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: StatusPill(
                        label: '${scenario.region} region',
                        color: scenario.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            scenario.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            scenario.description,
            style: const TextStyle(color: Color(0xff65736f), height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: '${scenario.drones} drones',
                color: const Color(0xff0e7656),
              ),
              StatusPill(label: scenario.risk, color: const Color(0xffc2542d)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenSimulator,
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('Open in Simulator'),
            ),
          ),
        ],
      ),
    );
  }
}
