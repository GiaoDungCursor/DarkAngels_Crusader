import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enemy_unit.dart';
import '../models/equipment.dart';
import '../models/grid_position.dart';
import '../models/marine.dart';
import '../models/tactical_map.dart';
import '../services/pathfinder.dart';
import 'settings_provider.dart';

enum ActionMode {
  move,
  shoot,
  melee,
  ability,
  overwatch,
  deployReserve,
  plantBomb,
  deployBeacon,
}

enum SimulationSpeed { paused, slow, normal }

enum ThreatLevel { safe, warning, danger }

enum ActivationPhase { marines, enemies }

enum MissionStatus { active, victory, defeat }

class CombatEvent {
  const CombatEvent(this.message, {this.important = false});

  final String message;
  final bool important;
}

class GameState {
  static const marineMoveRange = 2;
  static const rangedAttackRange = 3;
  static const meleeAttackRange = 1;
  static const maxCommandPoints = 10;

  final int commandPoints;
  final int requisitionPoints;
  final int missionIndex;
  final TacticalMap map;
  final List<MissionObjective> objectives;
  final List<Marine> squad;
  final List<Marine> reserveSquad;
  final List<EnemyUnit> enemies;
  final int selectedMarineIndex;
  final int? selectedReserveIndex;
  final ActionMode? actionMode;
  final ActivationPhase activationPhase;
  final int activeEnemyIndex;
  final int activationRound;
  final SimulationSpeed speed;
  final MissionStatus missionStatus;
  final double elapsedSeconds;
  final double cpChargeSeconds;
  final double aiThinkSeconds;
  final int wave;
  final int defeatedEnemies;
  final bool beaconDestroyed;
  final Set<GridPosition> activeEnemyBases;
  final Map<GridPosition, int> plantedBombs;
  final Set<GridPosition> activeDropBeacons;
  final int revision;
  final String statusMessage;
  final List<CombatEvent> events;

  GameState({
    required this.commandPoints,
    required this.requisitionPoints,
    required this.missionIndex,
    required this.map,
    required this.objectives,
    required this.squad,
    required this.reserveSquad,
    required this.enemies,
    required this.selectedMarineIndex,
    required this.selectedReserveIndex,
    required this.actionMode,
    required this.activationPhase,
    required this.activeEnemyIndex,
    required this.activationRound,
    required this.speed,
    required this.missionStatus,
    required this.elapsedSeconds,
    required this.cpChargeSeconds,
    required this.aiThinkSeconds,
    required this.wave,
    required this.defeatedEnemies,
    required this.beaconDestroyed,
    required this.activeEnemyBases,
    required this.plantedBombs,
    required this.activeDropBeacons,
    required this.revision,
    required this.statusMessage,
    required this.events,
  });

  int get columns => map.width;
  int get rows => map.height;
  Set<GridPosition> get coverTiles => map.coverTiles;
  bool get isPlayerPlanning => missionStatus == MissionStatus.active;
  bool get isMarinePhase =>
      missionStatus == MissionStatus.active &&
      activationPhase == ActivationPhase.marines;

  Marine? get selectedMarine {
    if (selectedMarineIndex < 0 || selectedMarineIndex >= squad.length) {
      return null;
    }
    return squad[selectedMarineIndex];
  }

  double get squadIntegrity {
    final total = squad.fold<int>(0, (sum, marine) => sum + marine.maxHp);
    final hp = squad.fold<int>(0, (sum, marine) => sum + max(0, marine.hp));
    return total == 0 ? 0 : hp / total;
  }

  Set<GridPosition> get blockers {
    return {
      ...map.coverTiles,
      for (final enemy in enemies)
        if (enemy.hp > 0) enemy.position,
      for (final marine in squad)
        if (marine.hp > 0) marine.gridPosition,
    };
  }

  Set<GridPosition> get reachableTiles {
    final marine = selectedMarine;
    if (marine == null || !isMarinePhase || marine.hasMoved || marine.hp <= 0) {
      return {};
    }
    return const Pathfinder().reachable(
      map: map,
      start: marine.gridPosition,
      maxSteps: marineMoveRange,
      blockers: blockers..remove(marine.gridPosition),
    );
  }

  Set<GridPosition> get shootableTiles {
    final marine = selectedMarine;
    if (marine == null ||
        !isMarinePhase ||
        marine.hasAttacked ||
        marine.hp <= 0) {
      return {};
    }
    return enemies
        .where(
          (enemy) =>
              enemy.hp > 0 &&
              marine.gridPosition.distanceTo(enemy.position) <=
                  rangedAttackRange &&
              const Pathfinder().hasLineOfSight(
                map: map,
                from: marine.gridPosition,
                to: enemy.position,
              ),
        )
        .map((enemy) => enemy.position)
        .toSet();
  }

  Set<GridPosition> get meleeTiles {
    final marine = selectedMarine;
    if (marine == null ||
        !isMarinePhase ||
        marine.hasAttacked ||
        marine.hp <= 0) {
      return {};
    }
    return enemies
        .where(
          (enemy) =>
              enemy.hp > 0 &&
              marine.gridPosition.distanceTo(enemy.position) <=
                  meleeAttackRange,
        )
        .map((enemy) => enemy.position)
        .toSet();
  }

  Set<GridPosition> get plantBombTiles {
    final marine = selectedMarine;
    if (marine == null ||
        !isMarinePhase ||
        marine.hasAttacked ||
        marine.hp <= 0) {
      return {};
    }
    return activeEnemyBases.where((base) {
      return base.distanceTo(marine.gridPosition) <= 1 &&
          !plantedBombs.containsKey(base);
    }).toSet();
  }

  Set<GridPosition> get objectiveHighlights {
    return {...map.objectiveTiles, ...map.extractionTiles};
  }

  Set<GridPosition> get reserveDropTiles {
    if (!isMarinePhase ||
        selectedReserveIndex == null ||
        selectedReserveIndex! < 0 ||
        selectedReserveIndex! >= reserveSquad.length ||
        commandPoints < 2) {
      return {};
    }
    return freeReserveDropTiles;
  }

  Set<GridPosition> get freeReserveDropTiles {
    final occupied = {
      for (final marine in squad)
        if (marine.hp > 0) marine.gridPosition,
      for (final enemy in enemies)
        if (enemy.hp > 0) enemy.position,
    };
    final validTiles = {...map.marineSpawns, ...activeDropBeacons};
    return validTiles
        .where((tile) => map.isWalkable(tile) && !occupied.contains(tile))
        .toSet();
  }

  Set<GridPosition> get highlightedTiles {
    return switch (actionMode) {
      ActionMode.move => reachableTiles,
      ActionMode.shoot => shootableTiles,
      ActionMode.melee => meleeTiles,
      ActionMode.ability => shootableTiles.union(reachableTiles),
      ActionMode.overwatch => shootableTiles,
      ActionMode.deployReserve => reserveDropTiles,
      ActionMode.plantBomb => plantBombTiles,
      ActionMode.deployBeacon => deployBeaconTiles,
      null => {},
    };
  }

  Set<GridPosition> get deployBeaconTiles {
    final marine = selectedMarine;
    if (marine == null || !isMarinePhase || marine.hasAttacked || marine.hp <= 0) {
      return {};
    }
    final role = marine.role.toLowerCase();
    if (!role.contains('commander') && !role.contains('techmarine')) {
      return {};
    }
    // Can deploy beacon within 2 tiles
    return const Pathfinder().reachable(
      map: map,
      start: marine.gridPosition,
      maxSteps: 2,
      blockers: blockers,
    ).toSet();
  }

  Marine? getTargetFor(EnemyUnit enemy) {
    var bestMarine = -1;
    var bestDistance = 999.0;
    for (var i = 0; i < squad.length; i++) {
      if (squad[i].hp <= 0) continue;
      final distance = enemy.position.distanceTo(squad[i].gridPosition);
      if (distance < bestDistance) {
        bestDistance = distance.toDouble();
        bestMarine = i;
      }
    }
    return bestMarine != -1 ? squad[bestMarine] : null;
  }

  Map<GridPosition, ThreatLevel> get movementThreats {
    final threats = <GridPosition, ThreatLevel>{};
    if (actionMode != ActionMode.move) return threats;

    final pathfinder = const Pathfinder();
    for (final tile in reachableTiles) {
      var level = ThreatLevel.safe;
      for (final enemy in enemies) {
        if (enemy.hp <= 0) continue;
        
        final dist = tile.distanceTo(enemy.position);
        
        // Melee danger
        if (dist <= 1.5) {
          level = ThreatLevel.danger;
          break; // Max threat reached
        }
        
        // Ranged danger
        if (dist <= enemy.attackRange && pathfinder.hasLineOfSight(map: map, from: enemy.position, to: tile)) {
          if (hasDirectionalCover(target: tile, attacker: enemy.position, map: map)) {
            if (level == ThreatLevel.safe) {
              level = ThreatLevel.warning;
            }
          } else {
            level = ThreatLevel.danger;
            break; // Max threat reached
          }
        }
      }
      threats[tile] = level;
    }
    return threats;
  }

  static bool hasDirectionalCover({
    required GridPosition target,
    required GridPosition attacker,
    required TacticalMap map,
  }) {
    for (final cover in map.coverTiles) {
      if (cover.distanceTo(target) <= 1.5) {
        if (cover.distanceTo(attacker) < target.distanceTo(attacker)) {
          return true;
        }
      }
    }
    return false;
  }

  Set<GridPosition> get shieldedMarines {
    final shielded = <GridPosition>{};
    final pathfinder = const Pathfinder();
    for (final marine in squad) {
      if (marine.hp <= 0) continue;
      for (final enemy in enemies) {
        if (enemy.hp <= 0) continue;
        if (marine.gridPosition.distanceTo(enemy.position) <= enemy.attackRange &&
            pathfinder.hasLineOfSight(map: map, from: enemy.position, to: marine.gridPosition)) {
          if (hasDirectionalCover(target: marine.gridPosition, attacker: enemy.position, map: map)) {
            shielded.add(marine.gridPosition);
            break;
          }
        }
      }
    }
    return shielded;
  }

  bool isInside(GridPosition tile) => map.isInside(tile);

  int marineAt(GridPosition tile) {
    return squad.indexWhere(
      (marine) => marine.hp > 0 && marine.gridPosition == tile,
    );
  }

  int enemyAt(GridPosition tile) {
    return enemies.indexWhere(
      (enemy) => enemy.hp > 0 && enemy.position == tile,
    );
  }

  GameState copyWith({
    int? commandPoints,
    int? requisitionPoints,
    int? missionIndex,
    TacticalMap? map,
    List<MissionObjective>? objectives,
    List<Marine>? squad,
    List<Marine>? reserveSquad,
    List<EnemyUnit>? enemies,
    int? selectedMarineIndex,
    int? selectedReserveIndex,
    bool clearSelectedReserve = false,
    ActionMode? actionMode,
    bool clearActionMode = false,
    ActivationPhase? activationPhase,
    int? activeEnemyIndex,
    int? activationRound,
    SimulationSpeed? speed,
    MissionStatus? missionStatus,
    double? elapsedSeconds,
    double? cpChargeSeconds,
    double? aiThinkSeconds,
    int? wave,
    int? defeatedEnemies,
    bool? beaconDestroyed,
    Set<GridPosition>? activeEnemyBases,
    Map<GridPosition, int>? plantedBombs,
    Set<GridPosition>? activeDropBeacons,
    int? revision,
    String? statusMessage,
    List<CombatEvent>? events,
  }) {
    return GameState(
      commandPoints: commandPoints ?? this.commandPoints,
      requisitionPoints: requisitionPoints ?? this.requisitionPoints,
      missionIndex: missionIndex ?? this.missionIndex,
      map: map ?? this.map,
      objectives: objectives ?? this.objectives,
      squad: squad ?? this.squad,
      reserveSquad: reserveSquad ?? this.reserveSquad,
      enemies: enemies ?? this.enemies,
      selectedMarineIndex: selectedMarineIndex ?? this.selectedMarineIndex,
      selectedReserveIndex: clearSelectedReserve
          ? null
          : selectedReserveIndex ?? this.selectedReserveIndex,
      actionMode: clearActionMode ? null : actionMode ?? this.actionMode,
      activationPhase: activationPhase ?? this.activationPhase,
      activeEnemyIndex: activeEnemyIndex ?? this.activeEnemyIndex,
      activationRound: activationRound ?? this.activationRound,
      speed: speed ?? this.speed,
      missionStatus: missionStatus ?? this.missionStatus,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      cpChargeSeconds: cpChargeSeconds ?? this.cpChargeSeconds,
      aiThinkSeconds: aiThinkSeconds ?? this.aiThinkSeconds,
      wave: wave ?? this.wave,
      defeatedEnemies: defeatedEnemies ?? this.defeatedEnemies,
      beaconDestroyed: beaconDestroyed ?? this.beaconDestroyed,
      activeEnemyBases: activeEnemyBases ?? this.activeEnemyBases,
      plantedBombs: plantedBombs ?? this.plantedBombs,
      activeDropBeacons: activeDropBeacons ?? this.activeDropBeacons,
      revision: revision ?? this.revision + 1,
      statusMessage: statusMessage ?? this.statusMessage,
      events: events ?? this.events,
    );
  }
}

class GameStateNotifier extends Notifier<GameState> {
  static const _pathfinder = Pathfinder();

  @override
  GameState build() {
    return _newMissionState(0, requisitionPoints: 0);
  }

  void startMission(int index) {
    final safeIndex = index.clamp(0, campaignMaps.length - 1);
    state = _newMissionState(
      safeIndex,
      requisitionPoints: state.requisitionPoints,
      event: 'Mission loaded: ${campaignMaps[safeIndex].name}.',
    );
  }

  void selectUnit(int index) => selectMarine(index);

  void selectMarine(int index) {
    if (index < 0 || index >= state.squad.length) return;
    if (state.squad[index].hp <= 0) return;
    if (state.missionStatus != MissionStatus.active) {
      state = _emit(state, 'Mission already resolved.');
      return;
    }
    if (state.activationPhase != ActivationPhase.marines) {
      state = _emit(state, 'Enemy activation in progress.');
      return;
    }
    if (index != state.selectedMarineIndex) {
      state = _emit(
        state,
        '${state.squad[index].name} is waiting for their activation.',
      );
      return;
    }
    state = _emit(
      state.copyWith(
        selectedMarineIndex: index,
        actionMode: ActionMode.move,
        clearSelectedReserve: true,
      ),
      '${state.squad[index].name} selected.',
    );
  }

  void setActionMode(ActionMode mode) {
    if (state.missionStatus != MissionStatus.active) {
      state = _emit(state, 'Mission already resolved.');
      return;
    }
    state = _emit(
      state.copyWith(
        actionMode: mode,
        clearSelectedReserve: mode != ActionMode.deployReserve,
      ),
      'Mode: ${_modeName(mode)}.',
    );
  }

  void togglePause() {
    final next = state.speed == SimulationSpeed.paused
        ? SimulationSpeed.normal
        : SimulationSpeed.paused;
    state = _emit(
      state.copyWith(speed: next),
      next == SimulationSpeed.paused
          ? 'Tactical pause engaged.'
          : 'Realtime execution resumed.',
    );
  }

  void setSpeed(SimulationSpeed speed) {
    state = _emit(
      state.copyWith(speed: speed),
      speed == SimulationSpeed.slow
          ? 'Slow tactical execution.'
          : speed == SimulationSpeed.paused
          ? 'Tactical pause engaged.'
          : 'Realtime execution resumed.',
    );
  }

  void handleTileTap(GridPosition tile) {
    if (state.missionStatus != MissionStatus.active) {
      state = _emit(state, 'Mission already resolved.');
      return;
    }
    if (state.activationPhase != ActivationPhase.marines) {
      state = _emit(state, 'Wait for the enemy phase to resolve.');
      return;
    }
    switch (state.actionMode) {
      case ActionMode.move:
        issueMove(tile);
      case ActionMode.shoot:
        issueAttack(tile, melee: false);
      case ActionMode.melee:
        issueAttack(tile, melee: true);
      case ActionMode.ability:
        activateAbility(tile);
      case ActionMode.overwatch:
        setOverwatch();
      case ActionMode.deployReserve:
        final reserveIndex = state.selectedReserveIndex;
        if (reserveIndex == null) {
          state = _emit(state, 'Select a reserve marine first.');
        } else {
          deployReserveMarineAt(reserveIndex, tile);
        }
      case ActionMode.plantBomb:
        plantBomb(tile);
      case ActionMode.deployBeacon:
        deployBeacon(tile);
      case null:
        state = _emit(state, 'Choose a command mode first.');
    }
  }

  bool issueMove(GridPosition target) {
    final marine = state.selectedMarine;
    if (marine == null ||
        marine.hasMoved ||
        state.missionStatus != MissionStatus.active ||
        state.activationPhase != ActivationPhase.marines) {
      state = _emit(state, 'This battle-brother cannot move now.');
      return false;
    }
    final blockers = {...state.blockers}..remove(marine.gridPosition);
    final path = _pathfinder.findPath(
      map: state.map,
      start: marine.gridPosition,
      goal: target,
      blockers: blockers,
    );
    if (path.length < 2 || path.length - 1 > GameState.marineMoveRange) {
      state = _emit(
        state,
        'Move rejected: target must be within 2 clear tiles.',
      );
      return false;
    }

    final squad = List<Marine>.from(state.squad);
    squad[state.selectedMarineIndex] = marine.copyWith(
      gridPosition: target,
      commandPath: const [],
      commandProgress: 0,
      hasMoved: true,
      isOverwatching: false,
    );
    state = _emit(
      state.copyWith(squad: squad, actionMode: ActionMode.shoot),
      '${marine.name} moving to grid $target.',
    );
    return true;
  }

  bool issueAttack(GridPosition target, {required bool melee}) {
    final marine = state.selectedMarine;
    if (marine == null ||
        marine.hasAttacked ||
        state.missionStatus != MissionStatus.active ||
        state.activationPhase != ActivationPhase.marines) {
      state = _emit(state, 'This battle-brother cannot attack now.');
      return false;
    }
    final enemyIndex = state.enemyAt(target);
    if (enemyIndex == -1) {
      state = _emit(state, 'No hostile target at grid $target.');
      return false;
    }
    final range = melee
        ? GameState.meleeAttackRange
        : GameState.rangedAttackRange;
    if (marine.gridPosition.distanceTo(target) > range) {
      state = _emit(
        state,
        'Target outside ${melee ? 'melee' : 'ranged'} range.',
      );
      return false;
    }
    if (!melee &&
        !_pathfinder.hasLineOfSight(
          map: state.map,
          from: marine.gridPosition,
          to: target,
        )) {
      state = _emit(state, 'Line of sight blocked by cover.');
      return false;
    }

    _damageEnemy(
      enemyIndex,
      melee ? 24 : marine.weapon.damage,
      '${marine.name} ${melee ? 'charges' : 'fires on'} ${state.enemies[enemyIndex].name}.',
      attackerPosition: marine.gridPosition,
      markAttackerSpent: true,
    );
    return true;
  }

  bool activateAbility(GridPosition target) {
    final marine = state.selectedMarine;
    if (marine == null || state.commandPoints <= 0) {
      state = _emit(state, 'No command points available.');
      return false;
    }

    final role = marine.role.toLowerCase();
    if (role.contains('apothecary')) {
      final squad = List<Marine>.from(state.squad);
      final woundedIndex = squad.indexWhere(
        (unit) => unit.hp > 0 && unit.hp < unit.maxHp,
      );
      if (woundedIndex == -1) {
        state = _emit(state, 'No wounded battle-brother requires aid.');
        return false;
      }
      final wounded = squad[woundedIndex];
      squad[woundedIndex] = wounded.copyWith(
        hp: min(wounded.maxHp, wounded.hp + 28),
      );
      state = _emit(
        state.copyWith(commandPoints: state.commandPoints - 1, squad: squad),
        '${marine.name} restores ${wounded.name}.',
      );
      return true;
    }

    if (role.contains('flamer')) {
      var hit = false;
      for (var i = 0; i < state.enemies.length; i++) {
        if (state.enemies[i].position.distanceTo(target) <= 1) {
          _damageEnemy(
            i,
            20,
            '${marine.name} sweeps the corridor with holy flame.',
            attackerPosition: marine.gridPosition,
          );
          hit = true;
        }
      }
      if (hit) {
        state = state.copyWith(commandPoints: max(0, state.commandPoints - 1));
        return true;
      }
    }

    final enemyIndex = state.enemyAt(target);
    if (enemyIndex == -1) {
      state = _emit(state, 'Select an enemy tile for this ability.');
      return false;
    }
    final cost = role.contains('commander') ? 2 : 1;
    if (state.commandPoints < cost) {
      state = _emit(state, 'Insufficient command points.');
      return false;
    }
    final damage = role.contains('plasma')
        ? 36
        : role.contains('commander')
        ? 42
        : 24;
    _damageEnemy(
      enemyIndex,
      damage,
      '${marine.name} executes a class ability.',
      attackerPosition: marine.gridPosition,
    );
    state = state.copyWith(commandPoints: state.commandPoints - cost);
    return true;
  }

  void setOverwatch() {
    final marine = state.selectedMarine;
    if (marine == null || marine.hasAttacked) return;
    final squad = List<Marine>.from(state.squad);
    squad[state.selectedMarineIndex] = marine.copyWith(
      hasAttacked: true,
      isOverwatching: true,
    );
    state = _emit(
      state.copyWith(squad: squad),
      '${marine.name} enters Overwatch.',
    );
  }

  bool plantBomb(GridPosition target) {
    final marine = state.selectedMarine;
    if (marine == null || marine.hasAttacked) return false;
    if (!state.activeEnemyBases.contains(target) ||
        state.plantedBombs.containsKey(target)) {
      state = _emit(state, 'Cannot plant bomb here.');
      return false;
    }

    // Cost 1 CP to plant bomb
    if (state.commandPoints < 1) {
      state = _emit(state, 'Need 1 CP to plant bomb.');
      return false;
    }

    final newBombs = Map<GridPosition, int>.from(state.plantedBombs);
    newBombs[target] = 3; // Explodes in 3 rounds

    final squad = List<Marine>.from(state.squad);
    squad[state.selectedMarineIndex] = marine.copyWith(
      hasAttacked: true,
      isOverwatching: false,
    );

    state = _emit(
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

  void tickSimulation(double rawDt) {
    if (state.missionStatus != MissionStatus.active) return;
    state = _checkMissionEnd(_refreshObjectives(state));
  }

  void completeMission() {
    state = _checkMissionEnd(
      state.copyWith(missionStatus: MissionStatus.victory),
    );
  }

  void endPlayerTurn() {
    if (state.missionStatus != MissionStatus.active) return;
    if (state.activationPhase != ActivationPhase.marines) return;

    final squad = List<Marine>.from(state.squad);
    final active = state.selectedMarine;
    if (active != null) {
      squad[state.selectedMarineIndex] = active.copyWith(
        hasMoved: true,
        hasAttacked: true,
        isOverwatching: false,
      );
    }

    final nextMarine = _nextReadyMarineIndex(
      squad,
      state.selectedMarineIndex + 1,
    );
    if (nextMarine != -1) {
      state = _emit(
        state.copyWith(
          squad: squad,
          selectedMarineIndex: nextMarine,
          actionMode: ActionMode.move,
        ),
        '${squad[nextMarine].name} is active.',
      );
      return;
    }

    // Process bomb timers before enemy activation
    var nextState = _processBombs(
      state.copyWith(
        squad: squad,
        activationPhase: ActivationPhase.enemies,
        activeEnemyIndex: 0,
        clearActionMode: true,
        elapsedSeconds: state.elapsedSeconds + 10,
      ),
    );

    var afterEnemies = _runEnemyActivationRound(nextState);
    afterEnemies = _maybeSpawnWave(afterEnemies);
    afterEnemies = _refreshObjectives(afterEnemies);
    afterEnemies = _checkMissionEnd(afterEnemies);
    if (afterEnemies.missionStatus != MissionStatus.active) {
      state = afterEnemies.copyWith(
        activationPhase: ActivationPhase.marines,
        clearActionMode: true,
        clearSelectedReserve: true,
      );
      return;
    }
    final resetSquad = [
      for (final marine in afterEnemies.squad)
        marine.copyWith(
          hasMoved: false,
          hasAttacked: false,
          isOverwatching: false,
        ),
    ];
    final firstMarine = _nextReadyMarineIndex(resetSquad, 0);
    state = _emit(
      afterEnemies.copyWith(
        squad: resetSquad,
        selectedMarineIndex: max(0, firstMarine),
        activationPhase: ActivationPhase.marines,
        activeEnemyIndex: 0,
        activationRound: afterEnemies.activationRound + 1,
        actionMode: ActionMode.move,
        clearSelectedReserve: true,
        commandPoints: min(10, afterEnemies.commandPoints + 1),
      ),
      firstMarine == -1
          ? 'No battle-brothers remain standing.'
          : 'Enemy phase complete. ${resetSquad[firstMarine].name} is active.',
    );
  }

  GameState _processBombs(GameState current) {
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
            next = _damageMarine(
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

        next = _emit(
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

  void addRP(int amount) {
    state = state.copyWith(requisitionPoints: state.requisitionPoints + amount);
  }

  void useCP(int amount) {
    if (state.commandPoints >= amount) {
      state = state.copyWith(commandPoints: state.commandPoints - amount);
    }
  }

  void addCP(int amount) {
    state = state.copyWith(
      commandPoints: min(10, state.commandPoints + amount),
    );
  }

  bool deployReserveMarine(int reserveIndex) {
    if (reserveIndex < 0 || reserveIndex >= state.reserveSquad.length) {
      return false;
    }
    final dropTiles = state.freeReserveDropTiles;
    if (dropTiles.isEmpty) {
      state = _emit(state, 'No valid drop zone available.');
      return false;
    }
    return deployReserveMarineAt(reserveIndex, dropTiles.first);
  }

  void selectReserveForDeployment(int reserveIndex) {
    if (reserveIndex < 0 || reserveIndex >= state.reserveSquad.length) {
      return;
    }
    const cost = 2;
    if (state.missionStatus != MissionStatus.active) {
      state = _emit(state, 'Mission already resolved.');
      return;
    }
    if (state.commandPoints < cost) {
      state = _emit(state, 'Need $cost CP to deploy reinforcement.');
      return;
    }
    if (state.freeReserveDropTiles.isEmpty) {
      state = _emit(state, 'No valid drop zone available.');
      return;
    }

    state = _emit(
      state.copyWith(
        selectedReserveIndex: reserveIndex,
        actionMode: ActionMode.deployReserve,
      ),
      'Select a green drop tile for ${state.reserveSquad[reserveIndex].name}.',
      important: true,
    );
  }

  void deployBeacon(GridPosition tile) {
    if (!state.deployBeaconTiles.contains(tile)) return;
    final marine = state.selectedMarine!;
    
    final newBeacons = Set<GridPosition>.from(state.activeDropBeacons)..add(tile);
    final squad = List<Marine>.from(state.squad);
    squad[state.selectedMarineIndex] = marine.copyWith(hasAttacked: true);
    
    state = _emit(
      state.copyWith(
        activeDropBeacons: newBeacons,
        squad: squad,
        actionMode: ActionMode.move,
      ),
      'Drop Beacon deployed at $tile.',
    );
  }

  bool deployReserveMarineAt(int reserveIndex, GridPosition tile) {
    if (reserveIndex < 0 || reserveIndex >= state.reserveSquad.length) {
      return false;
    }
    const cost = 2;
    if (state.missionStatus != MissionStatus.active) {
      state = _emit(state, 'Mission already resolved.');
      return false;
    }
    if (state.commandPoints < cost) {
      state = _emit(state, 'Need $cost CP to deploy reinforcement.');
      return false;
    }
    if (!state.freeReserveDropTiles.contains(tile)) {
      state = _emit(state, 'Drop rejected: choose a highlighted drop tile.');
      return false;
    }

    final reserve = List<Marine>.from(state.reserveSquad);
    final reinforcement = reserve.removeAt(reserveIndex);
    final deployed = reinforcement.copyWith(
      gridPosition: tile,
      hasMoved: true,
      hasAttacked: true,
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

    state = _emit(
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

  bool useRP(int amount) {
    if (state.requisitionPoints >= amount) {
      state = state.copyWith(
        requisitionPoints: state.requisitionPoints - amount,
      );
      return true;
    }
    return false;
  }

  void upgradeWeapon(int marineIndex, Weapon newWeapon) {
    if (marineIndex < 0 || marineIndex >= state.squad.length) return;
    final newSquad = List<Marine>.from(state.squad);
    newSquad[marineIndex] = newSquad[marineIndex].copyWith(weapon: newWeapon);
    state = state.copyWith(squad: newSquad);
  }

  void upgradeArmor(int marineIndex, Armor newArmor) {
    if (marineIndex < 0 || marineIndex >= state.squad.length) return;
    final newSquad = List<Marine>.from(state.squad);
    newSquad[marineIndex] = newSquad[marineIndex].copyWith(armor: newArmor);
    state = state.copyWith(squad: newSquad);
  }

  void tick() => tickSimulation(1 / 60);

  GameState _newMissionState(
    int index, {
    required int requisitionPoints,
    String? event,
  }) {
    final map = campaignMaps[index];
    return GameState(
      commandPoints: 5,
      requisitionPoints: requisitionPoints,
      missionIndex: index,
      map: map,
      objectives: map.objectives,
      squad: _initSquad(map),
      reserveSquad: _initReserveSquad(map),
      enemies: _initEnemies(index),
      selectedMarineIndex: 0,
      selectedReserveIndex: null,
      actionMode: ActionMode.move,
      activationPhase: ActivationPhase.marines,
      activeEnemyIndex: 0,
      activationRound: 1,
      speed: SimulationSpeed.paused,
      missionStatus: MissionStatus.active,
      elapsedSeconds: 0,
      cpChargeSeconds: 0,
      aiThinkSeconds: 0,
      wave: 0,
      defeatedEnemies: 0,
      beaconDestroyed: false,
      activeEnemyBases: Set<GridPosition>.from(map.enemyBaseTiles),
      plantedBombs: const {},
      activeDropBeacons: Set<GridPosition>.from(map.marineSpawns),
      revision: 0,
      statusMessage:
          'Drop pod opened. Cpt. Varro is active. Four marines deployed.',
      events: [
        CombatEvent(event ?? 'Mission loaded: ${map.name}.', important: true),
      ],
    );
  }

  static List<Marine> _initSquad(TacticalMap map) {
    return _allMarines(map).take(4).toList();
  }

  static List<Marine> _initReserveSquad(TacticalMap map) {
    return _allMarines(map).skip(4).toList();
  }

  static List<Marine> _allMarines(TacticalMap map) {
    const defaultWeapon = Weapon(
      name: 'Godwyn-pattern Boltgun',
      type: WeaponType.boltgun,
      damage: 15,
      range: 3.0,
      fireRate: 1.0,
    );
    const defaultArmor = Armor(
      name: 'Mk X Tacticus Armor',
      type: ArmorType.powerArmor,
      defense: 4,
      speedModifier: 1.0,
    );

    final data = [
      (
        'Cpt. Varro',
        'Commander - Deathwing',
        'assets/portraits/cpt_varro.png',
        110,
      ),
      ('Iolan', 'Plasma Gunner', 'assets/portraits/iolan.png', 90),
      ('Marek', 'Apothecary', 'assets/portraits/marek.png', 90),
      ('Soren', 'Heavy Bolter', 'assets/portraits/soren.png', 95),
      ('Rusk', 'Assault - Ravenwing', 'assets/portraits/rusk.png', 88),
      ('Galen', 'Marksman', 'assets/portraits/galen.png', 84),
      ('Titus', 'Bladeguard Veteran', 'assets/portraits/titus.png', 115),
      ('Nero', 'Techmarine', 'assets/portraits/nero.png', 92),
      ('Cassian', 'Veteran', 'assets/portraits/cassian.png', 96),
      ('Sevran', 'Flamer', 'assets/portraits/sevran.png', 90),
    ];

    return [
      for (var i = 0; i < data.length; i++)
        Marine(
          name: data[i].$1,
          role: data[i].$2,
          portrait: data[i].$3,
          maxHp: data[i].$4,
          hp: data[i].$4,
          weapon: defaultWeapon,
          armor: defaultArmor,
          gridPosition: map.marineSpawns[i % map.marineSpawns.length],
        ),
    ];
  }

  List<EnemyUnit> _initEnemies(int missionIndex) {
    final difficulty = ref.read(settingsProvider).difficulty;
    final mult = difficulty == Difficulty.easy
        ? 0.75
        : difficulty == Difficulty.hard
        ? 1.35
        : 1.0;
    final map = campaignMaps[missionIndex];
    final names = missionIndex == 0
        ? [EnemyKind.orkBoy, EnemyKind.orkBoy, EnemyKind.loota, EnemyKind.nob]
        : missionIndex == 1
        ? [
            EnemyKind.cultist,
            EnemyKind.genestealer,
            EnemyKind.cultist,
            EnemyKind.genestealer,
          ]
        : [
            EnemyKind.cultist,
            EnemyKind.hereticAstartes,
            EnemyKind.hereticAstartes,
          ];
    return [
      for (var i = 0; i < names.length; i++)
        _enemyForKind(
          '${map.id}-enemy-$i',
          names[i],
          map.enemySpawns[i % map.enemySpawns.length],
          mult,
        ),
    ];
  }

  EnemyUnit _enemyForKind(
    String id,
    EnemyKind kind,
    GridPosition spawn,
    double mult,
  ) {
    return switch (kind) {
      EnemyKind.orkBoy => EnemyUnit(
        id: id,
        name: 'Ork Boy',
        kind: kind,
        hp: (34 * mult).round(),
        maxHp: (34 * mult).round(),
        position: spawn,
        damage: (12 * mult).round(),
      ),
      EnemyKind.nob => EnemyUnit(
        id: id,
        name: 'Nob',
        kind: kind,
        hp: (64 * mult).round(),
        maxHp: (64 * mult).round(),
        position: spawn,
        damage: (18 * mult).round(),
        rpReward: 12,
      ),
      EnemyKind.loota => EnemyUnit(
        id: id,
        name: 'Loota',
        kind: kind,
        hp: (28 * mult).round(),
        maxHp: (28 * mult).round(),
        position: spawn,
        attackRange: 3,
        damage: (10 * mult).round(),
      ),
      EnemyKind.cultist => EnemyUnit(
        id: id,
        name: 'Cultist',
        kind: kind,
        hp: (24 * mult).round(),
        maxHp: (24 * mult).round(),
        position: spawn,
        damage: (9 * mult).round(),
      ),
      EnemyKind.genestealer => EnemyUnit(
        id: id,
        name: 'Purestrain',
        kind: kind,
        hp: (42 * mult).round(),
        maxHp: (42 * mult).round(),
        position: spawn,
        damage: (19 * mult).round(),
        speed: 3.2,
        rpReward: 10,
      ),
      EnemyKind.hereticAstartes => EnemyUnit(
        id: id,
        name: 'Heretic Astartes',
        kind: kind,
        hp: (72 * mult).round(),
        maxHp: (72 * mult).round(),
        position: spawn,
        attackRange: 3,
        damage: (17 * mult).round(),
        rpReward: 18,
      ),
    };
  }

  int _nextReadyMarineIndex(List<Marine> squad, int start) {
    for (var i = start; i < squad.length; i++) {
      if (squad[i].hp > 0 && !squad[i].hasMoved && !squad[i].hasAttacked) {
        return i;
      }
    }
    return -1;
  }

  GameState _runEnemyActivationRound(GameState current) {
    var next = current;
    final enemies = <EnemyUnit>[];
    for (final enemy in next.enemies) {
      if (enemy.hp <= 0) continue;
      final actingEnemy = _moveEnemyOffMarineTile(next, enemy, enemies);
      final targetIndex = _nearestMarineIndex(actingEnemy.position, next.squad);
      if (targetIndex == -1) {
        enemies.add(actingEnemy);
        continue;
      }
      final target = next.squad[targetIndex];
      if (actingEnemy.position != target.gridPosition &&
          actingEnemy.position.distanceTo(target.gridPosition) <=
              actingEnemy.attackRange &&
          _pathfinder.hasLineOfSight(
            map: next.map,
            from: actingEnemy.position,
            to: target.gridPosition,
          )) {
        next = _damageMarine(
          next,
          targetIndex,
          actingEnemy.damage,
          '${actingEnemy.name} attacks ${target.name}.',
          attackerPosition: actingEnemy.position,
        );
        enemies.add(actingEnemy.copyWith(path: const [], commandProgress: 0));
      } else {
        final blockers = {...next.blockers}
          ..remove(actingEnemy.position)
          ..remove(target.gridPosition);
        final path = _pathfinder.findPath(
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
        final destination = _safeEnemyDestination(
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
          afterMove = _triggerOverwatch(afterMove, step);
        }
        next = afterMove;
        final refreshedTarget = next.squad[targetIndex];
        if (movedDistance > 0 &&
            movedEnemy.position.distanceTo(refreshedTarget.gridPosition) <=
                movedEnemy.attackRange) {
          next = _damageMarine(
            next,
            targetIndex,
            movedEnemy.damage,
            '${movedEnemy.name} closes and strikes ${refreshedTarget.name}.',
            attackerPosition: movedEnemy.position,
          );
        }
        enemies.add(movedEnemy);
      }
    }
    return next.copyWith(enemies: enemies);
  }

  EnemyUnit _moveEnemyOffMarineTile(
    GameState current,
    EnemyUnit enemy,
    List<EnemyUnit> resolvedEnemies,
  ) {
    final marineTiles = {
      for (final marine in current.squad)
        if (marine.hp > 0) marine.gridPosition,
    };
    if (!marineTiles.contains(enemy.position)) return enemy;

    final destination = _safeEnemyDestination(
      current: current,
      enemy: enemy,
      desired: enemy.position,
      focus: enemy.position,
      reservedEnemyTiles: {
        for (final resolvedEnemy in resolvedEnemies) resolvedEnemy.position,
      },
    );
    return enemy.copyWith(position: destination);
  }

  GridPosition _safeEnemyDestination({
    required GameState current,
    required EnemyUnit enemy,
    required GridPosition desired,
    required GridPosition focus,
    required Set<GridPosition> reservedEnemyTiles,
  }) {
    if (_canEnemyOccupy(
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
      if (_canEnemyOccupy(
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

  bool _canEnemyOccupy({
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

  GameState _maybeSpawnWave(GameState current) {
    final waveTime = 25.0 + current.wave * 28.0;
    if (current.elapsedSeconds < waveTime || current.wave >= 3) return current;
    final spawns = current.map.enemySpawns;
    final kind = current.missionIndex == 2
        ? EnemyKind.hereticAstartes
        : EnemyKind.orkBoy;
    final newEnemies = [
      ...current.enemies,
      for (var i = 0; i < 2 + current.wave; i++)
        _enemyForKind(
          '${current.map.id}-wave-${current.wave}-$i',
          i == 0 && current.wave > 0 ? kind : EnemyKind.orkBoy,
          spawns[i % spawns.length],
          1.0 + current.wave * 0.1,
        ),
    ];
    return _emit(
      current.copyWith(enemies: newEnemies, wave: current.wave + 1),
      'Enemy reinforcements entering the battlespace.',
    );
  }

  GameState _refreshObjectives(GameState current) {
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

  GameState _checkMissionEnd(GameState current) {
    if (current.missionStatus != MissionStatus.active) return current;
    final alive = current.squad.any((marine) => marine.hp > 0);
    if (!alive) {
      return _emit(
        current.copyWith(missionStatus: MissionStatus.defeat),
        'Mission failed. Squad incapacitated.',
      );
    }
    if (current.objectives.every((objective) => objective.completed)) {
      return _emit(
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

  void _damageEnemy(
    int enemyIndex,
    int rawDamage,
    String message, {
    required GridPosition attackerPosition,
    bool markAttackerSpent = false,
  }) {
    final enemy = state.enemies[enemyIndex];
    final inCover = GameState.hasDirectionalCover(
      target: enemy.position,
      attacker: attackerPosition,
      map: state.map,
    );
    final damage = inCover ? (rawDamage * 0.65).round() : rawDamage;
    final nextHp = enemy.hp - damage;
    final enemies = List<EnemyUnit>.from(state.enemies);
    enemies[enemyIndex] = enemy.copyWith(hp: nextHp);
    var squad = state.squad;
    if (markAttackerSpent) {
      squad = List<Marine>.from(state.squad);
      final marine = squad[state.selectedMarineIndex];
      squad[state.selectedMarineIndex] = marine.copyWith(
        hasAttacked: true,
        isOverwatching: false,
      );
    }
    final defeated = nextHp <= 0;
    state = _emit(
      state.copyWith(
        squad: squad,
        enemies: defeated
            ? enemies.where((enemy) => enemy.hp > 0).toList()
            : enemies,
        defeatedEnemies: defeated
            ? state.defeatedEnemies + 1
            : state.defeatedEnemies,
        requisitionPoints: defeated
            ? state.requisitionPoints + enemy.rpReward
            : state.requisitionPoints,
        commandPoints: defeated
            ? min(GameState.maxCommandPoints, state.commandPoints + 1)
            : state.commandPoints,
        actionMode: markAttackerSpent ? ActionMode.move : state.actionMode,
      ),
      defeated
          ? '$message ${enemy.name} eliminated.'
          : '$message $damage damage.',
    );
  }

  GameState _damageMarine(
    GameState current,
    int marineIndex,
    int rawDamage,
    String message, {
    required GridPosition attackerPosition,
  }) {
    final marine = current.squad[marineIndex];
    final covered = GameState.hasDirectionalCover(
      target: marine.gridPosition,
      attacker: attackerPosition,
      map: current.map,
    );
    final mitigated = max(2, rawDamage - marine.armor.defense);
    final damage = covered ? (mitigated * 0.55).round() : mitigated;
    final squad = List<Marine>.from(current.squad);
    squad[marineIndex] = marine.copyWith(hp: max(0, marine.hp - damage));
    return _emit(current.copyWith(squad: squad), '$message $damage damage.');
  }

  GameState _triggerOverwatch(GameState current, GridPosition enemyPosition) {
    final enemyIndex = current.enemyAt(enemyPosition);
    if (enemyIndex == -1) return current;
    for (var i = 0; i < current.squad.length; i++) {
      final marine = current.squad[i];
      if (!marine.isOverwatching || marine.hp <= 0) continue;
      if (marine.gridPosition.distanceTo(enemyPosition) <=
              GameState.rangedAttackRange &&
          _pathfinder.hasLineOfSight(
            map: current.map,
            from: marine.gridPosition,
            to: enemyPosition,
          )) {
        final enemies = List<EnemyUnit>.from(current.enemies);
        final enemy = enemies[enemyIndex];
        enemies[enemyIndex] = enemy.copyWith(hp: enemy.hp - 12);
        final squad = List<Marine>.from(current.squad);
        squad[i] = marine.copyWith(isOverwatching: false);
        return _emit(
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

  int _nearestMarineIndex(GridPosition from, List<Marine> squad) {
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


  GameState _emit(GameState next, String message, {bool important = false}) {
    final events = [
      CombatEvent(message, important: important),
      ...next.events.take(7),
    ];
    return next.copyWith(statusMessage: message, events: events);
  }

  String _modeName(ActionMode? mode) {
    return switch (mode) {
      ActionMode.move => 'Move',
      ActionMode.shoot => 'Shoot',
      ActionMode.melee => 'Melee',
      ActionMode.ability => 'Ability',
      ActionMode.overwatch => 'Overwatch',
      ActionMode.deployReserve => 'Reserve Drop',
      ActionMode.plantBomb => 'Plant Bomb',
      ActionMode.deployBeacon => 'Deploy Beacon',
      null => 'None',
    };
  }
}

final gameStateProvider = NotifierProvider<GameStateNotifier, GameState>(() {
  return GameStateNotifier();
});
