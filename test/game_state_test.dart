import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_code/models/grid_position.dart';
import 'package:game_code/models/tactical_map.dart';
import 'package:game_code/providers/game_state_provider.dart';
import 'package:game_code/services/pathfinder.dart';

void main() {
  test('A* avoids cover blockers', () {
    final map = campaignMaps.first;
    final path = const Pathfinder().findPath(
      map: map,
      start: const GridPosition(3, 2),
      goal: const GridPosition(8, 2),
      blockers: map.coverTiles,
    );

    expect(path, isNotEmpty);
    expect(path.any(map.coverTiles.contains), isFalse);
  });

  test('reachable tiles respect two tile movement and blockers', () {
    final map = campaignMaps.first;
    final reachable = const Pathfinder().reachable(
      map: map,
      start: const GridPosition(3, 2),
      maxSteps: 2,
      blockers: map.coverTiles,
    );

    expect(
      reachable.every((tile) => tile.distanceTo(const GridPosition(3, 2)) <= 2),
      isTrue,
    );
    expect(reachable.any(map.coverTiles.contains), isFalse);
  });

  test('line of sight is blocked by cover between shooter and target', () {
    final map = campaignMaps.first;
    expect(
      const Pathfinder().hasLineOfSight(
        map: map,
        from: const GridPosition(3, 2),
        to: const GridPosition(8, 2),
      ),
      isFalse,
    );
  });

  void setupMarinesPhase(GameStateNotifier notifier, GameState state) {
    notifier.startMission(0, selectedDropZone: const GridPosition(2, 2));
  }

  test('squad turn advances directly to enemy phase', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier);
    setupMarinesPhase(notifier, container.read(gameStateProvider));

    notifier.endSquadTurn();
    final state = container.read(gameStateProvider);
    expect(state.activationPhase, ActivationPhase.marines);
    expect(state.activationRound, 2);
    expect(state.squad.every((marine) => marine.actionPoints == 2), isTrue);
    expect(state.squad.length, 4);
    expect(state.reserveSquad.length, 6);
  });

  test('enemy activation never leaves hostiles on marine tiles', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier);
    setupMarinesPhase(notifier, container.read(gameStateProvider));

    for (var i = 0; i < 2; i++) {
      notifier.endSquadTurn();
    }

    final state = container.read(gameStateProvider);
    final marineTiles = {
      for (final marine in state.squad)
        if (marine.hp > 0) marine.gridPosition,
    };

    expect(
      state.enemies
          .where((enemy) => enemy.hp > 0)
          .any((enemy) => marineTiles.contains(enemy.position)),
      isFalse,
    );
  });

  test('reserve marine can deploy with command points', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier);
    setupMarinesPhase(notifier, container.read(gameStateProvider));

    expect(container.read(gameStateProvider).squad.length, 4);
    expect(container.read(gameStateProvider).reserveSquad.length, 6);
    expect(notifier.deployReserveMarine(0), isTrue);

    final state = container.read(gameStateProvider);
    expect(state.squad.length, 5);
    expect(state.reserveSquad.length, 5);
    expect(state.commandPoints, 3);
  });

  test('reserve deployment lets player choose a highlighted drop tile', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier);
    setupMarinesPhase(notifier, container.read(gameStateProvider));

    notifier.selectReserveForDeployment(0);
    final planning = container.read(gameStateProvider);
    expect(planning.actionMode, ActionMode.deployReserve);
    expect(planning.reserveDropTiles, isNotEmpty);

    final dropTile = planning.reserveDropTiles.first;
    notifier.handleTileTap(dropTile);

    final state = container.read(gameStateProvider);
    expect(state.squad.length, 5);
    expect(state.reserveSquad.length, 5);
    expect(state.squad.last.gridPosition, dropTile);
    expect(state.selectedReserveIndex, isNull);
  });

  test('move command immediately changes active marine tile', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier);
    setupMarinesPhase(notifier, container.read(gameStateProvider));

    GridPosition? target;
    for (int i = 0; i < container.read(gameStateProvider).squad.length; i++) {
      notifier.selectMarine(i);
      notifier.setActionMode(ActionMode.move);
      final st = container.read(gameStateProvider);
      
      final reachable = st.reachableTiles;
      if (reachable.isNotEmpty) {
        target = reachable.first;
        expect(notifier.issueMove(target), isTrue);
        break;
      }
    }

    final state = container.read(gameStateProvider);
    expect(target, isNotNull);
    expect(state.selectedMarine!.gridPosition, target);
    expect(state.selectedMarine!.actionPoints, 1);
  });
}
