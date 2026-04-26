import 'package:flutter/material.dart';
import '../../models/tactical_map.dart';
import '../../providers/game_state_provider.dart';

class TopStatusCard extends StatelessWidget {
  final GameState state;
  const TopStatusCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xE60A1017),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF263440)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mission Control',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Text(
                'Select order, then commit.',
                style: TextStyle(
                  color: Color(0xFFB9C3CC),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: state.missionStatus == MissionStatus.victory
                  ? const Color(0xFF2E3D2A)
                  : state.missionStatus == MissionStatus.defeat
                  ? const Color(0xFF4A1C1C)
                  : const Color(0xFF1D2630),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: state.missionStatus == MissionStatus.active
                    ? const Color(0xFFD8A93A)
                    : state.missionStatus == MissionStatus.victory
                    ? const Color(0xFF77D48B)
                    : const Color(0xFFE55A5A),
              ),
            ),
            child: Text(
              state.missionStatus == MissionStatus.active
                  ? state.activationPhase == ActivationPhase.enemies
                        ? 'ENEMY PHASE'
                        : (state.selectedMarine?.name.toUpperCase() ??
                              'MARINE PHASE')
                  : state.missionStatus.name.toUpperCase(),
              style: TextStyle(
                color: state.missionStatus == MissionStatus.active
                    ? const Color(0xFFD8A93A)
                    : state.missionStatus == MissionStatus.victory
                    ? const Color(0xFF77D48B)
                    : const Color(0xFFE55A5A),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'T: ${state.elapsedSeconds.floor()}s  |  RP: ${state.requisitionPoints}  |  ',
            style: const TextStyle(
              color: Color(0xFF77D48B),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'CP: ${state.commandPoints}',
            style: const TextStyle(
              color: Color(0xFFD8A93A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ObjectiveBar extends StatelessWidget {
  const ObjectiveBar({super.key, required this.objectives});

  final List<MissionObjective> objectives;

  @override
  Widget build(BuildContext context) {
    if (objectives.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        border: Border.all(color: const Color(0xFF263440)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, color: Color(0xFFD8A93A)),
          const SizedBox(width: 12),
          const Text(
            'OBJECTIVES:',
            style: TextStyle(
              color: Color(0xFF9FAAB5),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final obj in objectives)
                  SizedBox(
                    width: 240,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          obj.completed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: obj.completed
                              ? const Color(0xFF77D48B)
                              : const Color(0xFFD8A93A),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${obj.label} ${obj.requiredValue > 1 ? "(${obj.progress}/${obj.requiredValue})" : ""}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: obj.completed
                                  ? const Color(0xFF77D48B)
                                  : const Color(0xFFE2E8F0),
                              fontWeight: FontWeight.w600,
                              decoration: obj.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
