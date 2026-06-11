import 'package:flutter/material.dart';

import 'app/aero_scout_app.dart';

export 'app/aero_scout_app.dart';
export 'app/aero_scout_shell.dart';

void main() {
  runApp(const AeroScoutApp());
}

class AeroScoutApp extends StatelessWidget {
  const AeroScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroScout Sim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0c7c59),
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const AeroScoutShell(),
    );
  }
}

class AeroScoutShell extends StatefulWidget {
  const AeroScoutShell({super.key});

  @override
  State<AeroScoutShell> createState() => _AeroScoutShellState();
}

class _AeroScoutShellState extends State<AeroScoutShell> {
  int _page = 0;
  String _region = 'All';

  static const _nav = [
    NavItem(Icons.dashboard_outlined, 'Scenario Library'),
    NavItem(Icons.radar_outlined, 'Live Simulator'),
    NavItem(Icons.flight_takeoff_outlined, 'Drone Fleet'),
    NavItem(Icons.monitor_heart_outlined, 'Analytics'),
  ];

  Iterable<Scenario> get _visibleScenarios {
    if (_region == 'All') {
      return scenarios;
    }
    return scenarios.where((scenario) => scenario.region == _region);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final page = switch (_page) {
      0 => ScenarioLibrary(
        region: _region,
        visibleScenarios: _visibleScenarios.toList(),
        onRegionChanged: (region) => setState(() => _region = region),
      ),
      1 => const LiveSimulator(),
      2 => const FleetPage(),
      _ => const AnalyticsPage(),
    };

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f5),
      body: Row(
        children: [
          if (!compact)
            Sidebar(
              items: _nav,
              selected: _page,
              onSelect: (index) => setState(() => _page = index),
            ),
          Expanded(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TopBar(
                    compact: compact,
                    title: _nav[_page].label,
                    onMenuTap: () {},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 28,
                        18,
                        compact ? 16 : 28,
                        compact ? 96 : 28,
                      ),
                      child: page,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: compact
          ? NavigationBar(
              selectedIndex: _page,
              onDestinationSelected: (index) => setState(() => _page = index),
              destinations: _nav
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({
    required this.compact,
    required this.title,
    required this.onMenuTap,
    super.key,
  });

  final bool compact;
  final String title;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 16, compact ? 16 : 28, 0),
      child: Row(
        children: [
          if (compact)
            IconButton(
              tooltip: 'Menu',
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AeroScout Sim',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Mission Control',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xff62716c),
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            StatusPill(label: 'Online', color: const Color(0xff12805c)),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ],
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({
    required this.items,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      color: const Color(0xff10231d),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_fire_department, color: Color(0xffffc857)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AeroScout Sim',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              for (var index = 0; index < items.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: selected == index
                          ? const Color(0xff10231d)
                          : const Color(0xffd8e7e1),
                      backgroundColor: selected == index
                          ? const Color(0xffb7f1d8)
                          : Colors.transparent,
                      minimumSize: const Size.fromHeight(46),
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => onSelect(index),
                    icon: Icon(items[index].icon),
                    label: Text(items[index].label),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff1b382f),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Mission planner synced with 12 drone profiles and 4 fire behavior models.',
                  style: TextStyle(color: Color(0xffc9ddd5), height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScenarioLibrary extends StatefulWidget {
  const ScenarioLibrary({
    required this.region,
    required this.visibleScenarios,
    required this.onRegionChanged,
    super.key,
  });

  final String region;
  final List<Scenario> visibleScenarios;
  final ValueChanged<String> onRegionChanged;

  @override
  State<ScenarioLibrary> createState() => _ScenarioLibraryState();
}

class _ScenarioLibraryState extends State<ScenarioLibrary> {
  String _query = '';
  String? _selectedScenarioId;
  int _droneAdjustment = 0;
  String _workflowNote = 'Select a scenario to review mission readiness.';

  List<Scenario> get _filteredScenarios {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return widget.visibleScenarios;
    }

    return widget.visibleScenarios.where((scenario) {
      return scenario.name.toLowerCase().contains(normalized) ||
          scenario.location.toLowerCase().contains(normalized) ||
          scenario.region.toLowerCase().contains(normalized) ||
          scenario.description.toLowerCase().contains(normalized);
    }).toList();
  }

  Scenario get _selectedScenario {
    final visible = _filteredScenarios;
    if (visible.isEmpty) {
      return scenarios.first;
    }
    return visible.firstWhere(
      (scenario) => scenario.id == _selectedScenarioId,
      orElse: () => visible.first,
    );
  }

  int get _configuredDrones =>
      math.max(2, _selectedScenario.drones + _droneAdjustment);

  int get _readiness {
    final adjusted = _selectedScenario.readiness + (_configuredDrones * 2);
    return adjusted.clamp(72, 98).toInt();
  }

  @override
  void didUpdateWidget(covariant ScenarioLibrary oldWidget) {
    super.didUpdateWidget(oldWidget);
    final visibleIds = _filteredScenarios
        .map((scenario) => scenario.id)
        .toSet();
    if (_selectedScenarioId != null &&
        !visibleIds.contains(_selectedScenarioId)) {
      _selectedScenarioId = _filteredScenarios.isEmpty
          ? null
          : _filteredScenarios.first.id;
      _droneAdjustment = 0;
    }
  }

  void _selectScenario(Scenario scenario) {
    setState(() {
      _selectedScenarioId = scenario.id;
      _droneAdjustment = 0;
      _workflowNote = '${scenario.name} is ready for configuration review.';
    });
  }

  void _changeDroneCount(int delta) {
    setState(() {
      _droneAdjustment = (_droneAdjustment + delta).clamp(-3, 5).toInt();
      _workflowNote = 'Drone count updated for ${_selectedScenario.name}.';
    });
  }

  void _recordAction(String action) {
    setState(() => _workflowNote = action);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 980;
    final selectedScenario = _selectedScenario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroPanel(
          title: 'Scenario Planner',
          body:
              'Build a realistic wildfire patrol mission, tune drone coverage, and prepare the future handoff into live aircraft control.',
        ),
        const SizedBox(height: 16),
        ScenarioSummaryBar(
          scenariosShown: _filteredScenarios.length,
          readiness: _readiness,
          selectedScenario: selectedScenario,
        ),
        const SizedBox(height: 16),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScenarioListPanel(
                query: _query,
                region: widget.region,
                visibleScenarios: _filteredScenarios,
                selectedScenario: selectedScenario,
                onQueryChanged: (value) => setState(() => _query = value),
                onRegionChanged: widget.onRegionChanged,
                onScenarioSelected: _selectScenario,
              ),
              const SizedBox(height: 16),
              ScenarioWorkspace(
                scenario: selectedScenario,
                configuredDrones: _configuredDrones,
                onDroneCountChanged: _changeDroneCount,
              ),
              const SizedBox(height: 16),
              MissionReadinessPanel(
                scenario: selectedScenario,
                readiness: _readiness,
                workflowNote: _workflowNote,
                onLoadScenario: () => _recordAction(
                  '${selectedScenario.name} loaded into the simulator queue.',
                ),
                onPrepareMission: () => _recordAction(
                  'Mission package prepared. Drone API connection is standing by.',
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 378,
                child: ScenarioListPanel(
                  query: _query,
                  region: widget.region,
                  visibleScenarios: _filteredScenarios,
                  selectedScenario: selectedScenario,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onRegionChanged: widget.onRegionChanged,
                  onScenarioSelected: _selectScenario,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ScenarioWorkspace(
                  scenario: selectedScenario,
                  configuredDrones: _configuredDrones,
                  onDroneCountChanged: _changeDroneCount,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 344,
                child: MissionReadinessPanel(
                  scenario: selectedScenario,
                  readiness: _readiness,
                  workflowNote: _workflowNote,
                  onLoadScenario: () => _recordAction(
                    '${selectedScenario.name} loaded into the simulator queue.',
                  ),
                  onPrepareMission: () => _recordAction(
                    'Mission package prepared. Drone API connection is standing by.',
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class ScenarioSummaryBar extends StatelessWidget {
  const ScenarioSummaryBar({
    required this.scenariosShown,
    required this.readiness,
    required this.selectedScenario,
    super.key,
  });

  final int scenariosShown;
  final int readiness;
  final Scenario selectedScenario;

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      children: [
        MetricCard(
          label: 'Scenarios Visible',
          value: '$scenariosShown',
          detail: 'Filtered mission templates',
        ),
        MetricCard(
          label: 'Selected Readiness',
          value: '$readiness%',
          detail: '${selectedScenario.name} mission model',
        ),
        const MetricCard(
          label: 'Drone Link',
          value: 'Standby',
          detail: 'Simulation now, aircraft API later',
        ),
      ],
    );
  }
}

class ScenarioListPanel extends StatelessWidget {
  const ScenarioListPanel({
    required this.query,
    required this.region,
    required this.visibleScenarios,
    required this.selectedScenario,
    required this.onQueryChanged,
    required this.onRegionChanged,
    required this.onScenarioSelected,
    super.key,
  });

  final String query;
  final String region;
  final List<Scenario> visibleScenarios;
  final Scenario selectedScenario;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<Scenario> onScenarioSelected;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Scenario Library',
            subtitle: 'Choose terrain before configuring the mission.',
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search scenarios',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: regions
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 8),
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
          if (visibleScenarios.isEmpty)
            const EmptyScenarioState()
          else
            Column(
              children: visibleScenarios
                  .map(
                    (scenario) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ScenarioListItem(
                        scenario: scenario,
                        selected: selectedScenario.id == scenario.id,
                        onTap: () => onScenarioSelected(scenario),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class ScenarioListItem extends StatelessWidget {
  const ScenarioListItem({
    required this.scenario,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Scenario scenario;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffedf8f2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xff0e7656) : const Color(0xffe0e8e4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                scenario.image,
                width: 116,
                height: 82,
                fit: BoxFit.cover,
                semanticLabel: 'Generated landscape for ${scenario.name}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scenario.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xff17231f),
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xff0e7656),
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scenario.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff66756f),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatusPill(label: scenario.risk, color: scenario.color),
                      MiniFact(
                        icon: Icons.public,
                        label: '${scenario.areaSqKm} km²',
                      ),
                      MiniFact(
                        icon: Icons.terrain,
                        label: '${scenario.maxElevationMeters} m',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return SizedBox(
      height: compact ? 260 : 226,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff142f28),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/scenario-mountain.jpg',
                fit: BoxFit.cover,
                semanticLabel:
                    'Generated mountain wildfire drone patrol landscape',
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x3314231d),
                      Color(0x9914231d),
                      Color(0xdd14231d),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Scenario Library / Scenario Planner',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xffe6f3ee),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xffe6f3ee),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScenarioWorkspace extends StatelessWidget {
  const ScenarioWorkspace({
    required this.scenario,
    required this.configuredDrones,
    required this.onDroneCountChanged,
    super.key,
  });

  final Scenario scenario;
  final int configuredDrones;
  final ValueChanged<int> onDroneCountChanged;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Scenario',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xff60716b),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scenario.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Edit Plan'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            scenario.description,
            style: const TextStyle(color: Color(0xff5f6f69), height: 1.45),
          ),
          const SizedBox(height: 16),
          ScenarioMetaRow(scenario: scenario),
          const SizedBox(height: 18),
          const TabStrip(labels: ['Configuration', 'Environment', 'Terrain']),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Drone Configuration',
            subtitle: 'Tune mission inputs before loading the scenario.',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 640;
              final controls = [
                DroneCountControl(
                  count: configuredDrones,
                  onDecrement: () => onDroneCountChanged(-1),
                  onIncrement: () => onDroneCountChanged(1),
                ),
                ConfigField(
                  label: 'Endurance',
                  value: '${scenario.enduranceMinutes}',
                  unit: 'min',
                  icon: Icons.battery_charging_full,
                ),
                ConfigField(
                  label: 'Detection Radius',
                  value: '${scenario.detectionRadiusMeters}',
                  unit: 'm',
                  icon: Icons.radar,
                ),
              ];
              if (stack) {
                return Column(
                  children: controls
                      .map(
                        (control) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: control,
                        ),
                      )
                      .toList(),
                );
              }
              return Row(
                children: controls
                    .map(
                      (control) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: control,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Mission Parameters'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 640;
              final fields = [
                ConfigField(
                  label: 'Flight Altitude',
                  value: '${scenario.flightAltitudeMeters}',
                  unit: 'm AGL',
                  icon: Icons.flight_takeoff,
                ),
                ConfigField(
                  label: 'Speed',
                  value: '${scenario.speedMetersPerSecond}',
                  unit: 'm/s',
                  icon: Icons.speed,
                ),
                ConfigField(
                  label: 'Overlap',
                  value: '${scenario.overlapPercent}',
                  unit: '%',
                  icon: Icons.grid_view,
                ),
              ];
              if (stack) {
                return Column(
                  children: fields
                      .map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: field,
                        ),
                      )
                      .toList(),
                );
              }
              return Row(
                children: fields
                    .map(
                      (field) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: field,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          FireRiskRow(scenario: scenario),
          const SizedBox(height: 18),
          WeatherSummary(scenario: scenario),
          const SizedBox(height: 18),
          TerrainSummary(scenario: scenario),
        ],
      ),
    );
  }
}

class MissionReadinessPanel extends StatelessWidget {
  const MissionReadinessPanel({
    required this.scenario,
    required this.readiness,
    required this.workflowNote,
    required this.onLoadScenario,
    required this.onPrepareMission,
    super.key,
  });

  final Scenario scenario;
  final int readiness;
  final String workflowNote;
  final VoidCallback onLoadScenario;
  final VoidCallback onPrepareMission;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InfoCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Readiness & Coverage',
                subtitle:
                    'Preflight checks for simulation or future drone API.',
              ),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  width: 190,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(190, 110),
                        painter: ReadinessGaugePainter(readiness: readiness),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$readiness%',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                          ),
                          const Text(
                            'Mission Readiness',
                            style: TextStyle(color: Color(0xff60716b)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              CheckRow(label: 'Weather acceptable', ok: true),
              CheckRow(label: 'Drone readiness', ok: readiness >= 82),
              CheckRow(label: 'Battery health', ok: true),
              CheckRow(label: 'Drone API link', ok: false, warning: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InfoCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Coverage Estimate'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MetricInline(
                      label: 'Coverage',
                      value: '${scenario.coverageKm2.toStringAsFixed(1)} km²',
                    ),
                  ),
                  Expanded(
                    child: MetricInline(
                      label: 'Efficiency',
                      value: '${scenario.coverageEfficiency}%',
                    ),
                  ),
                  Expanded(
                    child: MetricInline(
                      label: 'Est. Time',
                      value: '${scenario.missionMinutes} min',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InfoCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Route Preview'),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1.28,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          scenario.image,
                          fit: BoxFit.cover,
                          semanticLabel:
                              'Generated route preview for ${scenario.name}',
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: RoutePreviewPainter(color: scenario.color),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Row(
                          children: const [
                            MapLegendDot(label: 'Start'),
                            SizedBox(width: 8),
                            MapLegendDot(label: 'Waypoint', amber: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onLoadScenario,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Load Scenario'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onPrepareMission,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Prepare Mission'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Container(
                  key: ValueKey(workflowNote),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xfff3f6f4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xffdfe8e4)),
                  ),
                  child: Text(
                    workflowNote,
                    style: const TextStyle(
                      color: Color(0xff5d6e68),
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ScenarioMetaRow extends StatelessWidget {
  const ScenarioMetaRow({required this.scenario, super.key});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final facts = [
      MiniFact(icon: Icons.place_outlined, label: scenario.location),
      MiniFact(icon: Icons.public, label: '${scenario.areaSqKm} km²'),
      MiniFact(icon: Icons.calendar_today, label: scenario.seasonWindow),
      MiniFact(icon: Icons.sensors, label: scenario.apiMode),
    ];

    return Wrap(spacing: 14, runSpacing: 8, children: facts);
  }
}

class TabStrip extends StatelessWidget {
  const TabStrip({required this.labels, super.key});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffdfe8e4))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: labels
              .map(
                (label) => Padding(
                  padding: const EdgeInsets.only(right: 26),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      border: label == labels.first
                          ? const Border(
                              bottom: BorderSide(
                                color: Color(0xff0e7656),
                                width: 2,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: label == labels.first
                            ? const Color(0xff0e7656)
                            : const Color(0xff60716b),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class DroneCountControl extends StatelessWidget {
  const DroneCountControl({
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
    super.key,
  });

  final int count;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return ConfigShell(
      label: 'Drone Count',
      child: Row(
        children: [
          IconButton(
            tooltip: 'Decrease drone count',
            onPressed: onDecrement,
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase drone count',
            onPressed: onIncrement,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class ConfigField extends StatelessWidget {
  const ConfigField({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ConfigShell(
      label: label,
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xff0e7656)),
          const SizedBox(width: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xff65736f)),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfigShell extends StatelessWidget {
  const ConfigShell({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xfffbfdfc),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdfe8e4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff60716b),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class FireRiskRow extends StatelessWidget {
  const FireRiskRow({required this.scenario, super.key});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfffff8ef),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffffdfb8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xffffe2c7),
            foregroundColor: const Color(0xffc2542d),
            child: const Icon(Icons.local_fire_department),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.risk,
                  style: const TextStyle(
                    color: Color(0xffc2542d),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${scenario.fuelModel} · ${scenario.fireBehavior}',
                  style: const TextStyle(color: Color(0xff6b5b4c)),
                ),
              ],
            ),
          ),
          SizedBox(width: 180, child: RiskMeter(score: scenario.riskScore)),
        ],
      ),
    );
  }
}

class RiskMeter extends StatelessWidget {
  const RiskMeter({required this.score, super.key});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: score / 100,
            backgroundColor: const Color(0xffffdfb8),
            color: const Color(0xffc2542d),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$score / 100',
          style: const TextStyle(
            color: Color(0xff6b5b4c),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class WeatherSummary extends StatelessWidget {
  const WeatherSummary({required this.scenario, super.key});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Weather Snapshot'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            WeatherFact(
              icon: Icons.thermostat,
              label: 'Temp',
              value: scenario.temperature,
            ),
            WeatherFact(icon: Icons.air, label: 'Wind', value: scenario.wind),
            WeatherFact(
              icon: Icons.water_drop_outlined,
              label: 'Humidity',
              value: scenario.humidity,
            ),
            WeatherFact(
              icon: Icons.visibility_outlined,
              label: 'Visibility',
              value: scenario.visibility,
            ),
          ],
        ),
      ],
    );
  }
}

class TerrainSummary extends StatelessWidget {
  const TerrainSummary({required this.scenario, super.key});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Terrain Summary'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            TerrainFact(
              icon: Icons.landscape_outlined,
              value: '${scenario.maxElevationMeters} m',
              label: 'Max Elevation',
            ),
            TerrainFact(
              icon: Icons.keyboard_double_arrow_down,
              value: '${scenario.minElevationMeters} m',
              label: 'Min Elevation',
            ),
            TerrainFact(
              icon: Icons.route,
              value: '${scenario.routeLengthKm} km',
              label: 'Route Length',
            ),
            TerrainFact(
              icon: Icons.warning_amber,
              value: scenario.avgSlope,
              label: 'Avg Slope',
            ),
          ],
        ),
      ],
    );
  }
}

class WeatherFact extends StatelessWidget {
  const WeatherFact({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff0e7656), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff17231f),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff65736f),
                    fontSize: 12,
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

class TerrainFact extends StatelessWidget {
  const TerrainFact({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff17231f), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff65736f),
                    fontSize: 12,
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

class MiniFact extends StatelessWidget {
  const MiniFact({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xff65736f)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xff65736f), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class MetricInline extends StatelessWidget {
  const MetricInline({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xff65736f), fontSize: 12),
        ),
      ],
    );
  }
}

class CheckRow extends StatelessWidget {
  const CheckRow({
    required this.label,
    required this.ok,
    this.warning = false,
    super.key,
  });

  final String label;
  final bool ok;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? const Color(0xffc9831f)
        : ok
        ? const Color(0xff0e7656)
        : const Color(0xffc2542d);
    final icon = warning
        ? Icons.warning_amber
        : ok
        ? Icons.check_circle
        : Icons.cancel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff33433e),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapLegendDot extends StatelessWidget {
  const MapLegendDot({required this.label, this.amber = false, super.key});

  final String label;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xcc10231d),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: amber ? const Color(0xffffc857) : const Color(0xff71d49b),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyScenarioState extends StatelessWidget {
  const EmptyScenarioState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfff5f8f6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdfe8e4)),
      ),
      child: const Text(
        'No scenarios match the current filters.',
        style: TextStyle(color: Color(0xff60716b)),
      ),
    );
  }
}

class ReadinessGaugePainter extends CustomPainter {
  ReadinessGaugePainter({required this.readiness});

  final int readiness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height * 1.5);
    final background = Paint()
      ..color = const Color(0xffdfe8e4)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final foreground = Paint()
      ..color = const Color(0xff0e7656)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, math.pi, math.pi, false, background);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * (readiness.clamp(0, 100) / 100),
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant ReadinessGaugePainter oldDelegate) {
    return readiness != oldDelegate.readiness;
  }
}

class RoutePreviewPainter extends CustomPainter {
  RoutePreviewPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Paint()..color = const Color(0x66000000);
    canvas.drawRect(Offset.zero & size, shade);

    final points = [
      Offset(size.width * 0.28, size.height * 0.24),
      Offset(size.width * 0.67, size.height * 0.27),
      Offset(size.width * 0.83, size.height * 0.60),
      Offset(size.width * 0.42, size.height * 0.78),
      Offset(size.width * 0.28, size.height * 0.24),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xffffc857)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var index = 0; index < points.length - 1; index++) {
      final point = points[index];
      final isStart = index == 0;
      canvas.drawCircle(
        point,
        isStart ? 13 : 11,
        Paint()..color = isStart ? color : const Color(0xfffff5cf),
      );
      final paragraph = TextPainter(
        text: TextSpan(
          text: isStart ? 'S' : '${index + 1}',
          style: TextStyle(
            color: isStart ? Colors.white : const Color(0xff17231f),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      paragraph.paint(
        canvas,
        point - Offset(paragraph.width / 2, paragraph.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RoutePreviewPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class LiveSimulator extends StatelessWidget {
  const LiveSimulator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'Live Simulator'),
        SizedBox(height: 14),
        SimulatorBoard(),
        SizedBox(height: 16),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Run #2417',
              value: 'Active',
              detail: 'Foothill ridge sweep',
            ),
            MetricCard(
              label: 'Coverage',
              value: '83%',
              detail: 'Projected in 18 minutes',
            ),
            MetricCard(
              label: 'Wind Shift',
              value: '12 mph',
              detail: 'Northwest at 14:20',
            ),
          ],
        ),
      ],
    );
  }
}

class SimulatorBoard extends StatelessWidget {
  const SimulatorBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: MissionMapPainter())),
            Positioned(
              left: 16,
              top: 16,
              child: StatusPill(
                label: 'Thermal front tracking',
                color: Color(0xffc2542d),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FilledButton.icon(
                onPressed: null,
                icon: Icon(Icons.play_arrow),
                label: Text('Start run'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FleetPage extends StatelessWidget {
  const FleetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'Drone Fleet'),
        SizedBox(height: 14),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Scout Alpha',
              value: 'Ready',
              detail: 'Thermal + visual',
            ),
            MetricCard(
              label: 'Relay Beta',
              value: 'Charging',
              detail: '74% battery',
            ),
            MetricCard(
              label: 'Mapper Delta',
              value: 'Ready',
              detail: 'LiDAR sweep',
            ),
          ],
        ),
      ],
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'Analytics'),
        SizedBox(height: 14),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Detection Latency',
              value: '2.6 min',
              detail: 'Down 31% vs manual patrol',
            ),
            MetricCard(
              label: 'Thermal Confidence',
              value: '91%',
              detail: 'Model ensemble average',
            ),
            MetricCard(
              label: 'Safe Return',
              value: '97%',
              detail: 'Battery-aware routing',
            ),
          ],
        ),
      ],
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1180
        ? 3
        : width >= 760
        ? 2
        : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = columns == 1 ? 12.0 : 16.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdfe8e4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    super.key,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xff60716b))),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(detail, style: const TextStyle(color: Color(0xff65736f))),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xff65736f),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null)
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: trailing,
            ),
          ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = color.computeLuminance() > 0.55
        ? const Color(0xff17231f)
        : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TerrainPainter extends CustomPainter {
  TerrainPainter({required this.seed, required this.night});

  final int seed;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: night
            ? const [Color(0xff12352d), Color(0xff0c1715)]
            : const [Color(0xffdbeee8), Color(0xffffe0b5)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final random = math.Random(seed);
    for (var layer = 0; layer < 4; layer++) {
      final path = Path()..moveTo(0, size.height);
      final base = size.height * (0.45 + layer * 0.13);
      for (var x = 0.0; x <= size.width + 30; x += 34) {
        final wave =
            math.sin((x / size.width * math.pi * 2) + layer + seed) * 18;
        final jitter = (random.nextDouble() - 0.5) * 20;
        path.lineTo(x, base + wave + jitter);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      final color = night
          ? [
              const Color(0xff1f5748),
              const Color(0xff173c34),
              const Color(0xff102a25),
              const Color(0xff0b1b18),
            ][layer]
          : [
              const Color(0xff8ec7a4),
              const Color(0xff6aa37f),
              const Color(0xff4b795f),
              const Color(0xff315241),
            ][layer];
      canvas.drawPath(path, Paint()..color = color);
    }

    final fire = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0xffffd166), Color(0xffff7d3b), Color(0x00ff7d3b)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.72, size.height * 0.58),
              radius: size.shortestSide * 0.33,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.58),
      size.shortestSide * 0.34,
      fire,
    );

    final dronePaint = Paint()
      ..color = night ? Colors.white : const Color(0xff10231d)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final center = Offset(
        size.width * (0.22 + i * 0.22),
        size.height * (0.24 + i * 0.06),
      );
      canvas.drawCircle(center, 9, dronePaint);
      canvas.drawLine(
        center.translate(-18, 0),
        center.translate(18, 0),
        dronePaint,
      );
      canvas.drawLine(
        center.translate(0, -18),
        center.translate(0, 18),
        dronePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TerrainPainter oldDelegate) {
    return seed != oldDelegate.seed || night != oldDelegate.night;
  }
}

class MissionMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xffe7f1ed), Color(0xffffffff)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      background,
    );

    final grid = Paint()
      ..color = const Color(0xffd9e6e1)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final route = Path()
      ..moveTo(size.width * 0.12, size.height * 0.72)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.28,
        size.width * 0.54,
        size.height * 0.82,
        size.width * 0.72,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.16,
        size.width * 0.92,
        size.height * 0.42,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xff0e7656)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final hazard = Paint()..color = const Color(0x44f05d2f);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.54),
        width: size.width * 0.28,
        height: size.height * 0.42,
      ),
      hazard,
    );

    final pointPaint = Paint()..color = const Color(0xff10231d);
    for (final point in [
      Offset(size.width * 0.12, size.height * 0.72),
      Offset(size.width * 0.34, size.height * 0.38),
      Offset(size.width * 0.72, size.height * 0.36),
      Offset(size.width * 0.92, size.height * 0.42),
    ]) {
      canvas.drawCircle(point, 7, pointPaint);
      canvas.drawCircle(point, 14, Paint()..color = const Color(0x2210231d));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Scenario {
  const Scenario({
    required this.id,
    required this.name,
    required this.region,
    required this.location,
    required this.description,
    required this.drones,
    required this.risk,
    required this.riskScore,
    required this.color,
    required this.seed,
    required this.image,
    required this.areaSqKm,
    required this.maxElevationMeters,
    required this.minElevationMeters,
    required this.routeLengthKm,
    required this.enduranceMinutes,
    required this.detectionRadiusMeters,
    required this.flightAltitudeMeters,
    required this.speedMetersPerSecond,
    required this.overlapPercent,
    required this.readiness,
    required this.coverageKm2,
    required this.coverageEfficiency,
    required this.missionMinutes,
    required this.seasonWindow,
    required this.apiMode,
    required this.fuelModel,
    required this.fireBehavior,
    required this.temperature,
    required this.wind,
    required this.humidity,
    required this.visibility,
    required this.avgSlope,
  });

  final String id;
  final String name;
  final String region;
  final String location;
  final String description;
  final int drones;
  final String risk;
  final int riskScore;
  final Color color;
  final int seed;
  final String image;
  final int areaSqKm;
  final int maxElevationMeters;
  final int minElevationMeters;
  final int routeLengthKm;
  final int enduranceMinutes;
  final int detectionRadiusMeters;
  final int flightAltitudeMeters;
  final int speedMetersPerSecond;
  final int overlapPercent;
  final int readiness;
  final double coverageKm2;
  final int coverageEfficiency;
  final int missionMinutes;
  final String seasonWindow;
  final String apiMode;
  final String fuelModel;
  final String fireBehavior;
  final String temperature;
  final String wind;
  final String humidity;
  final String visibility;
  final String avgSlope;
}

class NavItem {
  const NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

const regions = ['All', 'Mountain', 'Coastal', 'Boreal', 'Plateau'];

const scenarios = [
  Scenario(
    id: 'min-mountains',
    name: 'Min Mountains · California',
    region: 'Mountain',
    location: 'Sierra foothills, CA',
    description:
        'Steep ridgeline scan with smoke-obscured valleys and narrow return corridors.',
    drones: 6,
    risk: 'High heat',
    riskScore: 86,
    color: Color(0xff315241),
    seed: 4,
    image: 'assets/images/scenario-mountain.jpg',
    areaSqKm: 42,
    maxElevationMeters: 1680,
    minElevationMeters: 620,
    routeLengthKm: 31,
    enduranceMinutes: 45,
    detectionRadiusMeters: 800,
    flightAltitudeMeters: 120,
    speedMetersPerSecond: 12,
    overlapPercent: 30,
    readiness: 82,
    coverageKm2: 38.5,
    coverageEfficiency: 86,
    missionMinutes: 38,
    seasonWindow: 'May to October',
    apiMode: 'Simulation API',
    fuelModel: 'Fuel load: heavy',
    fireBehavior: 'Active upslope spread',
    temperature: '22°C',
    wind: 'NW 12 km/h',
    humidity: '32%',
    visibility: '16 km',
    avgSlope: 'Steep',
  ),
  Scenario(
    id: 'santa-cruz',
    name: 'Santa Cruz Fog Belt',
    region: 'Coastal',
    location: 'Santa Cruz coast, CA',
    description:
        'Low ceiling patrol that balances thermal locks against shifting marine fog.',
    drones: 5,
    risk: 'Visibility',
    riskScore: 72,
    color: Color(0xff2f7d9a),
    seed: 8,
    image: 'assets/images/scenario-coastal.jpg',
    areaSqKm: 58,
    maxElevationMeters: 920,
    minElevationMeters: 80,
    routeLengthKm: 27,
    enduranceMinutes: 42,
    detectionRadiusMeters: 650,
    flightAltitudeMeters: 95,
    speedMetersPerSecond: 10,
    overlapPercent: 38,
    readiness: 80,
    coverageKm2: 34.8,
    coverageEfficiency: 81,
    missionMinutes: 41,
    seasonWindow: 'June to September',
    apiMode: 'Weather-gated API',
    fuelModel: 'Chaparral edge',
    fireBehavior: 'Fog-limited thermal read',
    temperature: '18°C',
    wind: 'W 18 km/h',
    humidity: '61%',
    visibility: '7 km',
    avgSlope: 'Mixed',
  ),
  Scenario(
    id: 'yukon-boreal',
    name: 'Yukon Boreal Line',
    region: 'Boreal',
    location: 'Yukon fire line, CA model',
    description:
        'Long-range perimeter sweep through dense conifer canopy and cold uplifts.',
    drones: 8,
    risk: 'Canopy',
    riskScore: 78,
    color: Color(0xff0e7656),
    seed: 12,
    image: 'assets/images/scenario-boreal.jpg',
    areaSqKm: 96,
    maxElevationMeters: 1450,
    minElevationMeters: 510,
    routeLengthKm: 44,
    enduranceMinutes: 58,
    detectionRadiusMeters: 720,
    flightAltitudeMeters: 135,
    speedMetersPerSecond: 13,
    overlapPercent: 35,
    readiness: 84,
    coverageKm2: 71.2,
    coverageEfficiency: 88,
    missionMinutes: 55,
    seasonWindow: 'July to October',
    apiMode: 'Relay mesh API',
    fuelModel: 'Conifer canopy',
    fireBehavior: 'Spotting under canopy',
    temperature: '15°C',
    wind: 'N 9 km/h',
    humidity: '44%',
    visibility: '12 km',
    avgSlope: 'Rolling',
  ),
  Scenario(
    id: 'colorado-plateau',
    name: 'Colorado Plateau Watch',
    region: 'Plateau',
    location: 'Mesa canyon grid, CO',
    description:
        'Mesa-to-canyon mapping with relay handoffs and strong afternoon winds.',
    drones: 7,
    risk: 'Wind',
    riskScore: 81,
    color: Color(0xffc2542d),
    seed: 16,
    image: 'assets/images/scenario-plateau.jpg',
    areaSqKm: 75,
    maxElevationMeters: 1880,
    minElevationMeters: 930,
    routeLengthKm: 39,
    enduranceMinutes: 50,
    detectionRadiusMeters: 760,
    flightAltitudeMeters: 140,
    speedMetersPerSecond: 11,
    overlapPercent: 32,
    readiness: 79,
    coverageKm2: 52.4,
    coverageEfficiency: 83,
    missionMinutes: 46,
    seasonWindow: 'April to September',
    apiMode: 'Relay standby',
    fuelModel: 'Dry brush corridor',
    fireBehavior: 'Wind-driven canyon push',
    temperature: '27°C',
    wind: 'SW 24 km/h',
    humidity: '25%',
    visibility: '19 km',
    avgSlope: 'Canyon',
  ),
];
