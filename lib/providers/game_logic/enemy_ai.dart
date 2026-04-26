// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../game_state_provider.dart';

extension EnemyAiLogic on GameStateNotifier {
  GameState runEnemyActivationRound(GameState current) {
    var next = current;
    final enemies = <EnemyUnit>[];
    for (final enemy in next.enemies) {
      if (enemy.hp <= 0) continue;
      final actingEnemy = moveEnemyOffMarineTile(next, enemy, enemies);
      final targetIndex = nearestMarineIndex(actingEnemy.position, next.squad);
      if (targetIndex == -1) {
        enemies.add(actingEnemy);
        continue;
      }
      final target = next.squad[targetIndex];
      if (actingEnemy.position != target.gridPosition &&
          actingEnemy.position.distanceTo(target.gridPosition) <=
              actingEnemy.attackRange &&
          GameStateNotifier._pathfinder.hasLineOfSight(
            map: next.map,
            from: actingEnemy.position,
            to: target.gridPosition,
          )) {
        if (actingEnemy.kind == EnemyKind.orkWarboss) {
          var hitCount = 0;
          for (var i = 0; i < next.squad.length; i++) {
            final marine = next.squad[i];
            if (marine.hp > 0 && actingEnemy.position.distanceTo(marine.gridPosition) <= 1.5) {
              next = damageMarine(
                next,
                i,
                actingEnemy.damage,
                '${actingEnemy.name} CLEAVES ${marine.name}!',
                attackerPosition: actingEnemy.position,
              );
              hitCount++;
            }
          }
          if (hitCount == 0) {
             next = damageMarine(
              next,
              targetIndex,
              actingEnemy.damage,
              '${actingEnemy.name} attacks ${target.name}.',
              attackerPosition: actingEnemy.position,
            );
          }
        } else {
          next = damageMarine(
            next,
            targetIndex,
            actingEnemy.damage,
            '${actingEnemy.name} attacks ${target.name}.',
            attackerPosition: actingEnemy.position,
          );
        }
        enemies.add(actingEnemy.copyWith(path: const [], commandProgress: 0));
      } else {
        final blockers = {...next.blockers}
          ..remove(actingEnemy.position)
          ..remove(target.gridPosition);
        final path = GameStateNotifier._pathfinder.findPath(
          map: next.map,
          start: actingEnemy.position,
          goal: target.gridPosition,
          blockers: blockers,
        );
        final stepPath = path
            .skip(1)
            .take(2)
            .where((step) => step != target.gridPosition)
            .toList();
        final rawDestination = stepPath.isEmpty
            ? actingEnemy.position
            : stepPath.last;
        final destination = safeEnemyDestination(
          current: next,
          enemy: actingEnemy,
          desired: rawDestination,
          focus: target.gridPosition,
          reservedEnemyTiles: {
            for (final resolvedEnemy in enemies) resolvedEnemy.position,
          },
        );
        final movedEnemy = actingEnemy.copyWith(
          position: destination,
          path: const [],
          commandProgress: 0,
        );
        final movedDistance = actingEnemy.position.distanceTo(
          movedEnemy.position,
        );
        var afterMove = next;
        for (final step in stepPath) {
          afterMove = triggerOverwatch(afterMove, step);
        }
        next = afterMove;
        final refreshedTarget = next.squad[targetIndex];
        if (movedDistance > 0 &&
            movedEnemy.position.distanceTo(refreshedTarget.gridPosition) <=
                movedEnemy.attackRange) {
          if (movedEnemy.kind == EnemyKind.orkWarboss) {
            // Cleave Attack: hit all adjacent marines
            var hitCount = 0;
            for (var i = 0; i < next.squad.length; i++) {
              final marine = next.squad[i];
              if (marine.hp > 0 && movedEnemy.position.distanceTo(marine.gridPosition) <= 1.5) {
                next = damageMarine(
                  next,
                  i,
                  movedEnemy.damage,
                  '${movedEnemy.name} CLEAVES ${marine.name}!',
                  attackerPosition: movedEnemy.position,
                );
                hitCount++;
              }
            }
            if (hitCount == 0) {
                next = damageMarine(
                  next,
                  targetIndex,
                  movedEnemy.damage,
                  '${movedEnemy.name} closes and strikes ${refreshedTarget.name}.',
                  attackerPosition: movedEnemy.position,
                );
            }
          } else {
            next = damageMarine(
              next,
              targetIndex,
              movedEnemy.damage,
              '${movedEnemy.name} closes and strikes ${refreshedTarget.name}.',
              attackerPosition: movedEnemy.position,
            );
          }
        }
        enemies.add(movedEnemy);
      }
    }
    return next.copyWith(enemies: enemies);
  }




  GridPosition safeEnemyDestination({
    required GameState current,
    required EnemyUnit enemy,
    required GridPosition desired,
    required GridPosition focus,
    required Set<GridPosition> reservedEnemyTiles,
  }) {
    if (canEnemyOccupy(
      current: current,
      tile: desired,
      enemy: enemy,
      reservedEnemyTiles: reservedEnemyTiles,
    )) {
      return desired;
    }

    final candidates =
        <GridPosition>{
          ...focus.neighbors(),
          ...desired.neighbors(),
          ...enemy.position.neighbors(),
        }.toList()..sort((a, b) {
          final byFocus = a.distanceTo(focus).compareTo(b.distanceTo(focus));
          if (byFocus != 0) return byFocus;
          return a
              .distanceTo(enemy.position)
              .compareTo(b.distanceTo(enemy.position));
        });

    for (final candidate in candidates) {
      if (canEnemyOccupy(
        current: current,
        tile: candidate,
        enemy: enemy,
        reservedEnemyTiles: reservedEnemyTiles,
      )) {
        return candidate;
      }
    }
    return enemy.position;
  }


  bool canEnemyOccupy({
    required GameState current,
    required GridPosition tile,
    required EnemyUnit enemy,
    required Set<GridPosition> reservedEnemyTiles,
  }) {
    if (!current.map.isWalkable(tile) || reservedEnemyTiles.contains(tile)) {
      return false;
    }
    for (final marine in current.squad) {
      if (marine.hp > 0 && marine.gridPosition == tile) return false;
    }
    for (final other in current.enemies) {
      if (other.hp > 0 && other.id != enemy.id && other.position == tile) {
        return false;
      }
    }
    return true;
  }


  int nearestMarineIndex(GridPosition from, List<Marine> squad) {
    var bestIndex = -1;
    var bestDistance = 999;
    for (var i = 0; i < squad.length; i++) {
      if (squad[i].hp <= 0) continue;
      final distance = from.distanceTo(squad[i].gridPosition);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }


}
