import 'package:flutter/material.dart';

import '../models/analytics_snapshot.dart';
import '../services/drone_api_client.dart';
import '../widgets/analytics/analytics_hero.dart';
import '../widgets/analytics/analytics_tab_selector.dart';
import 'analytics_graphs_page.dart';
import 'analytics_overview_tab.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({required this.droneClient, super.key});

  final DroneApiClient droneClient;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _selectedTab = 0;
  late Future<AnalyticsSnapshot> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = widget.droneClient.fetchAnalytics();
  }

  void _refreshAnalytics() {
    setState(() {
      _analyticsFuture = widget.droneClient.fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnalyticsSnapshot>(
      future: _analyticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _AnalyticsErrorState(
            message: snapshot.error.toString(),
            onRetry: _refreshAnalytics,
          );
        }

        final analytics = snapshot.data;
        if (analytics == null) {
          return _AnalyticsErrorState(
            message: 'Analytics feed unavailable.',
            onRetry: _refreshAnalytics,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalyticsHero(
              analytics: analytics,
              onRefresh: _refreshAnalytics,
              refreshing: snapshot.connectionState == ConnectionState.waiting,
            ),
            const SizedBox(height: 14),
            AnalyticsTabSelector(
              selected: _selectedTab,
              onChanged: (index) => setState(() => _selectedTab = index),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _selectedTab == 0
                  ? AnalyticsOverviewTab(
                      key: const ValueKey('overview'),
                      analytics: analytics,
                    )
                  : AnalyticsGraphsPage(
                      key: const ValueKey('graphs'),
                      analytics: analytics,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AnalyticsErrorState extends StatelessWidget {
  const _AnalyticsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: Color(0xff94a3b8)),
            const SizedBox(height: 12),
            const Text(
              'Analytics unavailable',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff62716c), height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
