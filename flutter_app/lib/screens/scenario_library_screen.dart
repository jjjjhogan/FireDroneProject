import 'package:flutter/material.dart';

import '../models/drone_connection.dart';
import '../models/scenario.dart';
import '../services/drone_api_client.dart';
import '../widgets/common/metric_card.dart';
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
    required this.droneClient,
    super.key,
  });

  final String region;
  final List<Scenario> visibleScenarios;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<Scenario> onOpenSimulator;
  final DroneApiClient droneClient;

  @override
  Widget build(BuildContext context) {
    final statusFuture = droneClient.fetchStatus();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<DjiStatus>(
          future: statusFuture,
          builder: (context, snapshot) {
            final status = snapshot.data;
            return HeroPanel(
              title: 'DJI-ready wildfire mission control',
              body:
                  'Preview fire-zone routes, verify telemetry links, and prepare mission packages before a human releases any DJI command.',
              linkLabel: status == null
                  ? 'DJI Link standby'
                  : status.connection == 'not-configured'
                  ? 'DJI connector not configured'
                  : 'DJI Link · ${status.connector}',
              readiness: status?.commandEnabled ?? false
                  ? 'Commands enabled'
                  : 'Command gate locked',
            );
          },
        ),
        const SizedBox(height: 18),
        FutureBuilder<DjiStatus>(
          future: statusFuture,
          builder: (context, snapshot) {
            final status = snapshot.data;
            final configured =
                status != null && status.connection != 'not-configured';
            return ResponsiveGrid(
              children: [
                MetricCard(
                  icon: Icons.sensors,
                  label: 'DJI Link',
                  value: configured ? 'Configured' : 'Not configured',
                  detail: configured
                      ? 'Reading status from the configured DJI connector'
                      : 'No fake aircraft data is shown without DJI setup',
                ),
                const MetricCard(
                  icon: Icons.verified_user_outlined,
                  label: 'Mission Readiness',
                  value: 'Preview only',
                  detail: 'Manual confirmation required before dispatch',
                ),
                MetricCard(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Fire Perimeter',
                  value: configured ? 'Live feed required' : 'No live feed',
                  detail:
                      'Connect DJI data feeds before treating map layers as live',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Mission Scenarios',
          subtitle:
              'Pick a terrain profile, then open it in the DJI mission preview.',
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
