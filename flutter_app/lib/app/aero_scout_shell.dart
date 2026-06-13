import 'package:flutter/material.dart';

import '../data/mock_scenarios.dart';
import '../models/nav_item.dart';
import '../models/scenario.dart';
import '../screens/analytics_page.dart';
import '../screens/about_docs_screen.dart';
import '../screens/fleet_page.dart';
import '../screens/live_simulator_screen.dart';
import '../screens/scenario_library_screen.dart';
import '../services/drone_api_client.dart';
import '../services/operations_api_client.dart';
import '../services/scenario_library_service.dart';
import '../widgets/layout/sidebar.dart';
import '../widgets/layout/top_bar.dart';

class AeroScoutShell extends StatefulWidget {
  const AeroScoutShell({required this.droneClient, super.key});

  final DroneApiClient droneClient;

  @override
  State<AeroScoutShell> createState() => _AeroScoutShellState();
}

class _AeroScoutShellState extends State<AeroScoutShell> {
  int _page = 1;
  Scenario _activeScenario = scenarios.first;
  final ScenarioLibraryService _scenarioService =
      const MockScenarioLibraryService();
  final OperationsApiClient _operationsClient = ResilientOperationsApiClient();

  static const _nav = [
    NavItem(Icons.dashboard_outlined, 'Scenario Library'),
    NavItem(Icons.radar_outlined, 'Live Simulator'),
    NavItem(Icons.flight_takeoff_outlined, 'Drone Fleet'),
    NavItem(Icons.monitor_heart_outlined, 'Analytics'),
    NavItem(Icons.policy_outlined, 'About & Safety'),
  ];

  void _openScenarioInSimulator(Scenario scenario) {
    setState(() {
      _activeScenario = scenario;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final page = switch (_page) {
      0 => ScenarioLibraryScreen(
        scenarioService: _scenarioService,
        onOpenSimulator: _openScenarioInSimulator,
        droneClient: widget.droneClient,
      ),
      1 => LiveSimulatorScreen(
        scenario: _activeScenario,
        droneClient: widget.droneClient,
        operationsClient: _operationsClient,
        onScenarioChanged: (scenario) {
          setState(() => _activeScenario = scenario);
        },
      ),
      2 => FleetPage(droneClient: widget.droneClient),
      3 => AnalyticsPage(droneClient: widget.droneClient),
      _ => AboutDocsScreen(operationsClient: _operationsClient),
    };

    return Scaffold(
      backgroundColor: const Color(0xffeef4f1),
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
                  if (compact || _page != 1)
                    TopBar(
                      compact: compact,
                      title: _nav[_page].label,
                      onMenuTap: () {},
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 12,
                        compact ? 18 : 12,
                        compact ? 16 : 12,
                        compact ? 96 : 12,
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
