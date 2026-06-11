import 'package:flutter/material.dart';

import '../models/drone_connection.dart';
import '../services/drone_api_client.dart';
import '../widgets/common/info_card.dart';
import '../widgets/common/metric_card.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_pill.dart';

class FleetPage extends StatelessWidget {
  const FleetPage({required this.droneClient, super.key});

  final DroneApiClient droneClient;

  @override
  Widget build(BuildContext context) {
    final fleetFuture = droneClient.fetchFleet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Drone Fleet',
          subtitle:
              'DJI aircraft inventory, link health, battery, altitude, and safety warnings.',
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<DroneSummary>>(
          future: fleetFuture,
          builder: (context, snapshot) {
            final drones = snapshot.data ?? const <DroneSummary>[];
            final online = drones.where(
              (drone) => drone.connection == 'online',
            );
            final averageBattery = drones.isEmpty
                ? 0
                : (drones
                              .map((drone) => drone.batteryPct)
                              .reduce((a, b) => a + b) /
                          drones.length)
                      .round();
            return ResponsiveGrid(
              children: [
                MetricCard(
                  icon: Icons.flight_takeoff,
                  label: 'Connected Drones',
                  value: '${online.length}/${drones.length}',
                  detail: 'DJI aircraft reporting into mission control',
                ),
                MetricCard(
                  icon: Icons.battery_charging_full,
                  label: 'Average Battery',
                  value: drones.isEmpty ? '--' : '$averageBattery%',
                  detail: 'Dispatch target keeps reserve aircraft above 60%',
                ),
                const MetricCard(
                  icon: Icons.lock_outline,
                  label: 'Command Safety',
                  value: 'Locked',
                  detail: 'Manual confirmation protects real DJI aircraft',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<DroneSummary>>(
          future: fleetFuture,
          builder: (context, snapshot) {
            final drones = snapshot.data ?? const <DroneSummary>[];
            return Column(
              children: drones
                  .map(
                    (drone) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DroneFleetRow(drone: drone),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class DroneFleetRow extends StatelessWidget {
  const DroneFleetRow({required this.drone, super.key});

  final DroneSummary drone;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (drone.connection) {
      'online' => const Color(0xff12805c),
      'standby' => const Color(0xffffc857),
      _ => const Color(0xff8c9b96),
    };

    return InfoCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xffedf8f2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.flight, color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drone.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${drone.model} · ${drone.altitudeM} m · '
                  '${drone.lat.toStringAsFixed(4)}, '
                  '${drone.lng.toStringAsFixed(4)}',
                  style: const TextStyle(color: Color(0xff62716c)),
                ),
              ],
            ),
          ),
          StatusPill(label: drone.connection, color: statusColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${drone.batteryPct}% battery',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${drone.signalPct}% signal',
                  style: const TextStyle(color: Color(0xff62716c)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
