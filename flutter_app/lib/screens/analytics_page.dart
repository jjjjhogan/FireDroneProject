import 'package:flutter/material.dart';

import '../models/drone_connection.dart';
import '../services/drone_api_client.dart';
import '../widgets/common/metric_card.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/common/section_header.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({required this.droneClient, super.key});

  final DroneApiClient droneClient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Analytics',
          subtitle:
              'Mission-level telemetry for the DJI-ready wildfire workflow.',
        ),
        const SizedBox(height: 14),
        FutureBuilder<TelemetrySnapshot>(
          future: droneClient.fetchTelemetry(),
          builder: (context, snapshot) {
            final telemetry = snapshot.data;
            return ResponsiveGrid(
              children: [
                MetricCard(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Link Health',
                  value: telemetry?.linkHealth ?? 'loading',
                  detail: 'Active DJI telemetry channel status',
                ),
                MetricCard(
                  icon: Icons.route,
                  label: 'Mission State',
                  value: telemetry?.missionState ?? 'standby',
                  detail:
                      '${telemetry?.routeProgressPct ?? 0}% route progress in preview',
                ),
                MetricCard(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Fire Perimeter Risk',
                  value: telemetry?.firePerimeterRisk ?? 'unknown',
                  detail:
                      '${telemetry?.windMph.round() ?? 0} mph wind · ${telemetry?.temperatureF.round() ?? 0} F',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
