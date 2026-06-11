import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NavSectionData {
  const NavSectionData({required this.label, required this.items});

  final String label;
  final List<NavItemData> items;
}

class NavItemData {
  const NavItemData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const sidebarSections = [
  NavSectionData(
    label: 'WORKSPACE',
    items: [
      NavItemData(icon: Icons.dashboard_outlined, label: 'Dashboard'),
      NavItemData(icon: Icons.play_circle_outline, label: 'Live Simulator'),
      NavItemData(icon: Icons.map_outlined, label: 'Scenarios'),
      NavItemData(icon: Icons.flight_outlined, label: 'Drone Fleet'),
    ],
  ),
  NavSectionData(
    label: 'INSIGHTS',
    items: [
      NavItemData(icon: Icons.bar_chart_outlined, label: 'Analytics'),
      NavItemData(icon: Icons.route_outlined, label: 'Fleet Planning'),
    ],
  ),
];

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    var runningIndex = 0;

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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final section in sidebarSections) ...[
                  _NavSection(
                    label: section.label,
                    children: [
                      for (final item in section.items)
                        Builder(
                          builder: (context) {
                            final index = runningIndex++;
                            return _NavItemTile(
                              item: item,
                              isActive: index == selectedIndex,
                              onTap: () => onSelect(index),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
          const _ResearchModeBadge(),
          const SizedBox(height: 16),
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
  const _NavSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

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
        ...children,
      ],
    );
  }
}

class _NavItemTile extends StatelessWidget {
  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 2),
      child: Material(
        color: isActive ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color:
                      isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
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
      ),
    );
  }
}

class _ResearchModeBadge extends StatelessWidget {
  const _ResearchModeBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.science_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Research Mode',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Runs are CPU-simulated. No physical drones required.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
