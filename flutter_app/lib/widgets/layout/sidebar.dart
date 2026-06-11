import 'package:flutter/material.dart';

import '../../models/nav_item.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    required this.items,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 284,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff071512), Color(0xff10231d), Color(0xff0f1d1a)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.radar, color: Color(0xffffc857)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AeroScout Command',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              for (var index = 0; index < items.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: selected == index
                          ? const Color(0xff10231d)
                          : const Color(0xffd8e7e1),
                      backgroundColor: selected == index
                          ? const Color(0xffb7f1d8)
                          : Colors.transparent,
                      minimumSize: const Size.fromHeight(46),
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => onSelect(index),
                    icon: Icon(items[index].icon),
                    label: Text(items[index].label),
                  ),
                ),
              const Spacer(),
              const MissionOverviewCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class MissionOverviewCard extends StatelessWidget {
  const MissionOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff101b1f),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff20333a)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MISSION OVERVIEW',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 20),
          SidebarLabelValue(
            label: 'Current Scenario',
            value: 'Canyon Ridge Fire',
          ),
          SizedBox(height: 16),
          SidebarLabelValue(
            label: 'Location',
            value: 'Los Padres National Forest, CA',
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SidebarLabelValue(label: 'Started', value: '09:42 AM'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SidebarLabelValue(label: 'Elapsed', value: '00:18:42'),
              ),
            ],
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: Color(0xffffc857), size: 26),
              SizedBox(width: 8),
              Text(
                '24°C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Text(
                  'WNW 6 m/s',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SidebarLabelValue(label: 'Visibility', value: '16 km'),
          SizedBox(height: 18),
          Text(
            'Fire Behavior Index',
            style: TextStyle(color: Color(0xff8ea09a), fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            'High',
            style: TextStyle(
              color: Color(0xffff9f1c),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: BehaviorSegment(active: true)),
              SizedBox(width: 4),
              Expanded(child: BehaviorSegment(active: true)),
              SizedBox(width: 4),
              Expanded(child: BehaviorSegment(active: true)),
              SizedBox(width: 4),
              Expanded(child: BehaviorSegment(active: true)),
              SizedBox(width: 4),
              Expanded(child: BehaviorSegment(active: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class SidebarLabelValue extends StatelessWidget {
  const SidebarLabelValue({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xff8ea09a), fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class BehaviorSegment extends StatelessWidget {
  const BehaviorSegment({required this.active, super.key});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: active ? const Color(0xffff8a00) : const Color(0xff29383b),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
