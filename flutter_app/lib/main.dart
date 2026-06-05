import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const AeroScoutApp());
}

class AeroScoutApp extends StatelessWidget {
  const AeroScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroScout Sim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0c7c59),
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const AeroScoutShell(),
    );
  }
}

class AeroScoutShell extends StatefulWidget {
  const AeroScoutShell({super.key});

  @override
  State<AeroScoutShell> createState() => _AeroScoutShellState();
}

class _AeroScoutShellState extends State<AeroScoutShell> {
  int _page = 0;
  String _region = 'All';

  static const _nav = [
    NavItem(Icons.dashboard_outlined, 'Scenario Library'),
    NavItem(Icons.radar_outlined, 'Live Simulator'),
    NavItem(Icons.flight_takeoff_outlined, 'Drone Fleet'),
    NavItem(Icons.monitor_heart_outlined, 'Analytics'),
  ];

  Iterable<Scenario> get _visibleScenarios {
    if (_region == 'All') {
      return scenarios;
    }
    return scenarios.where((scenario) => scenario.region == _region);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final page = switch (_page) {
      0 => ScenarioLibrary(
        region: _region,
        visibleScenarios: _visibleScenarios.toList(),
        onRegionChanged: (region) => setState(() => _region = region),
      ),
      1 => const LiveSimulator(),
      2 => const FleetPage(),
      _ => const AnalyticsPage(),
    };

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f5),
      body: Row(
        children: [
          if (!compact)
            Sidebar(
              items: _nav,
              selected: _page,
              onSelect: (index) => setState(() => _page = index),
            ),
          Expanded(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TopBar(
                    compact: compact,
                    title: _nav[_page].label,
                    onMenuTap: () {},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 28,
                        18,
                        compact ? 16 : 28,
                        compact ? 96 : 28,
                      ),
                      child: page,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: compact
          ? NavigationBar(
              selectedIndex: _page,
              onDestinationSelected: (index) => setState(() => _page = index),
              destinations: _nav
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }
}

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
                  'AeroScout Sim',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Mission Control',
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
            StatusPill(label: 'Online', color: const Color(0xff12805c)),
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
              Row(
                children: const [
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

class ScenarioLibrary extends StatelessWidget {
  const ScenarioLibrary({
    required this.region,
    required this.visibleScenarios,
    required this.onRegionChanged,
    super.key,
  });

  final String region;
  final List<Scenario> visibleScenarios;
  final ValueChanged<String> onRegionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroPanel(
          title: 'Cooperative wildfire patrol planning',
          body:
              'Tune drone routes, sensor cadence, and terrain response before sending a fleet into a live fire zone.',
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Pre-built Scenarios',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: regions
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(item),
                      selected: region == item,
                      onSelected: (_) => onRegionChanged(item),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        ResponsiveGrid(
          children: visibleScenarios
              .map((scenario) => ScenarioCard(scenario: scenario))
              .toList(),
        ),
      ],
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff142f28),
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x3314231d),
                      Color(0x9914231d),
                      Color(0xdd14231d),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusPill(
                      label: 'Runbook ready',
                      color: Color(0xffffc857),
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

class ScenarioCard extends StatelessWidget {
  const ScenarioCard({required this.scenario, super.key});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.65,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      scenario.image,
                      fit: BoxFit.cover,
                      semanticLabel: 'Generated landscape for ${scenario.name}',
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x22000000),
                            Color(0x88000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: StatusPill(
                        label: '${scenario.region} region',
                        color: scenario.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            scenario.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            scenario.description,
            style: const TextStyle(color: Color(0xff65736f), height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: '${scenario.drones} drones',
                color: const Color(0xff0e7656),
              ),
              StatusPill(label: scenario.risk, color: const Color(0xffc2542d)),
            ],
          ),
        ],
      ),
    );
  }
}

class LiveSimulator extends StatelessWidget {
  const LiveSimulator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'Live Simulator'),
        SizedBox(height: 14),
        SimulatorBoard(),
        SizedBox(height: 16),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Run #2417',
              value: 'Active',
              detail: 'Foothill ridge sweep',
            ),
            MetricCard(
              label: 'Coverage',
              value: '83%',
              detail: 'Projected in 18 minutes',
            ),
            MetricCard(
              label: 'Wind Shift',
              value: '12 mph',
              detail: 'Northwest at 14:20',
            ),
          ],
        ),
      ],
    );
  }
}

class SimulatorBoard extends StatelessWidget {
  const SimulatorBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: MissionMapPainter())),
            Positioned(
              left: 16,
              top: 16,
              child: StatusPill(
                label: 'Thermal front tracking',
                color: Color(0xffc2542d),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FilledButton.icon(
                onPressed: null,
                icon: Icon(Icons.play_arrow),
                label: Text('Start run'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FleetPage extends StatelessWidget {
  const FleetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'Drone Fleet'),
        SizedBox(height: 14),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Scout Alpha',
              value: 'Ready',
              detail: 'Thermal + visual',
            ),
            MetricCard(
              label: 'Relay Beta',
              value: 'Charging',
              detail: '74% battery',
            ),
            MetricCard(
              label: 'Mapper Delta',
              value: 'Ready',
              detail: 'LiDAR sweep',
            ),
          ],
        ),
      ],
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'Analytics'),
        SizedBox(height: 14),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Detection Latency',
              value: '2.6 min',
              detail: 'Down 31% vs manual patrol',
            ),
            MetricCard(
              label: 'Thermal Confidence',
              value: '91%',
              detail: 'Model ensemble average',
            ),
            MetricCard(
              label: 'Safe Return',
              value: '97%',
              detail: 'Battery-aware routing',
            ),
          ],
        ),
      ],
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1180
        ? 3
        : width >= 760
        ? 2
        : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = columns == 1 ? 12.0 : 16.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdfe8e4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    super.key,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xff60716b))),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(detail, style: const TextStyle(color: Color(0xff65736f))),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        if (trailing != null)
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: trailing,
            ),
          ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = color.computeLuminance() > 0.55
        ? const Color(0xff17231f)
        : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TerrainPainter extends CustomPainter {
  TerrainPainter({required this.seed, required this.night});

  final int seed;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: night
            ? const [Color(0xff12352d), Color(0xff0c1715)]
            : const [Color(0xffdbeee8), Color(0xffffe0b5)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final random = math.Random(seed);
    for (var layer = 0; layer < 4; layer++) {
      final path = Path()..moveTo(0, size.height);
      final base = size.height * (0.45 + layer * 0.13);
      for (var x = 0.0; x <= size.width + 30; x += 34) {
        final wave =
            math.sin((x / size.width * math.pi * 2) + layer + seed) * 18;
        final jitter = (random.nextDouble() - 0.5) * 20;
        path.lineTo(x, base + wave + jitter);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      final color = night
          ? [
              const Color(0xff1f5748),
              const Color(0xff173c34),
              const Color(0xff102a25),
              const Color(0xff0b1b18),
            ][layer]
          : [
              const Color(0xff8ec7a4),
              const Color(0xff6aa37f),
              const Color(0xff4b795f),
              const Color(0xff315241),
            ][layer];
      canvas.drawPath(path, Paint()..color = color);
    }

    final fire = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0xffffd166), Color(0xffff7d3b), Color(0x00ff7d3b)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.72, size.height * 0.58),
              radius: size.shortestSide * 0.33,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.58),
      size.shortestSide * 0.34,
      fire,
    );

    final dronePaint = Paint()
      ..color = night ? Colors.white : const Color(0xff10231d)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final center = Offset(
        size.width * (0.22 + i * 0.22),
        size.height * (0.24 + i * 0.06),
      );
      canvas.drawCircle(center, 9, dronePaint);
      canvas.drawLine(
        center.translate(-18, 0),
        center.translate(18, 0),
        dronePaint,
      );
      canvas.drawLine(
        center.translate(0, -18),
        center.translate(0, 18),
        dronePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TerrainPainter oldDelegate) {
    return seed != oldDelegate.seed || night != oldDelegate.night;
  }
}

class MissionMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xffe7f1ed), Color(0xffffffff)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      background,
    );

    final grid = Paint()
      ..color = const Color(0xffd9e6e1)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final route = Path()
      ..moveTo(size.width * 0.12, size.height * 0.72)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.28,
        size.width * 0.54,
        size.height * 0.82,
        size.width * 0.72,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.16,
        size.width * 0.92,
        size.height * 0.42,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xff0e7656)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final hazard = Paint()..color = const Color(0x44f05d2f);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.54),
        width: size.width * 0.28,
        height: size.height * 0.42,
      ),
      hazard,
    );

    final pointPaint = Paint()..color = const Color(0xff10231d);
    for (final point in [
      Offset(size.width * 0.12, size.height * 0.72),
      Offset(size.width * 0.34, size.height * 0.38),
      Offset(size.width * 0.72, size.height * 0.36),
      Offset(size.width * 0.92, size.height * 0.42),
    ]) {
      canvas.drawCircle(point, 7, pointPaint);
      canvas.drawCircle(point, 14, Paint()..color = const Color(0x2210231d));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Scenario {
  const Scenario({
    required this.name,
    required this.region,
    required this.description,
    required this.drones,
    required this.risk,
    required this.color,
    required this.seed,
    required this.image,
  });

  final String name;
  final String region;
  final String description;
  final int drones;
  final String risk;
  final Color color;
  final int seed;
  final String image;
}

class NavItem {
  const NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

const regions = ['All', 'Mountain', 'Coastal', 'Boreal', 'Plateau'];

const scenarios = [
  Scenario(
    name: 'Min Mountains · California',
    region: 'Mountain',
    description:
        'Steep ridgeline scan with smoke-obscured valleys and narrow return corridors.',
    drones: 6,
    risk: 'High heat',
    color: Color(0xff315241),
    seed: 4,
    image: 'assets/images/scenario-mountain.jpg',
  ),
  Scenario(
    name: 'Santa Cruz Fog Belt',
    region: 'Coastal',
    description:
        'Low ceiling patrol that balances thermal locks against shifting marine fog.',
    drones: 5,
    risk: 'Visibility',
    color: Color(0xff2f7d9a),
    seed: 8,
    image: 'assets/images/scenario-coastal.jpg',
  ),
  Scenario(
    name: 'Yukon Boreal Line',
    region: 'Boreal',
    description:
        'Long-range perimeter sweep through dense conifer canopy and cold uplifts.',
    drones: 8,
    risk: 'Canopy',
    color: Color(0xff0e7656),
    seed: 12,
    image: 'assets/images/scenario-boreal.jpg',
  ),
  Scenario(
    name: 'Colorado Plateau Watch',
    region: 'Plateau',
    description:
        'Mesa-to-canyon mapping with relay handoffs and strong afternoon winds.',
    drones: 7,
    risk: 'Wind',
    color: Color(0xffc2542d),
    seed: 16,
    image: 'assets/images/scenario-plateau.jpg',
  ),
];
