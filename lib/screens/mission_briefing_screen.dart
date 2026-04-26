import 'package:flutter/material.dart';

import '../models/mission.dart';
import 'command_screen.dart';

class MissionBriefingScreen extends StatefulWidget {
  const MissionBriefingScreen({
    super.key,
    required this.mission,
    required this.missionIndex,
  });

  final Mission mission;
  final int missionIndex;

  @override
  State<MissionBriefingScreen> createState() => _MissionBriefingScreenState();
}

class _MissionBriefingScreenState extends State<MissionBriefingScreen> {
  int _lineIndex = 0;

  static const _speaker = 'Master Azael Vorn';
  static const _lines = [
    'Operation Iron Halo begins now.',
    'Drop Zone Epsilon is lost. You will land with four battle-brothers and secure the relay.',
    'The public objective is simple: restore orbital coordination and break the enemy beachhead.',
    'The true directive is not. Recover the encrypted trace before anyone else understands what it is.',
    'When the pod opens, move fast. Cover will keep you alive. The relay will bring your brothers down.',
  ];

  bool get _isLastLine => _lineIndex >= _lines.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/backgrounds/hub_spaceship.png', fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.38),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 880;
                    final portrait = _CommanderPortrait(wide: wide);
                    final briefing = _BriefingTextPanel(
                      mission: widget.mission,
                      speaker: _speaker,
                      line: _lines[_lineIndex],
                      lineIndex: _lineIndex,
                      lineCount: _lines.length,
                      isLastLine: _isLastLine,
                      onAdvance: _advance,
                    );

                    if (!wide) {
                      return Column(
                        children: [
                          SizedBox(height: 320, child: portrait),
                          const SizedBox(height: 18),
                          Expanded(child: briefing),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 4, child: portrait),
                        const SizedBox(width: 22),
                        Expanded(flex: 5, child: briefing),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: SafeArea(
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _advance() {
    if (!_isLastLine) {
      setState(() => _lineIndex++);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CommandScreen(
          mission: widget.mission,
          missionIndex: widget.missionIndex,
        ),
      ),
    );
  }
}

class _CommanderPortrait extends StatelessWidget {
  const _CommanderPortrait({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8A93A), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD8A93A).withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/portraits/cpt_varro.png',
              fit: wide ? BoxFit.cover : BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.76),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'INNER CIRCLE LIAISON',
                    style: TextStyle(
                      color: Color(0xFFD8A93A),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Master Azael Vorn',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingTextPanel extends StatelessWidget {
  const _BriefingTextPanel({
    required this.mission,
    required this.speaker,
    required this.line,
    required this.lineIndex,
    required this.lineCount,
    required this.isLastLine,
    required this.onAdvance,
  });

  final Mission mission;
  final String speaker;
  final String line;
  final int lineIndex;
  final int lineCount;
  final bool isLastLine;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEE0E151D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF31404C)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THE OBOLUS PRIME INCURSION',
              style: TextStyle(
                color: Color(0xFFD8A93A),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mission.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mission.subtitle,
              style: const TextStyle(
                color: Color(0xFFB9C3CC),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _BriefingChip(
                  icon: Icons.public,
                  label: 'Secure relay',
                  color: const Color(0xFF77D48B),
                ),
                _BriefingChip(
                  icon: Icons.lock,
                  label: 'Hidden trace',
                  color: const Color(0xFFD8A93A),
                ),
                _BriefingChip(
                  icon: Icons.groups,
                  label: 'Initial squad: 4',
                  color: const Color(0xFFB9C3CC),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF090E14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD8A93A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speaker.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFD8A93A),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      '"$line"',
                      key: ValueKey(line),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (lineIndex + 1) / lineCount,
                    minHeight: 7,
                    backgroundColor: const Color(0xFF263440),
                    color: const Color(0xFFD8A93A),
                  ),
                ),
                const SizedBox(width: 14),
                FilledButton.icon(
                  onPressed: onAdvance,
                  icon: Icon(isLastLine ? Icons.flight_land : Icons.touch_app),
                  label: Text(isLastLine ? 'BEGIN DROP' : 'NEXT'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isLastLine
                        ? const Color(0xFF9A3232)
                        : const Color(0xFFD8A93A),
                    foregroundColor: isLastLine
                        ? Colors.white
                        : const Color(0xFF101010),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingChip extends StatelessWidget {
  const _BriefingChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
