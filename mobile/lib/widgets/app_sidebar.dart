import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const _BrandHeader(),
          const SizedBox(height: 32),
          const _NavSection(
            label: 'WORKSPACE',
            items: [
              _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
              _NavItem(icon: Icons.play_circle_outline, label: 'Live Simulator'),
              _NavItem(
                icon: Icons.map_outlined,
                label: 'Scenarios',
                isActive: true,
              ),
              _NavItem(icon: Icons.flight_outlined, label: 'Drone Fleet'),
            ],
          ),
          const SizedBox(height: 24),
          const _NavSection(
            label: 'INSIGHTS',
            items: [
              _NavItem(icon: Icons.bar_chart_outlined, label: 'Analytics'),
              _NavItem(icon: Icons.route_outlined, label: 'Fleet Planning'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
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
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AeroScout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Fire Patrol Simulator',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  const _NavSection({required this.label, required this.items});

  final String label;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _NavItemTile(item: item)),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({
    this.icon,
    required this.label,
    this.isActive = false,
  });

  final IconData? icon;
  final String label;
  final bool isActive;
}

class _NavItemTile extends StatelessWidget {
  const _NavItemTile({required this.item});

  final _NavItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 2,
      ),
      child: Material(
        color: item.isActive ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 18,
                  color: item.isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        item.isActive ? FontWeight.w600 : FontWeight.w400,
                    color: item.isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
