import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flame/game.dart';
import '../../game/crusade_game.dart';
import '../../providers/game_state_provider.dart';
import '../armory_screen.dart';
import '../../widgets/ui_components.dart';

class BattlefieldFrame extends StatelessWidget {
  final CrusadeGame game;
  final GameState state;
  final Function(ActionMode) onSetMode;

  const BattlefieldFrame({
    super.key,
    required this.game,
    required this.state,
    required this.onSetMode,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerMove: (event) {
                if (game.isCutsceneActive) return;
                if (event.buttons == kPrimaryMouseButton ||
                    event.buttons == kMiddleMouseButton) {
                  game.panCamera(Vector2(-event.delta.dx, -event.delta.dy));
                }
              },
              onPointerSignal: (event) {
                if (game.isCutsceneActive) return;
                if (event is PointerScrollEvent) {
                  final delta = event.scrollDelta.dy < 0 ? 0.12 : -0.12;
                  game.zoomCamera(delta);
                }
              },
              child: GameWidget(game: game),
            ),
          ),
          Positioned(
            left: 10,
            top: 12,
            child: BattlefieldHudMini(state: state),
          ),
          if (state.selectedMarine != null)
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
                onModeChanged: onSetMode,
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
          const Positioned(right: 10, top: 10, child: BattlefieldLegend()),
          Positioned(
            left: 10,
            bottom: 10,
            child: CameraControls(game: game),
          ),
        ],
      ),
    );
  }
}

class BattlefieldHudMini extends StatelessWidget {
  const BattlefieldHudMini({super.key, required this.state});
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
            MiniStatusPill(
              label: 'R${state.activationRound}',
              color: const Color(0xFF77D48B),
            ),
            MiniStatusPill(
              label: '${state.commandPoints} CP',
              color: const Color(0xFFD8A93A),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniStatusPill extends StatelessWidget {
  const MiniStatusPill({super.key, required this.label, required this.color});
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

class CameraControls extends StatelessWidget {
  const CameraControls({super.key, required this.game});
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

class BattlefieldLegend extends StatelessWidget {
  const BattlefieldLegend({super.key});

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
            LegendLine(color: Color(0xFF3A8DFF), text: 'Blue: move tile'),
            LegendLine(color: Color(0xFFFFB15E), text: 'Gold: shoot target'),
            LegendLine(color: Color(0xFFFF6B5F), text: 'Red: melee/danger'),
            LegendLine(color: Color(0xFF33D6A6), text: 'Green: reserve drop'),
            LegendLine(color: Color(0xFFC04040), text: 'Dark Red: plant bomb'),
            LegendLine(color: Color(0xFF87919C), text: 'Gray: cover/block'),
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

class LegendLine extends StatelessWidget {
  const LegendLine({super.key, required this.color, required this.text});

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
