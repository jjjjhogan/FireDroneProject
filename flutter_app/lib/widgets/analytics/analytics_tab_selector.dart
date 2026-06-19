import 'package:flutter/material.dart';

import '../common/info_card.dart';

class AnalyticsTabSelector extends StatelessWidget {
  const AnalyticsTabSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(8),
      color: const Color(0xfff8fbfa),
      child: Row(
        children: [
          _TabButton(
            selected: selected == 0,
            icon: Icons.dashboard_outlined,
            label: 'Overview',
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 8),
          _TabButton(
            selected: selected == 1,
            icon: Icons.show_chart_outlined,
            label: 'Graphs',
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? const Color(0xff0e7656) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : const Color(0xff60716b),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : const Color(0xff24322f),
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
