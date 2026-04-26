// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../game_state_provider.dart';

extension MissionLogic on GameStateNotifier {
  GameState maybeSpawnWave(GameState current) {
    final waveTime = 25.0 + current.wave * 28.0;
    if (current.elapsedSeconds < waveTime || current.wave >= 3) return current;
    final spawns = current.activeEnemyBases.isNotEmpty 
        ? current.activeEnemyBases.toList() 
        : current.map.enemySpawns;
        
    if (spawns.isEmpty) return current;

    final kind = current.missionIndex == 2
        ? EnemyKind.hereticAstartes
        : EnemyKind.orkBoy;
    final newEnemies = [
      ...current.enemies,
      for (var i = 0; i < 2 + current.wave; i++)
        enemyForKind(
          '${current.map.id}-wave-${current.wave}-$i',
          i == 0 && current.wave > 0 ? kind : EnemyKind.orkBoy,
          spawns[i % spawns.length],
          1.0 + current.wave * 0.1,
        ),
    ];
    return emit(
      current.copyWith(enemies: newEnemies, wave: current.wave + 1),
      'Enemy reinforcements entering the battlespace.',
    );
  }


  GameState refreshObjectives(GameState current) {
    final objectives = <MissionObjective>[];
    var beaconDestroyed = current.beaconDestroyed;
    for (final objective in current.objectives) {
      switch (objective.type) {
        case ObjectiveType.survive:
          final progress = objective.requiredValue <= 10
              ? min(objective.requiredValue, current.wave)
              : min(objective.requiredValue, current.elapsedSeconds.floor());
          objectives.add(
            objective.copyWith(
              progress: progress,
              completed: progress >= objective.requiredValue,
            ),
          );
        case ObjectiveType.eliminateAll:
          objectives.add(
            objective.copyWith(
              progress: current.enemies.isEmpty ? 1 : 0,
              completed: current.enemies.isEmpty,
            ),
          );
        case ObjectiveType.destroyBeacon:
          final marineOnObjective = current.squad.any(
            (marine) =>
                marine.hp > 0 &&
                current.map.objectiveTiles.contains(marine.gridPosition),
          );
          if (marineOnObjective) beaconDestroyed = true;
          objectives.add(
            objective.copyWith(
              progress: beaconDestroyed ? 1 : 0,
              completed: beaconDestroyed,
            ),
          );
        case ObjectiveType.destroyBase:
          final totalBases = current.map.enemyBaseTiles.length;
          final destroyed = totalBases - current.activeEnemyBases.length;
          objectives.add(
            objective.copyWith(
              progress: destroyed,
              completed: destroyed >= objective.requiredValue,
            ),
          );
        case ObjectiveType.extract:
          final extracted = current.squad.any(
            (marine) =>
                marine.hp > 0 &&
                current.map.extractionTiles.contains(marine.gridPosition),
          );
          objectives.add(
            objective.copyWith(
              progress: extracted ? 1 : 0,
              completed: extracted,
            ),
          );
      }
    }
    return current.copyWith(
      objectives: objectives,
      beaconDestroyed: beaconDestroyed,
    );
  }


  GameState checkMissionEnd(GameState current) {
    if (current.missionStatus != MissionStatus.active) return current;
    final alive = current.squad.any((marine) => marine.hp > 0);
    if (!alive) {
      return emit(
        current.copyWith(missionStatus: MissionStatus.defeat),
        'Mission failed. Squad incapacitated.',
      );
    }
    if (current.objectives.every((objective) => objective.completed)) {
      return emit(
        current.copyWith(
          missionStatus: MissionStatus.victory,
          requisitionPoints: current.requisitionPoints + current.map.rewardRP,
          speed: SimulationSpeed.paused,
        ),
        'Mission complete. ${current.map.rewardRP} RP secured.',
        important: true,
      );
    }
    return current;
  }


  GameState processBombs(GameState current) {
    var next = current;
    final newBombs = Map<GridPosition, int>.from(current.plantedBombs);
    final activeBases = Set<GridPosition>.from(current.activeEnemyBases);
    final toRemove = <GridPosition>[];

    for (final entry in newBombs.entries) {
      final pos = entry.key;
      final turnsLeft = entry.value - 1;

      if (turnsLeft <= 0) {
        // Explode
        toRemove.add(pos);
        activeBases.remove(pos);

        // Damage anything adjacent
        final affectedTiles = [pos, ...pos.neighbors()];

        // Destroy cover
        final newCover = Set<GridPosition>.from(next.map.coverTiles);
        newCover.removeAll(affectedTiles);
        next = next.copyWith(map: next.map.copyWith(coverTiles: newCover));

        // Damage marines
        final squad = List<Marine>.from(next.squad);
        for (var i = 0; i < squad.length; i++) {
          if (squad[i].hp > 0 &&
              affectedTiles.contains(squad[i].gridPosition)) {
            next = damageMarine(
              next,
              i,
              45,
              'Explosion caught ${squad[i].name}!',
              attackerPosition: pos,
            );
          }
        }

        // Damage enemies
        final enemies = List<EnemyUnit>.from(next.enemies);
        var enemyDefeatedCount = 0;
        var newRp = next.requisitionPoints;
        var newCp = next.commandPoints;
        for (var i = 0; i < enemies.length; i++) {
          if (enemies[i].hp > 0 &&
              affectedTiles.contains(enemies[i].position)) {
            final nextHp = enemies[i].hp - 45;
            enemies[i] = enemies[i].copyWith(hp: nextHp);
            if (nextHp <= 0) {
              enemyDefeatedCount++;
              newRp += enemies[i].rpReward;
              newCp = min(GameState.maxCommandPoints, newCp + 1);
            }
          }
        }

        next = emit(
          next.copyWith(
            squad: squad,
            enemies: enemies.where((e) => e.hp > 0).toList(),
            defeatedEnemies: next.defeatedEnemies + enemyDefeatedCount,
            requisitionPoints: newRp,
            commandPoints: newCp,
          ),
          'Bomb detonated at $pos! Base destroyed.',
          important: true,
        );
      } else {
        newBombs[pos] = turnsLeft;
      }
    }

    for (final pos in toRemove) {
      newBombs.remove(pos);
    }

    return next.copyWith(plantedBombs: newBombs, activeEnemyBases: activeBases);
  }




}
