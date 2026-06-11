import 'package:flutter/material.dart';

import '../models/scenario.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/common/section_header.dart';
import '../widgets/scenario/hero_panel.dart';
import '../widgets/scenario/scenario_card.dart';

class ScenarioLibraryScreen extends StatelessWidget {
  const ScenarioLibraryScreen({
    required this.region,
    required this.visibleScenarios,
    required this.onRegionChanged,
    required this.onOpenSimulator,
    super.key,
  });

  final String region;
  final List<Scenario> visibleScenarios;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<Scenario> onOpenSimulator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HeroPanel(
          title: 'Cooperative wildfire patrol planning',
          body:
              'Tune drone routes, sensor cadence, and terrain response before sending a fleet into a live fire zone.',
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Pre-built Scenarios',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: regions
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(item),
                      selected: region == item,
                      onSelected: (_) => onRegionChanged(item),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        ResponsiveGrid(
          children: visibleScenarios
              .map(
                (scenario) => ScenarioCard(
                  scenario: scenario,
                  onOpenSimulator: () => onOpenSimulator(scenario),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
