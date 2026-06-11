import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

class _Drone {
  const _Drone(this.name, this.status, this.detail, this.statusColor);

  final String name;
  final String status;
  final String detail;
  final Color statusColor;
}

const _fleet = [
  _Drone('Scout Alpha', 'Ready', 'Thermal + visual', AppColors.fwiLow),
  _Drone('Relay Beta', 'Charging', '74% battery', AppColors.fwiMed),
  _Drone('Mapper Delta', 'Ready', 'LiDAR sweep', AppColors.fwiLow),
  _Drone('Scout Gamma', 'Airborne', 'Sector 3-North', AppColors.chartBlue),
  _Drone('Relay Echo', 'Standby', 'Hangar bay 2', AppColors.textSecondary),
  _Drone('Mapper Zeta', 'Maintenance', 'Rotor inspection', AppColors.fwiHigh),
];

class DroneFleetScreen extends StatelessWidget {
  const DroneFleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'Drone Fleet'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Active Roster',
                  subtitle: '6 airframes synced with mission planner',
                ),
                const SizedBox(height: 16),
                ResponsiveGrid(
                  children: [
                    for (final drone in _fleet) _DroneCard(drone: drone),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DroneCard extends StatelessWidget {
  const _DroneCard({required this.drone});

  final _Drone drone;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flight,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  drone.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusPill(label: drone.status, color: drone.statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            drone.detail,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
