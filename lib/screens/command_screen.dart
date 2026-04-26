import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';

import '../providers/game_state_provider.dart';
import '../game/crusade_game.dart';

import '../models/marine.dart';
import '../models/mission.dart';
import '../models/tactical_map.dart';
import '../widgets/ui_components.dart';
import '../widgets/marine_card.dart';
import 'armory_screen.dart';
import 'mission_result_screen.dart';

class CommandScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final int missionIndex;

  const CommandScreen({
    super.key,
    required this.mission,
    required this.missionIndex,
  });

  @override
  ConsumerState<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends ConsumerState<CommandScreen> {
  late CrusadeGame _game;
  bool _missionResultShown = false;

  final List<String> battleLog = [
    'Flame Engine Uplink Established.',
    'Pixel Asset load complete.',
    'The Unforgiven do not fail. Hunt the Fallen.',
  ];

  @override
  void initState() {
    super.initState();
    _game = CrusadeGame(ref);

    // Set background after the current frame to avoid build phase issues if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).startMission(widget.missionIndex);
      _game.changeBackground(ref.read(gameStateProvider).map.background);
      _log('Deployed to: ${widget.mission.name}.');
    });
  }

  void _log(String text) {
    setState(() {
      battleLog.insert(0, text);
      if (battleLog.length > 6) battleLog.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      if (_missionResultShown ||
          next.missionStatus == MissionStatus.active ||
          previous?.missionStatus == next.missionStatus) {
        return;
      }
      _missionResultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MissionResultScreen(
              mission: widget.mission,
              missionIndex: widget.missionIndex,
              result: next,
            ),
          ),
        );
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFF070A0E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _topFrame(gameState),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _battlefieldFrame(gameState)),
                    if (gameState.activationPhase !=
                        ActivationPhase.deployment) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 300,
                        child: SingleChildScrollView(
                          child: _rightPanel(gameState),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _bottomConsole(gameState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topFrame(GameState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopStatusCard(state: state),
        const SizedBox(width: 8),
        Expanded(child: _ObjectiveBar(objectives: state.objectives)),
      ],
    );
  }

  Widget _battlefieldFrame(GameState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerMove: (event) {
                if (_game.isCutsceneActive) return;
                if (event.buttons == kPrimaryMouseButton ||
                    event.buttons == kMiddleMouseButton) {
                  _game.panCamera(Vector2(-event.delta.dx, -event.delta.dy));
                }
              },
              onPointerSignal: (event) {
                if (_game.isCutsceneActive) return;
                if (event is PointerScrollEvent) {
                  final delta = event.scrollDelta.dy < 0 ? 0.12 : -0.12;
                  _game.zoomCamera(delta);
                }
              },
              child: GameWidget(game: _game),
            ),
          ),
          Positioned(
            left: 10,
            top: 12,
            child: _BattlefieldHudMini(state: state),
          ),
          if (state.activationPhase != ActivationPhase.deployment &&
              state.selectedMarine != null)
            Positioned(
              left: 10,
              top: 66,
              bottom: 10,
              child: CommandSquarePanel(
                marine: state.selectedMarine!,
                currentMode: state.actionMode,
                isMissionActive: state.missionStatus == MissionStatus.active,
                canMove:
                    state.activationPhase == ActivationPhase.marines &&
                    state.selectedMarine!.actionPoints > 0,
                canAttack:
                    state.activationPhase == ActivationPhase.marines &&
                    state.selectedMarine!.actionPoints > 0,
                onModeChanged: _setMode,
                onOpenArmory: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ArmoryScreen(
                      selectedMarineIndex: state.selectedMarineIndex,
                    ),
                  );
                },
              ),
            ),
          const Positioned(right: 10, top: 10, child: _BattlefieldLegend()),
          Positioned(
            right: 10,
            bottom: 10,
            child: _CameraControls(game: _game),
          ),
        ],
      ),
    );
  }

  Widget _bottomConsole(GameState state) {
    if (state.activationPhase == ActivationPhase.deployment) {
      return _DeploymentConsole(state: state);
    }
    return SizedBox(
      height: 118,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: BattleLog(
              entries: [
                ...state.events.map((e) => e.message),
                ...battleLog,
              ].take(4).toList(),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 190,
            child: EndTurnButton(
              isMissionActive: state.missionStatus == MissionStatus.active,
              onEndTurn: () {
                ref.read(gameStateProvider.notifier).endSquadTurn();
                _log('Squad turn ended. Enemy forces advancing.');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _setMode(ActionMode mode) {
    ref.read(gameStateProvider.notifier).setActionMode(mode);
    switch (mode) {
      case ActionMode.move:
        _log('Move mode: advance up to 2 tiles.');
      case ActionMode.shoot:
        _log('Shoot mode: ranged attacks reach 3 tiles.');
      case ActionMode.melee:
        _log('Melee mode: engage adjacent enemies.');
      case ActionMode.ability:
        _log('Ability mode: spend CP for class powers.');
      case ActionMode.overwatch:
        ref.read(gameStateProvider.notifier).setOverwatch();
        _log('Overwatch set for selected marine.');
      case ActionMode.deployReserve:
        _log('Reserve drop mode: click a green drop tile.');
      case ActionMode.plantBomb:
        _log('Plant Bomb mode: click an adjacent enemy base.');
      case ActionMode.deployBeacon:
        _log('Deploy Beacon: click an empty tile within 2 spaces.');
    }
  }

  Widget _rightPanel(GameState state) {
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
              else
                for (var i = 0; i < state.reserveSquad.length; i++)
                  _ReserveMarineTile(
                    marine: state.reserveSquad[i],
                    selected: state.selectedReserveIndex == i,
                    canDeploy:
                        state.commandPoints >= 2 &&
                        state.missionStatus == MissionStatus.active,
                    onDeploy: () {
                      ref
                          .read(gameStateProvider.notifier)
                          .selectReserveForDeployment(i);
                    },
                  ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopStatusCard extends StatelessWidget {
  final GameState state;
  const _TopStatusCard({required this.state});

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

class _BattlefieldHudMini extends StatelessWidget {
  const _BattlefieldHudMini({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final active = state.selectedMarine;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD0A1017),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF31404C)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              active?.name ?? 'No active marine',
              style: const TextStyle(
                color: Color(0xFFD8A93A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            _MiniStatusPill(
              label: 'R${state.activationRound}',
              color: const Color(0xFF77D48B),
            ),
            _MiniStatusPill(
              label: '${state.commandPoints} CP',
              color: const Color(0xFFD8A93A),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  const _MiniStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ReserveMarineTile extends StatelessWidget {
  const _ReserveMarineTile({
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

class _CameraControls extends StatelessWidget {
  const _CameraControls({required this.game});

  final CrusadeGame game;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD0E151D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF263440)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Pan up',
            onPressed: () => game.panCamera(Vector2(0, -160)),
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Pan left',
                onPressed: () => game.panCamera(Vector2(-160, 0)),
                icon: const Icon(Icons.keyboard_arrow_left),
              ),
              IconButton(
                tooltip: 'Zoom in',
                onPressed: () => game.zoomCamera(0.12),
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: 'Pan right',
                onPressed: () => game.panCamera(Vector2(160, 0)),
                icon: const Icon(Icons.keyboard_arrow_right),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Pan down',
                onPressed: () => game.panCamera(Vector2(0, 160)),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              IconButton(
                tooltip: 'Zoom out',
                onPressed: () => game.zoomCamera(-0.12),
                icon: const Icon(Icons.remove),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BattlefieldLegend extends StatelessWidget {
  const _BattlefieldLegend();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD0A1017),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF31404C)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MAP LEGEND',
              style: TextStyle(
                color: Color(0xFFD8A93A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            _LegendLine(color: Color(0xFF3A8DFF), text: 'Blue: move tile'),
            _LegendLine(color: Color(0xFFFFB15E), text: 'Gold: shoot target'),
            _LegendLine(color: Color(0xFFFF6B5F), text: 'Red: melee/danger'),
            _LegendLine(color: Color(0xFF33D6A6), text: 'Green: reserve drop'),
            _LegendLine(color: Color(0xFFC04040), text: 'Dark Red: plant bomb'),
            _LegendLine(color: Color(0xFF87919C), text: 'Gray: cover/block'),
            SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mouse, size: 14, color: Color(0xFFD8A93A)),
                SizedBox(width: 6),
                Text(
                  'Wheel zoom | drag pan',
                  style: TextStyle(
                    color: Color(0xFFB9C3CC),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _LegendLine extends StatelessWidget {
  const _LegendLine({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.65),
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFB9C3CC),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveBar extends StatelessWidget {
  const _ObjectiveBar({required this.objectives});

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

class _DeploymentConsole extends ConsumerWidget {
  final GameState state;

  const _DeploymentConsole({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needed = state.squad.length;
    final selected = state.selectedDropZones.length;
    final ready = selected == needed;

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF31404C), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'PLANETFALL PROTOCOL INITIATED',
            style: TextStyle(
              color: Color(0xFFD8A93A),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select Drop Coordinates ($selected / $needed)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            width: 300,
            child: FilledButton.icon(
              onPressed: ready
                  ? () {
                      ref.read(gameStateProvider.notifier).confirmDeployment();
                    }
                  : null,
              icon: const Icon(Icons.flight_land),
              label: const Text(
                'CONFIRM DROP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: ready
                    ? const Color(0xFF9A3232)
                    : Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
