import 'package:flutter/material.dart';

import '../models/grid_position.dart';
import '../models/mission.dart';
import '../models/tactical_map.dart';
import 'orbital_drop_cutscene_screen.dart';

class DropPlanningScreen extends StatefulWidget {
  const DropPlanningScreen({
    super.key,
    required this.mission,
    required this.missionIndex,
  });

  final Mission mission;
  final int missionIndex;

  @override
  State<DropPlanningScreen> createState() => _DropPlanningScreenState();
}

class _DropPlanningScreenState extends State<DropPlanningScreen> {
  GridPosition? _selectedZone;

  @override
  Widget build(BuildContext context) {
    final map = campaignMaps[widget.missionIndex];
    final selectedZone =
        _selectedZone ??
        (map.dropZones.isNotEmpty ? map.dropZones.first : null);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _HoloDropConsole(
                  map: map,
                  selectedZone: selectedZone,
                  onZoneSelected: (zone) {
                    setState(() => _selectedZone = zone);
                  },
                ),
              ),
              const SizedBox(width: 18),
              SizedBox(
                width: 340,
                child: _DropIntelPanel(
                  mission: widget.mission,
                  selectedZone: selectedZone,
                  onDeploy: selectedZone == null
                      ? null
                      : () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => OrbitalDropCutsceneScreen(
                                mission: widget.mission,
                                missionIndex: widget.missionIndex,
                                selectedDropZone: selectedZone,
                              ),
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoloDropConsole extends StatelessWidget {
  const _HoloDropConsole({
    required this.map,
    required this.selectedZone,
    required this.onZoneSelected,
  });

  final TacticalMap map;
  final GridPosition? selectedZone;
  final ValueChanged<GridPosition> onZoneSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF071015),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF23414A), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33D6A6).withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.radar, color: Color(0xFF33D6A6), size: 22),
                const SizedBox(width: 10),
                const Text(
                  'ORBITAL INSERTION MAP',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                Text(
                  'SEST ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFFD8A93A),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final diameter = constraints.biggest.shortestSide;
                  final tileSize = (diameter * 0.78 / map.width)
                      .floorToDouble();
                  final mapWidth = tileSize * map.width;
                  final mapHeight = tileSize * map.height;

                  return Center(
                    child: SizedBox.square(
                      dimension: diameter,
                      child: ClipOval(
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Color(0xFF0A151B),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: CustomPaint(painter: _RadarPainter()),
                              ),
                              SizedBox(
                                width: mapWidth,
                                height: mapHeight,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ColorFiltered(
                                        colorFilter: const ColorFilter.mode(
                                          Color(0x9933D6A6),
                                          BlendMode.screen,
                                        ),
                                        child: Image.asset(
                                          'assets/images/${map.background}',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0x9933D6A6),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    for (var y = 0; y < map.height; y++)
                                      for (var x = 0; x < map.width; x++)
                                        Positioned(
                                          left: x * tileSize,
                                          top: y * tileSize,
                                          width: tileSize,
                                          height: tileSize,
                                          child: _buildTile(
                                            context,
                                            GridPosition(x, y),
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                              Positioned(
                                right: diameter * 0.14,
                                bottom: diameter * 0.18,
                                child: const Text(
                                  '100M',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, GridPosition pos) {
    if (map.dropZones.contains(pos)) {
      final isSelected = selectedZone == pos;
      return GestureDetector(
        onTap: () => onZoneSelected(pos),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFD8A93A).withValues(alpha: 0.6)
                : const Color(0xFF33D6A6).withValues(alpha: 0.35),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF33D6A6),
              width: isSelected ? 3 : 1,
            ),
            shape: BoxShape.circle,
          ),
          child: isSelected
              ? const Icon(Icons.arrow_upward, color: Colors.white)
              : const Center(
                  child: Text(
                    '',
                    style: TextStyle(
                      color: Color(0xFF33D6A6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      );
    }

    if (map.enemyBaseTiles.contains(pos)) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE55A5A).withValues(alpha: 0.3),
          border: Border.all(color: const Color(0xFFE55A5A)),
        ),
        child: const Icon(Icons.fort, color: Color(0xFFE55A5A), size: 16),
      );
    }

    if (map.bossSpawn == pos) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB041FF).withValues(alpha: 0.3),
          border: Border.all(color: const Color(0xFFB041FF)),
        ),
        child: const Icon(Icons.warning, color: Color(0xFFB041FF), size: 16),
      );
    }

    return const SizedBox.shrink();
  }
}

class _DropIntelPanel extends StatelessWidget {
  const _DropIntelPanel({
    required this.mission,
    required this.selectedZone,
    required this.onDeploy,
  });

  final Mission mission;
  final GridPosition? selectedZone;
  final VoidCallback? onDeploy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE60A1017),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF263440), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DROP LOGISTICS',
              style: TextStyle(
                color: Color(0xFFD8A93A),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              mission.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mission.subtitle,
              style: const TextStyle(
                color: Color(0xFFB9C3CC),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            _InfoBox(
              title: 'PRIMARY INSERTION',
              content: selectedZone == null
                  ? 'Select a beacon on the holo-map.'
                  : 'Grid ${selectedZone!.x}-${selectedZone!.y}. Four marines deploy around the pod.',
              icon: Icons.my_location,
              color: selectedZone == null
                  ? const Color(0xFFD8A93A)
                  : const Color(0xFF77D48B),
            ),
            const SizedBox(height: 12),
            const _InfoBox(
              title: 'ORBITAL DROP',
              content:
                  'Camera will track the pod impact, then the strike team exits from the landing zone.',
              icon: Icons.rocket_launch,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onDeploy,
              icon: const Icon(Icons.keyboard_double_arrow_down),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'CONFIRM DROP',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD8A93A),
                foregroundColor: const Color(0xFF101010),
                disabledBackgroundColor: const Color(0xFF263440),
                disabledForegroundColor: const Color(0xFF6B7A88),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final gridPaint = Paint()
      ..color = const Color(0x2233D6A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final ringPaint = Paint()
      ..color = const Color(0x5533D6A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, ringPaint);
    }
    for (var i = -5; i <= 5; i++) {
      final p = center.dx + i * radius / 5;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), gridPaint);
      final q = center.dy + i * radius / 5;
      canvas.drawLine(Offset(0, q), Offset(size.width, q), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.title,
    required this.content,
    required this.icon,
    this.color = const Color(0xFFB9C3CC),
  });

  final String title;
  final String content;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111B24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF31404C)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
