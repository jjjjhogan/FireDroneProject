import 'package:flutter/material.dart';

import '../models/drone_connection.dart';
import '../models/scenario.dart';
import '../services/drone_api_client.dart';
import '../services/scenario_library_service.dart';
import '../widgets/common/info_card.dart';
import '../widgets/common/metric_card.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/common/section_header.dart';
import '../widgets/scenario/hero_panel.dart';
import '../widgets/scenario/region_profile_panel.dart';
import '../widgets/scenario/scenario_card.dart';

class ScenarioLibraryScreen extends StatefulWidget {
  const ScenarioLibraryScreen({
    required this.scenarioService,
    required this.onOpenSimulator,
    required this.droneClient,
    super.key,
  });

  final ScenarioLibraryService scenarioService;
  final ValueChanged<Scenario> onOpenSimulator;
  final DroneApiClient droneClient;

  @override
  State<ScenarioLibraryScreen> createState() => _ScenarioLibraryScreenState();
}

class _ScenarioLibraryScreenState extends State<ScenarioLibraryScreen> {
  final _searchController = TextEditingController();
  late Future<DjiStatus> _statusFuture;
  late Future<List<Scenario>> _scenarioFuture;
  String _region = 'All';
  Scenario? _selectedScenario;

  @override
  void initState() {
    super.initState();
    _statusFuture = widget.droneClient.fetchStatus();
    _scenarioFuture = widget.scenarioService.searchScenarios();
  }

  @override
  void didUpdateWidget(covariant ScenarioLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.droneClient != widget.droneClient) {
      _statusFuture = widget.droneClient.fetchStatus();
    }
    if (oldWidget.scenarioService != widget.scenarioService) {
      _refreshScenarios();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshScenarios() {
    setState(() {
      _scenarioFuture = widget.scenarioService.searchScenarios(
        query: _searchController.text,
        region: _region,
      );
    });
  }

  void _setRegion(String region) {
    _region = region;
    _refreshScenarios();
  }

  void _selectScenario(Scenario scenario) {
    setState(() => _selectedScenario = scenario);
  }

  Scenario _resolvedSelectedScenario(List<Scenario> scenarios) {
    final selected = _selectedScenario;
    if (selected != null &&
        scenarios.any(
          (scenario) => scenario.scenarioId == selected.scenarioId,
        )) {
      return selected;
    }
    return scenarios.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<DjiStatus>(
          future: _statusFuture,
          builder: (context, snapshot) {
            final status = snapshot.data;
            return HeroPanel(
              title: 'DJI-ready wildfire mission control',
              body:
                  'Preview fire-zone routes, verify telemetry links, and prepare mission packages before a human releases any DJI command.',
              linkLabel: _scenarioLinkLabel(status),
              readiness: status?.commandEnabled ?? false
                  ? 'Commands enabled'
                  : 'Command gate locked',
            );
          },
        ),
        const SizedBox(height: 18),
        FutureBuilder<DjiStatus>(
          future: _statusFuture,
          builder: (context, snapshot) {
            final status = snapshot.data;
            final connected = status?.liveData ?? false;
            final bridgeConfigured =
                status != null && status.connection != 'not-configured';
            return ResponsiveGrid(
              children: [
                MetricCard(
                  icon: Icons.sensors,
                  label: 'DJI Link',
                  value: connected
                      ? '${status!.aircraftCount} aircraft'
                      : bridgeConfigured
                      ? status.connection
                      : 'Not configured',
                  detail: connected
                      ? 'Reading verified aircraft state from DJI ingest'
                      : bridgeConfigured
                      ? 'Waiting for fresh aircraft telemetry'
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
                  value: connected ? 'Operator feed' : 'No live feed',
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
        ),
        const SizedBox(height: 14),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search scenarios',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _refreshScenarios(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: regions.map((item) {
                  final profile = regionProfileFor(item);
                  return ChoiceChip(
                    avatar: profile == null
                        ? null
                        : Icon(profile.icon, size: 16, color: profile.accent),
                    label: Text(item),
                    selected: _region == item,
                    onSelected: (_) => _setRegion(item),
                  );
                }).toList(),
              ),
              if (_region != 'All') ...[
                const SizedBox(height: 12),
                RegionProfilePanel(profile: regionProfileForScenario(_region)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<Scenario>>(
          future: _scenarioFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const InfoCard(
                child: Text(
                  'Loading scenarios',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              );
            }

            if (snapshot.hasError) {
              return InfoCard(
                borderColor: const Color(0xffffb199),
                color: const Color(0xfffff4ef),
                child: Text(
                  'Scenario library unavailable: ${snapshot.error}',
                  style: const TextStyle(
                    color: Color(0xff7c2d12),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }

            final visibleScenarios = snapshot.data ?? const <Scenario>[];
            if (visibleScenarios.isEmpty) {
              return const InfoCard(
                child: Text(
                  'No scenarios match this search.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              );
            }

            final selectedScenario = _resolvedSelectedScenario(
              visibleScenarios,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectedScenarioPanel(
                  scenario: selectedScenario,
                  onOpenSimulator: () =>
                      widget.onOpenSimulator(selectedScenario),
                ),
                const SizedBox(height: 14),
                ResponsiveGrid(
                  children: visibleScenarios
                      .map(
                        (scenario) => GestureDetector(
                          onTap: () => _selectScenario(scenario),
                          child: ScenarioCard(
                            scenario: scenario,
                            selected:
                                selectedScenario.scenarioId ==
                                scenario.scenarioId,
                            onOpenSimulator: () =>
                                widget.onOpenSimulator(scenario),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SelectedScenarioPanel extends StatelessWidget {
  const _SelectedScenarioPanel({
    required this.scenario,
    required this.onOpenSimulator,
  });

  final Scenario scenario;
  final VoidCallback onOpenSimulator;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      borderColor: const Color(0xffb6d8c7),
      color: const Color(0xfff7fbf9),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Scenario',
                style: TextStyle(
                  color: Color(0xff0e7656),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                scenario.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Simulated mission planning package',
                style: TextStyle(
                  color: Color(0xff53615d),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _ScenarioFact(label: 'Region', value: scenario.region),
                  _ScenarioFact(label: 'Difficulty', value: scenario.risk),
                  _ScenarioFact(
                    label: 'Aircraft',
                    value: '${scenario.simulatedDroneCount}',
                  ),
                  _ScenarioFact(
                    label: 'Alerts',
                    value: '${scenario.simulatedAlertCount}',
                  ),
                ],
              ),
            ],
          );
          final action = FilledButton.icon(
            onPressed: onOpenSimulator,
            icon: const Icon(Icons.radar_outlined, size: 17),
            label: const Text('Open Selected Scenario'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [summary, const SizedBox(height: 12), action],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: summary),
              const SizedBox(width: 18),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _ScenarioFact extends StatelessWidget {
  const _ScenarioFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffdfe8e4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xff24322f)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xff60716b),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

String _scenarioLinkLabel(DjiStatus? status) {
  if (status == null) return 'DJI Link standby';
  if (status.connection == 'not-configured') {
    return 'DJI connector not configured';
  }
  if (status.connection == 'waiting-for-bridge') {
    return 'Waiting for DJI bridge';
  }
  if (status.connection == 'bridge-stale') {
    return 'DJI bridge stale';
  }
  if (status.liveData) {
    return 'DJI Link · ${status.source}';
  }
  return 'DJI Link · ${status.connection}';
}
