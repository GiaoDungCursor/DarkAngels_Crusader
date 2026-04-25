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
      start: const GridPosition(4, 4),
      goal: const GridPosition(8, 4),
      blockers: map.coverTiles,
    );

    expect(path, isNotEmpty);
    expect(path.any(map.coverTiles.contains), isFalse);
  });

  test('reachable tiles respect two tile movement and blockers', () {
    final map = campaignMaps.first;
    final reachable = const Pathfinder().reachable(
      map: map,
      start: const GridPosition(2, 7),
      maxSteps: 2,
      blockers: map.coverTiles,
    );

    expect(
      reachable.every((tile) => tile.distanceTo(const GridPosition(2, 7)) <= 2),
      isTrue,
    );
    expect(reachable.any(map.coverTiles.contains), isFalse);
  });

  test('line of sight is blocked by cover between shooter and target', () {
    final map = campaignMaps.first;
    expect(
      const Pathfinder().hasLineOfSight(
        map: map,
        from: const GridPosition(3, 7),
        to: const GridPosition(6, 7),
      ),
      isFalse,
    );
  });

  test('marine activations advance one character at a time', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier);

    expect(container.read(gameStateProvider).selectedMarineIndex, 0);
    notifier.endPlayerTurn();
    expect(container.read(gameStateProvider).selectedMarineIndex, 1);

    for (var i = 0; i < 3; i++) {
      notifier.endPlayerTurn();
    }

    final state = container.read(gameStateProvider);
    expect(state.activationPhase, ActivationPhase.marines);
    expect(state.activationRound, 2);
    expect(state.selectedMarineIndex, 0);
    expect(state.squad.length, 4);
    expect(state.reserveSquad.length, 6);
  });

  test('enemy activation never leaves hostiles on marine tiles', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier);

    for (var i = 0; i < 4; i++) {
      notifier.endPlayerTurn();
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

    final start = container
        .read(gameStateProvider)
        .selectedMarine!
        .gridPosition;
    final target = GridPosition(start.x, start.y - 1);
    expect(notifier.issueMove(target), isTrue);

    final state = container.read(gameStateProvider);
    expect(state.selectedMarine!.gridPosition, target);
    expect(state.selectedMarine!.hasMoved, isTrue);
  });
}
