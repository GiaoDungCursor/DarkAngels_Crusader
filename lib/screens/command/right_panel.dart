import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/marine.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/marine_card.dart';

class RightPanel extends ConsumerWidget {
  const RightPanel({super.key, required this.state, required this.onLog});

  final GameState state;
  final Function(String) onLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xE60A1017),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF263440)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'DEPLOYED MARINES',
                  style: TextStyle(
                    color: Color(0xFFD8A93A),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              for (var i = 0; i < state.squad.length; i++)
                MarineTile(
                  marine: state.squad[i],
                  selected: state.selectedMarineIndex == i,
                  orderLabel: '${i + 1}',
                  onTap: () {
                    ref.read(gameStateProvider.notifier).selectMarine(i);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xE60A1017),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF263440)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RESERVE',
                      style: TextStyle(
                        color: Color(0xFFD8A93A),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${state.reserveSquad.length} ready',
                      style: const TextStyle(
                        color: Color(0xFF77D48B),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.reserveSquad.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'All reserves deployed.',
                    style: TextStyle(
                      color: Color(0xFFB9C3CC),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else ...[
                if (state.missionStatus == MissionStatus.active &&
                    state.reserveSquad.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'RESERVES',
                      style: TextStyle(
                        color: Color(0xFFD8A93A),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                for (int i = 0; i < state.reserveSquad.length; i++)
                  if (state.reserveSquad[i].hp > 0)
                    ReserveMarineTile(
                      marine: state.reserveSquad[i],
                      selected: state.selectedReserveIndex == i,
                      canDeploy: state.commandPoints >= 2 &&
                          state.missionStatus == MissionStatus.active,
                      onDeploy: () {
                        ref
                            .read(gameStateProvider.notifier)
                            .selectReserveForDeployment(i);
                      },
                    ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class ReserveMarineTile extends StatelessWidget {
  const ReserveMarineTile({
    super.key,
    required this.marine,
    required this.selected,
    required this.canDeploy,
    required this.onDeploy,
  });

  final Marine marine;
  final bool selected;
  final bool canDeploy;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF17362F) : const Color(0xFF131C25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF33D6A6) : const Color(0xFF253342),
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundImage: marine.portrait == null
                    ? null
                    : AssetImage(marine.portrait!),
                backgroundColor: const Color(0xFF263440),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marine.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      marine.role,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9FAAB5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: canDeploy
                    ? 'Spend 2 CP, then click a green drop tile on the map.'
                    : 'Need 2 CP to deploy reinforcement.',
                child: OutlinedButton(
                  onPressed: canDeploy ? onDeploy : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD8A93A),
                    side: BorderSide(
                      color: canDeploy
                          ? const Color(0xFFD8A93A)
                          : const Color(0xFF31404C),
                    ),
                  ),
                  child: Text(selected ? 'PICK TILE' : 'DROP 2'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
