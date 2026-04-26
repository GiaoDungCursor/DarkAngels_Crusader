// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../game_state_provider.dart';

extension CombatLogic on GameStateNotifier {




  GameState triggerOverwatch(GameState current, GridPosition enemyPosition) {
    final enemyIndex = current.enemyAt(enemyPosition);
    if (enemyIndex == -1) return current;
    for (var i = 0; i < current.squad.length; i++) {
      final marine = current.squad[i];
      if (!marine.isOverwatching || marine.hp <= 0) continue;
      if (marine.gridPosition.distanceTo(enemyPosition) <=
              GameState.rangedAttackRange &&
          GameStateNotifier._pathfinder.hasLineOfSight(
            map: current.map,
            from: marine.gridPosition,
            to: enemyPosition,
          )) {
        final enemies = List<EnemyUnit>.from(current.enemies);
        final enemy = enemies[enemyIndex];
        enemies[enemyIndex] = enemy.copyWith(hp: enemy.hp - 12);
        final squad = List<Marine>.from(current.squad);
        squad[i] = marine.copyWith(isOverwatching: false);
        return emit(
          current.copyWith(
            squad: squad,
            enemies: enemies.where((enemy) => enemy.hp > 0).toList(),
          ),
          '${marine.name} fires Overwatch.',
        );
      }
    }
    return current;
  }


  GameState triggerWaaagh(GameState current) {
    final spawns = current.activeEnemyBases.isNotEmpty 
        ? current.activeEnemyBases.toList() 
        : current.map.enemySpawns;
        
    final newEnemies = List<EnemyUnit>.from(current.enemies);
    
    // Buff existing orks
    for (var i = 0; i < newEnemies.length; i++) {
      if (newEnemies[i].kind == EnemyKind.orkBoy || newEnemies[i].kind == EnemyKind.orkWarboss) {
        newEnemies[i] = newEnemies[i].copyWith(
          speed: newEnemies[i].speed + 0.5,
          damage: newEnemies[i].damage + 5,
        );
      }
    }
    
    // Summon 3 new orks
    if (spawns.isNotEmpty) {
      for (var i = 0; i < 3; i++) {
        newEnemies.add(enemyForKind(
          'waaagh-spawn-$i',
          EnemyKind.orkBoy,
          spawns[i % spawns.length],
          1.5, // Extra strong
        ));
      }
    }

    return emit(
      current.copyWith(enemies: newEnemies),
      'WAAAGH! The Warboss summons reinforcements and buffs all Orks!',
      important: true,
    );
  }


}
