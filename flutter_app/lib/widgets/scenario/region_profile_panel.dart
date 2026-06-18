import 'package:flutter/material.dart';

import '../../models/region_profile.dart';
import '../common/info_card.dart';

class RegionProfilePanel extends StatelessWidget {
  const RegionProfilePanel({required this.profile, super.key});

  final RegionProfile profile;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      color: profile.accent.withValues(alpha: 0.08),
      borderColor: profile.accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(profile.icon, color: profile.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${profile.label} Region Profile',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile.summary,
            style: const TextStyle(color: Color(0xff53615d), height: 1.35),
          ),
          const SizedBox(height: 12),
          _TraitGroup(title: 'Terrain traits', items: profile.terrainTraits),
          const SizedBox(height: 10),
          _TraitGroup(title: 'Flight challenges', items: profile.flightChallenges),
        ],
      ),
    );
  }
}

class _TraitGroup extends StatelessWidget {
  const _TraitGroup({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xff60716b),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => Chip(
                  label: Text(item),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
