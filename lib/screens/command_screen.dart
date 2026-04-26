import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_state_provider.dart';
import '../models/mission.dart';
import '../models/grid_position.dart';

import '../game/crusade_game.dart';
import '../widgets/ui_components.dart';

import 'mission_result_screen.dart';
import 'command/battlefield_frame.dart';
import 'command/right_panel.dart';
import 'command/top_frame.dart';

class CommandScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final int missionIndex;
  final GridPosition? selectedDropZone;

  const CommandScreen({
    super.key,
    required this.mission,
    required this.missionIndex,
    this.selectedDropZone,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).startMission(
            widget.missionIndex,
            selectedDropZone: widget.selectedDropZone,
          );
      _game.resetWorld();
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopStatusCard(state: gameState),
                  const SizedBox(width: 8),
                  Expanded(child: ObjectiveBar(objectives: gameState.objectives)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: BattlefieldFrame(game: _game, state: gameState, onSetMode: _setMode)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 300,
                      child: SingleChildScrollView(
                        child: RightPanel(state: gameState, onLog: _log),
                      ),
                    ),
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

  Widget _bottomConsole(GameState state) {
    return SizedBox(
      height: 104,
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
}
