import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'drone_fleet_screen.dart';
import 'live_simulator_screen.dart';
import 'scenario_library_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const LiveSimulatorScreen();
      case 2:
        return const ScenarioLibraryScreen();
      case 3:
        return const DroneFleetScreen();
      case 4:
        return const AnalyticsScreen();
      default:
        return _ComingSoonScreen(title: _titleForIndex(_selectedIndex));
    }
  }

  String _titleForIndex(int index) {
    var i = 0;
    for (final section in sidebarSections) {
      for (final item in section.items) {
        if (i == index) return item.label;
        i++;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: _selectedIndex,
            onSelect: (index) => setState(() => _selectedIndex = index),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          width: double.infinity,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_outlined,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  '$title is coming soon',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
