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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff183229),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xff2b5849)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DJI Link',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Cloud API and Mobile SDK bridge are reserved. Commands stay locked until manual confirmation.',
                      style: TextStyle(color: Color(0xffc9ddd5), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
