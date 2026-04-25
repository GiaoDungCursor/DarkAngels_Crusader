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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF070A0E),
                    Color(0xFF101820),
                    Color(0xFF17110D),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 310,
                            child: SingleChildScrollView(
                              child: _leftPanel(gameState),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: _centerPanel(gameState)),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 340,
                            child: SingleChildScrollView(
                              child: _rightPanel(gameState),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          _leftPanel(gameState),
                          const SizedBox(height: 16),
                          SizedBox(height: 500, child: _centerPanel(gameState)),
                          const SizedBox(height: 16),
                          _rightPanel(gameState),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _leftPanel(GameState state) {
    final integrity = (state.squadIntegrity * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HeaderCard(
          title: 'Mission Control',
          subtitle:
              'Follow the active marine, choose one order, then end turn.',
          icon: Icons.public,
        ),
        const SizedBox(height: 12),
        Panel(
          title: 'Mission',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatRow('Squad integrity', '$integrity%', state.squadIntegrity),
              StatRow(
                'Planet threat',
                '${state.map.threat}%',
                state.map.threat / 100,
              ),
              StatRow(
                'Objective control',
                '${state.map.control}%',
                state.map.control / 100,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Panel(title: 'How To Play', child: _HowToPlayPanel()),
      ],
    );
  }

  Widget _centerPanel(GameState state) {
    final selected = state.selectedMarine;
    final activationNumber = state.selectedMarineIndex + 1;
    return Panel(
      title: state.map.name,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ObjectiveBar(objectives: state.objectives),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Listener(
                      onPointerMove: (event) {
                        if (_game.isCutsceneActive) return;
                        if (event.buttons == kPrimaryMouseButton ||
                            event.buttons == kMiddleMouseButton) {
                          _game.panCamera(
                            Vector2(-event.delta.dx, -event.delta.dy),
                          );
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
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _BattlefieldHud(
                        state: state,
                        activationNumber: activationNumber,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _CameraControls(game: _game),
                    ),
                    const Positioned(
                      right: 12,
                      top: 12,
                      child: _BattlefieldLegend(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (selected != null) ...[
              _SelectedUnitStrip(state: state),
              const SizedBox(height: 10),
            ],
            _CurrentOrderHint(state: state),
            const SizedBox(height: 10),
            TacticalActionBar(
              currentMode: state.actionMode,
              isMissionActive: state.missionStatus == MissionStatus.active,
              canMove:
                  state.activationPhase == ActivationPhase.marines &&
                  selected != null &&
                  !selected.hasMoved,
              canAttack:
                  state.activationPhase == ActivationPhase.marines &&
                  selected != null &&
                  !selected.hasAttacked,
              onModeChanged: (mode) {
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
              },
              onOpenArmory: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ArmoryScreen(
                    selectedMarineIndex: state.selectedMarineIndex,
                  ),
                );
              },
              onEndTurn: () {
                ref.read(gameStateProvider.notifier).endPlayerTurn();
                _log('Squad actions refreshed.');
              },
            ),
            const SizedBox(height: 14),
            BattleLog(
              entries: [
                ...state.events.map((event) => event.message),
                ...battleLog,
              ].take(6).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rightPanel(GameState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: 'Deployed Marines',
          child: Column(
            children: [
              for (var i = 0; i < state.squad.length; i++)
                MarineTile(
                  marine: state.squad[i],
                  selected: state.selectedMarineIndex == i,
                  orderLabel: '${i + 1}',
                  onTap: () {
                    ref.read(gameStateProvider.notifier).selectMarine(i);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          title: 'Reserve',
          action: Text(
            '${state.reserveSquad.length} ready',
            style: const TextStyle(
              color: Color(0xFFD8A93A),
              fontWeight: FontWeight.w900,
            ),
          ),
          child: Column(
            children: [
              if (state.reserveSquad.isEmpty)
                const Text(
                  'All reserve battle-brothers are deployed.',
                  style: TextStyle(
                    color: Color(0xFFB9C3CC),
                    fontWeight: FontWeight.w700,
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
            ],
          ),
        ),
      ],
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

class _HowToPlayPanel extends StatelessWidget {
  const _HowToPlayPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RuleStep(number: '1', text: 'Gold ring marks the active marine.'),
        _RuleStep(
          number: '2',
          text: 'Pick Move, Shoot, Melee, Skill, or Guard.',
        ),
        _RuleStep(number: '3', text: 'Click a highlighted tile or enemy.'),
        _RuleStep(number: '4', text: 'End Turn to activate the next marine.'),
      ],
    );
  }
}

class _RuleStep extends StatelessWidget {
  const _RuleStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFD8A93A),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF101010),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB9C3CC),
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
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

class _CurrentOrderHint extends StatelessWidget {
  const _CurrentOrderHint({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final mode = state.actionMode;
    final (icon, title, body, color) = switch (mode) {
      ActionMode.move => (
        Icons.open_with,
        'Move Order',
        'Click a blue tile. The active marine can move up to 2 tiles.',
        const Color(0xFF3A8DFF),
      ),
      ActionMode.shoot => (
        Icons.gps_fixed,
        'Shoot Order',
        'Click a highlighted enemy within 3 tiles and line of sight.',
        const Color(0xFFFFB15E),
      ),
      ActionMode.melee => (
        Icons.hardware,
        'Melee Order',
        'Click an adjacent enemy. Melee range is 1 tile.',
        const Color(0xFFFF6B5F),
      ),
      ActionMode.ability => (
        Icons.auto_fix_high,
        'Skill Order',
        'Spend CP on the selected marine class ability.',
        const Color(0xFFD8A93A),
      ),
      ActionMode.overwatch => (
        Icons.visibility,
        'Guard Order',
        'The marine will fire at enemies that enter line of sight.',
        const Color(0xFF77D48B),
      ),
      ActionMode.deployReserve => (
        Icons.system_update_alt,
        'Reserve Drop',
        'Click a green drop tile to bring the selected reserve marine down.',
        const Color(0xFF33D6A6),
      ),
      ActionMode.plantBomb => (
        Icons.dangerous,
        'Plant Bomb',
        'Click an adjacent enemy base to plant an explosive charge (Cost: 1 CP).',
        const Color(0xFFC04040),
      ),
      ActionMode.deployBeacon => (
        Icons.flare,
        'Deploy Beacon',
        'Click an empty tile to establish a new reserve drop zone.',
        const Color(0xFF33D6A6),
      ),
      null => (
        Icons.touch_app,
        'Choose Order',
        'Select one command below, then click the battlefield.',
        const Color(0xFFB9C3CC),
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E151D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFFB9C3CC),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 260,
              child: Text(
                state.statusMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF87919C),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattlefieldHud extends StatelessWidget {
  const _BattlefieldHud({required this.state, required this.activationNumber});

  final GameState state;
  final int activationNumber;

  @override
  Widget build(BuildContext context) {
    final active = state.selectedMarine;
    final phaseText = state.activationPhase == ActivationPhase.enemies
        ? 'Enemy Phase'
        : 'Marine Activation';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE60A1017),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF31404C)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              phaseText.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFD8A93A),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              active == null ? 'No active marine' : active.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _HudChip(
                  icon: Icons.repeat,
                  label: 'Round ${state.activationRound}',
                  color: const Color(0xFF77D48B),
                ),
                _HudChip(
                  icon: Icons.groups,
                  label: '$activationNumber/${state.squad.length}',
                  color: const Color(0xFFB9C3CC),
                ),
                _HudChip(
                  icon: Icons.bolt,
                  label: '${state.commandPoints} CP',
                  color: const Color(0xFFD8A93A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
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
        color: const Color(0xFF14202A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedUnitStrip extends StatelessWidget {
  const _SelectedUnitStrip({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final marine = state.selectedMarine!;
    final hpPercent = marine.maxHp == 0 ? 0.0 : marine.hp / marine.maxHp;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E151D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF263440)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF322516),
              foregroundColor: const Color(0xFFD8A93A),
              backgroundImage: marine.portrait == null
                  ? null
                  : AssetImage(marine.portrait!),
              child: marine.portrait == null
                  ? Icon(marine.icon ?? Icons.shield, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${marine.name} - ${marine.role}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: hpPercent.clamp(0, 1),
                      minHeight: 7,
                      backgroundColor: const Color(0xFF2B343D),
                      color: hpPercent > 0.45
                          ? const Color(0xFF77D48B)
                          : const Color(0xFFFF6B5F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _HudChip(
              icon: marine.hasMoved ? Icons.check_circle : Icons.open_with,
              label: marine.hasMoved ? 'Moved' : 'Move 2',
              color: marine.hasMoved
                  ? const Color(0xFF87919C)
                  : const Color(0xFF3A8DFF),
            ),
            const SizedBox(width: 6),
            _HudChip(
              icon: marine.hasAttacked ? Icons.check_circle : Icons.gps_fixed,
              label: marine.hasAttacked ? 'Spent' : 'Shoot 3',
              color: marine.hasAttacked
                  ? const Color(0xFF87919C)
                  : const Color(0xFFFFB15E),
            ),
          ],
        ),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        obj.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: obj.completed ? const Color(0xFF77D48B) : const Color(0xFFD8A93A),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${obj.label} ${obj.requiredValue > 1 ? "(${obj.progress}/${obj.requiredValue})" : ""}',
                        style: TextStyle(
                          color: obj.completed ? const Color(0xFF77D48B) : const Color(0xFFE2E8F0),
                          fontWeight: FontWeight.w600,
                          decoration: obj.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
