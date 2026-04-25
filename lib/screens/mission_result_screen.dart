import 'package:flutter/material.dart';

import '../models/mission.dart';
import '../providers/game_state_provider.dart';
import 'hub_screen.dart';
import 'mission_select_screen.dart';

class MissionResultScreen extends StatelessWidget {
  const MissionResultScreen({
    super.key,
    required this.mission,
    required this.missionIndex,
    required this.result,
  });

  final Mission mission;
  final int missionIndex;
  final GameState result;

  @override
  Widget build(BuildContext context) {
    final victory = result.missionStatus == MissionStatus.victory;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/drop_pod_landing_splash.png',
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  _ResultPanel(
                    mission: mission,
                    result: result,
                    victory: victory,
                    onStrategium: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HubScreen()),
                        (route) => route.isFirst,
                      );
                    },
                    onNextMission: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const MissionSelectScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.mission,
    required this.result,
    required this.victory,
    required this.onStrategium,
    required this.onNextMission,
  });

  final Mission mission;
  final GameState result;
  final bool victory;
  final VoidCallback onStrategium;
  final VoidCallback onNextMission;

  @override
  Widget build(BuildContext context) {
    final accent = victory ? const Color(0xFF77D48B) : const Color(0xFFE55A5A);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEA0A1017),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  victory ? 'EXTRACTION COMPLETE' : 'MISSION FAILED',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mission.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  victory
                      ? 'Drop pod recovery beacon locked. The clue is secured and the squad withdraws under covering fire.'
                      : 'The strike force is wounded and pulled back for rearmament. The war for Obolus Prime continues.',
                  style: const TextStyle(
                    color: Color(0xFFB9C3CC),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip(
                      label: 'Time',
                      value: '${result.elapsedSeconds.floor()}s',
                    ),
                    _StatChip(
                      label: 'RP',
                      value: '${result.requisitionPoints}',
                    ),
                    _StatChip(label: 'CP', value: '${result.commandPoints}'),
                    _StatChip(
                      label: 'Round',
                      value: '${result.activationRound}',
                    ),
                  ],
                ),
              ],
            );

            final buttons = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: onNextMission,
                  icon: const Icon(Icons.public),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text('MISSION SELECT'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD8A93A),
                    foregroundColor: const Color(0xFF101010),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onStrategium,
                  icon: const Icon(Icons.home),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text('RETURN TO SHIP'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFB9C3CC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [summary, const SizedBox(height: 16), buttons],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: summary),
                const SizedBox(width: 18),
                SizedBox(width: 230, child: buttons),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111B24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF31404C)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ',
              style: const TextStyle(
                color: Color(0xFF9FAAB5),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFD8A93A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
