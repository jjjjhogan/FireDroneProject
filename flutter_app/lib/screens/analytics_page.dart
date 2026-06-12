import 'package:flutter/material.dart';

import '../services/drone_api_client.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_pill.dart';
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.droneClient.fetchAnalytics(),
      builder: (context, snapshot) {
        final analytics = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Analytics',
              subtitle:
                  'Mission telemetry, patrol efficiency, and chart-ready series for the DJI wildfire workflow.',
              trailing: StatusPill(
                label: analytics == null
                    ? 'Loading feed'
                    : '${analytics.dataSource.toUpperCase()} · ${analytics.lastUpdated}',
                color: analytics?.dataSource == 'api'
                    ? const Color(0xffb7f1d8)
                    : const Color(0xffffd9a8),
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.dashboard_outlined),
                  label: Text('Overview'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.show_chart_outlined),
                  label: Text('Graphs'),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (selection) {
                setState(() => _selectedTab = selection.first);
              },
            ),
            const SizedBox(height: 18),
            if (loading && analytics == null)
              const Center(child: CircularProgressIndicator())
            else if (analytics != null)
              _selectedTab == 0
                  ? AnalyticsOverviewTab(analytics: analytics)
                  : AnalyticsGraphsPage(analytics: analytics),
          ],
        );
      },
    );
  }
}
