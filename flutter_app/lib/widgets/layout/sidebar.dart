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
      width: 252,
      color: const Color(0xff10231d),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department, color: Color(0xffffc857)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AeroScout Sim',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff1b382f),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Mission planner synced with 12 drone profiles and 4 fire behavior models.',
                  style: TextStyle(color: Color(0xffc9ddd5), height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
