import 'package:flutter/material.dart';

import '../data/mock_scenarios.dart';
import '../models/nav_item.dart';
import '../models/scenario.dart';
import '../screens/analytics_page.dart';
import '../screens/about_docs_screen.dart';
import '../screens/fleet_page.dart';
import '../screens/live_simulator_screen.dart';
import '../screens/scenario_library_screen.dart';
import '../services/account_api_client.dart';
import '../services/browser_redirect.dart';
import '../services/drone_api_client.dart';
import '../services/operations_api_client.dart';
import '../services/scenario_library_service.dart';
import '../widgets/account/account_dialogs.dart';
import '../widgets/layout/sidebar.dart';
import '../widgets/layout/top_bar.dart';

class AeroScoutShell extends StatefulWidget {
  const AeroScoutShell({
    required this.accountClient,
    required this.droneClient,
    required this.operationsClient,
    super.key,
  });

  final AccountApiClient accountClient;
  final DroneApiClient droneClient;
  final OperationsApiClient operationsClient;

  @override
  State<AeroScoutShell> createState() => _AeroScoutShellState();
}

class _AeroScoutShellState extends State<AeroScoutShell> {
  int _page = 1;
  Scenario _activeScenario = scenarios.first;
  AccountSession? _accountSession;
  final ScenarioLibraryService _scenarioService =
      const MockScenarioLibraryService();

  static const _nav = [
    NavItem(Icons.dashboard_outlined, 'Scenario Library'),
    NavItem(Icons.radar_outlined, 'Live Simulator'),
    NavItem(Icons.flight_takeoff_outlined, 'Drone Fleet'),
    NavItem(Icons.monitor_heart_outlined, 'Analytics'),
    NavItem(Icons.policy_outlined, 'About & Safety'),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrapAccountSession();
  }

  Future<void> _bootstrapAccountSession() async {
    final loginCode = pendingAccountLoginCode();
    if (loginCode != null && loginCode.isNotEmpty) {
      try {
        final session = await widget.accountClient.completeLoginCode(loginCode);
        if (!mounted) return;
        _setAccountSession(session);
      } finally {
        clearAccountLoginQuery();
      }
      return;
    }

    final storedToken = storedAccountToken();
    if (storedToken == null || storedToken.isEmpty) {
      final error = pendingAccountError();
      if (error != null && error.isNotEmpty) {
        clearAccountLoginQuery();
      }
      return;
    }
    try {
      final session = await widget.accountClient.currentAccount(storedToken);
      if (!mounted) return;
      _setAccountSession(session);
    } catch (_) {
      clearStoredAccountToken();
    }
  }

  void _setAccountSession(AccountSession session) {
    saveAccountToken(session.token);
    setState(() => _accountSession = session);
  }

  void _clearAccountSession() {
    clearStoredAccountToken();
    setState(() => _accountSession = null);
  }

  Future<void> _signOut() async {
    final session = _accountSession;
    if (session != null) {
      try {
        await widget.accountClient.logout(session.token);
      } catch (_) {}
    }
    if (!mounted) return;
    _clearAccountSession();
    if (pendingAccountError() != null) {
      clearAccountLoginQuery();
    }
  }

  void _openScenarioInSimulator(Scenario scenario) {
    setState(() {
      _activeScenario = scenario;
      _page = 1;
    });
  }

  Future<void> _openAccountAuth() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AccountAuthDialog(
        accountClient: widget.accountClient,
        onSignedIn: (session) {
          _setAccountSession(session);
        },
      ),
    );
  }

  Future<void> _openAccountData() async {
    final session = _accountSession;
    if (session == null) {
      await _openAccountAuth();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AccountDataDialog(
        session: session,
        accountClient: widget.accountClient,
        onSaved: (data) {
          setState(() {
            _accountSession = AccountSession(
              token: session.token,
              tokenType: session.tokenType,
              account: session.account.copyWith(data: data),
            );
          });
        },
        onSignOut: _signOut,
      ),
    );
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
        operationsClient: widget.operationsClient,
        onScenarioChanged: (scenario) {
          setState(() => _activeScenario = scenario);
        },
      ),
      2 => FleetPage(droneClient: widget.droneClient),
      3 => AnalyticsPage(droneClient: widget.droneClient),
      _ => AboutDocsScreen(operationsClient: widget.operationsClient),
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
              accountSession: _accountSession,
              onSignIn: _openAccountAuth,
              onAccountData: _openAccountData,
              onSignOut: _signOut,
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
                      accountSession: _accountSession,
                      onSignIn: _openAccountAuth,
                      onAccountData: _openAccountData,
                      onSignOut: _signOut,
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
