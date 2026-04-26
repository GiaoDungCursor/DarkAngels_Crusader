// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../game_state_provider.dart';

extension PlayerActionsLogic on GameStateNotifier {
  bool issueMove(GridPosition target) {
    final marine = state.selectedMarine;
    if (marine == null ||
        marine.actionPoints == 0 ||
        state.missionStatus != MissionStatus.active ||
        state.activationPhase != ActivationPhase.marines) {
      state = emit(state, 'This battle-brother cannot move now.');
      return false;
    }
    final blockers = {...state.blockers}..remove(marine.gridPosition);
    final path = GameStateNotifier._pathfinder.findPath(
      map: state.map,
      start: marine.gridPosition,
      goal: target,
      blockers: blockers,
    );
    final distance = path.length - 1;
    final maxAllowed = marine.actionPoints >= 2 ? GameState.marineMoveRange : 2;
    if (distance <= 0 || distance > maxAllowed) {
      state = emit(
        state,
        'Move rejected: target out of reach.',
      );
      return false;
    }

    final apCost = distance > 2 ? 2 : 1;
    final squad = List<Marine>.from(state.squad);
    squad[state.selectedMarineIndex] = marine.copyWith(
      gridPosition: target,
      commandPath: const [],
      commandProgress: 0,
      actionPoints: max(0, marine.actionPoints - apCost),
      isOverwatching: false,
    );
    state = emit(
      state.copyWith(squad: squad, actionMode: ActionMode.move),
      '${marine.name} moving to grid $target.',
    );
    return true;
  }


  bool issueAttack(GridPosition target, {required bool melee}) {
    final marine = state.selectedMarine;
    if (marine == null ||
        marine.actionPoints == 0 ||
        state.missionStatus != MissionStatus.active ||
        state.activationPhase != ActivationPhase.marines) {
      state = emit(state, 'This battle-brother cannot attack now.');
      return false;
    }
    final enemyIndex = state.enemyAt(target);
    if (enemyIndex == -1) {
      state = emit(state, 'No hostile target at grid $target.');
      return false;
    }
    final range = melee
        ? GameState.meleeAttackRange
        : GameState.rangedAttackRange;
    if (marine.gridPosition.distanceTo(target) > range) {
      state = emit(
        state,
        'Target outside ${melee ? 'melee' : 'ranged'} range.',
      );
      return false;
    }
    if (!melee &&
        !GameStateNotifier._pathfinder.hasLineOfSight(
          map: state.map,
          from: marine.gridPosition,
          to: target,
        )) {
      state = emit(state, 'Line of sight blocked by cover.');
      return false;
    }

    damageEnemy(
      enemyIndex,
      melee ? 24 : marine.weapon.damage,
      '${marine.name} ${melee ? 'charges' : 'fires on'} ${state.enemies[enemyIndex].name}.',
      attackerPosition: marine.gridPosition,
      apCost: 1,
    );
    return true;
  }


  bool activateAbility(GridPosition target) {
    final marine = state.selectedMarine;
    if (marine == null || state.commandPoints <= 0) {
      state = emit(state, 'No command points available.');
      return false;
    }

    final role = marine.role.toLowerCase();
    if (role.contains('apothecary')) {
      final squad = List<Marine>.from(state.squad);
      final woundedIndex = squad.indexWhere(
        (unit) => unit.hp > 0 && unit.hp < unit.maxHp,
      );
      if (woundedIndex == -1) {
        state = emit(state, 'No wounded battle-brother requires aid.');
        return false;
      }
      final wounded = squad[woundedIndex];
      squad[woundedIndex] = wounded.copyWith(
        hp: min(wounded.maxHp, wounded.hp + 28),
      );
      squad[state.selectedMarineIndex] = marine.copyWith(
        actionPoints: max(0, marine.actionPoints - 1),
      );
      state = emit(
        state.copyWith(commandPoints: state.commandPoints - 1, squad: squad),
        '${marine.name} restores ${wounded.name}.',
      );
      return true;
    }

    if (role.contains('flamer')) {
      var hit = false;
      for (var i = 0; i < state.enemies.length; i++) {
        if (state.enemies[i].position.distanceTo(target) <= 1) {
          damageEnemy(
            i,
            20,
            '${marine.name} sweeps the corridor with holy flame.',
            attackerPosition: marine.gridPosition,
          );
          hit = true;
        }
      }
      if (hit) {
        final squad = List<Marine>.from(state.squad);
        squad[state.selectedMarineIndex] = marine.copyWith(
          actionPoints: max(0, marine.actionPoints - 1),
        );
        state = state.copyWith(commandPoints: max(0, state.commandPoints - 1), squad: squad);
        return true;
      }
    }

    final enemyIndex = state.enemyAt(target);
    if (enemyIndex == -1) {
      state = emit(state, 'Select an enemy tile for this ability.');
      return false;
    }
    final cost = role.contains('commander') ? 2 : 1;
    if (state.commandPoints < cost) {
      state = emit(state, 'Insufficient command points.');
      return false;
    }
    final damage = role.contains('plasma')
        ? 36
        : role.contains('commander')
        ? 42
        : 24;
    damageEnemy(
      enemyIndex,
      damage,
      '${marine.name} executes a class ability.',
      attackerPosition: marine.gridPosition,
      apCost: 1,
    );
    state = state.copyWith(commandPoints: state.commandPoints - cost);
    return true;
  }


  bool plantBomb(GridPosition target) {
    final marine = state.selectedMarine;
    if (marine == null || marine.actionPoints == 0) return false;
    if (!state.activeEnemyBases.contains(target) ||
        state.plantedBombs.containsKey(target)) {
      state = emit(state, 'Cannot plant bomb here.');
      return false;
    }

    // Cost 1 CP to plant bomb
    if (state.commandPoints < 1) {
      state = emit(state, 'Need 1 CP to plant bomb.');
      return false;
    }

    final newBombs = Map<GridPosition, int>.from(state.plantedBombs);
    newBombs[target] = 3; // Explodes in 3 rounds

    final squad = List<Marine>.from(state.squad);
    squad[state.selectedMarineIndex] = marine.copyWith(
      actionPoints: max(0, marine.actionPoints - 1),
      isOverwatching: false,
    );

    state = emit(
      state.copyWith(
        plantedBombs: newBombs,
        squad: squad,
        commandPoints: state.commandPoints - 1,
      ),
      '${marine.name} planted a bomb. Detonation in 3 rounds.',
      important: true,
    );
    return true;
  }


  bool deployReserveMarineAt(int reserveIndex, GridPosition tile) {
    if (reserveIndex < 0 || reserveIndex >= state.reserveSquad.length) {
      return false;
    }
    const cost = 2;
    if (state.missionStatus != MissionStatus.active) {
      state = emit(state, 'Mission already resolved.');
      return false;
    }
    if (state.commandPoints < cost) {
      state = emit(state, 'Need $cost CP to deploy reinforcement.');
      return false;
    }
    if (!state.freeReserveDropTiles.contains(tile)) {
      state = emit(state, 'Drop rejected: choose a highlighted drop tile.');
      return false;
    }

    final reserve = List<Marine>.from(state.reserveSquad);
    final reinforcement = reserve.removeAt(reserveIndex);
    final deployed = reinforcement.copyWith(
      gridPosition: tile,
      actionPoints: 0,
      isOverwatching: false,
    );

    var nextState = state.copyWith(
      squad: [...state.squad, deployed],
      reserveSquad: reserve,
      commandPoints: state.commandPoints - cost,
      actionMode: ActionMode.move,
      clearSelectedReserve: true,
    );

    // Drop Pod Impact Damage
    final affectedTiles = tile.neighbors();
    final enemies = List<EnemyUnit>.from(nextState.enemies);
    var enemyDefeatedCount = 0;
    var newRp = nextState.requisitionPoints;
    var newCp = nextState.commandPoints;

    for (var i = 0; i < enemies.length; i++) {
      if (enemies[i].hp > 0 && affectedTiles.contains(enemies[i].position)) {
        final nextHp = enemies[i].hp - 20; // 20 impact damage
        enemies[i] = enemies[i].copyWith(hp: nextHp);
        if (nextHp <= 0) {
          enemyDefeatedCount++;
          newRp += enemies[i].rpReward;
          newCp = min(GameState.maxCommandPoints, newCp + 1);
        }
      }
    }

    state = emit(
      nextState.copyWith(
        enemies: enemies.where((e) => e.hp > 0).toList(),
        defeatedEnemies: nextState.defeatedEnemies + enemyDefeatedCount,
        requisitionPoints: newRp,
        commandPoints: newCp,
      ),
      '${reinforcement.name} deployed to grid $tile. Drop pod impacts nearby enemies!',
      important: true,
    );
    return true;
  }


  void deployBeacon(GridPosition tile) {
    if (!state.deployBeaconTiles.contains(tile)) return;
    final marine = state.selectedMarine!;
    
    final newBeacons = Set<GridPosition>.from(state.activeDropBeacons)..add(tile);
    final squad = List<Marine>.from(state.squad);
    squad[state.selectedMarineIndex] = marine.copyWith(
      actionPoints: max(0, marine.actionPoints - 1),
    );
    
    state = emit(
      state.copyWith(
        activeDropBeacons: newBeacons,
        squad: squad,
        actionMode: ActionMode.move,
      ),
      'Drop Beacon deployed at $tile.',
    );
  }


}
