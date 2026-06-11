import 'package:flutter/material.dart';

import '../common/status_pill.dart';

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    required this.title,
    required this.body,
    required this.linkLabel,
    required this.readiness,
    super.key,
  });

  final String title;
  final String body;
  final String linkLabel;
  final String readiness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff071512),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/generated-scenarios-grid.jpg',
                fit: BoxFit.cover,
                semanticLabel:
                    'Generated multi-region wildfire drone patrol landscape collage',
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xee071512),
                      Color(0xaa10231d),
                      Color(0x3314231d),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 26,
              right: 26,
              bottom: 24,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusPill(
                          label: linkLabel,
                          color: const Color(0xffffc857),
                        ),
                        StatusPill(
                          label: readiness,
                          color: const Color(0xffb7f1d8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xffe6f3ee),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
