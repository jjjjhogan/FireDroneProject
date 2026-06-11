import 'package:flutter/material.dart';

import '../common/status_pill.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    required this.compact,
    required this.title,
    required this.onMenuTap,
    super.key,
  });

  final bool compact;
  final String title;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 16, compact ? 16 : 28, 0),
      child: Row(
        children: [
          if (compact)
            IconButton(
              tooltip: 'Menu',
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AeroScout Command',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'DJI-ready wildfire mission control',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xff62716c),
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const StatusPill(label: 'DJI Link', color: Color(0xff12805c)),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ],
      ),
    );
  }
}
