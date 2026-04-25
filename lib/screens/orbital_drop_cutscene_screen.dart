import 'package:flutter/material.dart';

import '../models/mission.dart';
import 'command_screen.dart';

class OrbitalDropCutsceneScreen extends StatelessWidget {
  const OrbitalDropCutsceneScreen({
    super.key,
    required this.mission,
    required this.missionIndex,
  });

  final Mission mission;
  final int missionIndex;

  @override
  Widget build(BuildContext context) {
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
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.78),
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
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xDD0A1017),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFD8A93A)),
                        ),
                        child: const Text(
                          'STATIC MISSION ART',
                          style: TextStyle(
                            color: Color(0xFFD8A93A),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _LandingBrief(
                    mission: mission,
                    onDeploy: () => _enterGame(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _enterGame(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            CommandScreen(mission: mission, missionIndex: missionIndex),
      ),
    );
  }
}

class _LandingBrief extends StatelessWidget {
  const _LandingBrief({required this.mission, required this.onDeploy});

  final Mission mission;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE80A1017),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8A93A), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DROP POD LANDED',
                  style: TextStyle(
                    color: Color(0xFFD8A93A),
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
                  'Four battle-brothers have exited the pod. Secure cover, activate the relay, then call the rest of the squad from reserve.',
                  style: const TextStyle(
                    color: Color(0xFFB9C3CC),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            );

            final button = FilledButton.icon(
              onPressed: onDeploy,
              icon: const Icon(Icons.shield),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'DEPLOY SQUAD',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9A3232),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [content, const SizedBox(height: 14), button],
              );
            }

            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 18),
                SizedBox(width: 240, child: button),
              ],
            );
          },
        ),
      ),
    );
  }
}
