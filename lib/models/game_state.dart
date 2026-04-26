import 'dart:math';

import 'combat_event.dart';
import 'enemy_unit.dart';
import 'game_enums.dart';
import 'grid_position.dart';
import 'marine.dart';
import 'tactical_map.dart';
import '../services/pathfinder.dart';

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
  final Set<GridPosition> selectedDropZones;
  final double elapsedSeconds;
  final double cpChargeSeconds;
  final double aiThinkSeconds;
  final int wave;
  final int defeatedEnemies;
  final bool beaconDestroyed;
  final Set<GridPosition> activeEnemyBases;
  final Map<GridPosition, int> plantedBombs;
  final Set<GridPosition> activeDropBeacons;
  final Set<GridPosition> dropPodCoverTiles;
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
    required this.dropPodCoverTiles,
    required this.revision,
    required this.statusMessage,
    required this.events,
    this.selectedDropZones = const {},
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
      ...dropPodCoverTiles,
      for (final enemy in enemies)
        if (enemy.hp > 0) enemy.position,
      for (final marine in squad)
        if (marine.hp > 0) marine.gridPosition,
    };
  }

  Set<GridPosition> get reachableTiles {
    final marine = selectedMarine;
    if (marine == null || !isMarinePhase || marine.actionPoints == 0 || marine.hp <= 0) {
      return {};
    }
    final maxSteps = marine.actionPoints >= 2 ? marineMoveRange : 2;
    return const Pathfinder().reachable(
      map: map,
      start: marine.gridPosition,
      maxSteps: maxSteps,
      blockers: blockers..remove(marine.gridPosition),
    );
  }

  Set<GridPosition> get shootableTiles {
    final marine = selectedMarine;
    if (marine == null ||
        !isMarinePhase ||
        marine.actionPoints == 0 ||
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
        marine.actionPoints == 0 ||
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
        marine.actionPoints == 0 ||
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
    final validTiles = {
      ...activeDropBeacons,
      for (final beacon in activeDropBeacons) ...beacon.neighbors(),
    };
    return validTiles
        .where((tile) =>
            map.isInside(tile) &&
            map.isWalkable(tile) &&
            !occupied.contains(tile) &&
            !dropPodCoverTiles.contains(tile))
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
    if (marine == null || !isMarinePhase || marine.actionPoints == 0 || marine.hp <= 0) {
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
          if (hasDirectionalCover(target: tile, attacker: enemy.position, map: map, dropPods: dropPodCoverTiles)) {
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
    Set<GridPosition> dropPods = const {},
  }) {
    for (final cover in {...map.coverTiles, ...dropPods}) {
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
          if (hasDirectionalCover(target: marine.gridPosition, attacker: enemy.position, map: map, dropPods: dropPodCoverTiles)) {
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
    Set<GridPosition>? dropPodCoverTiles,
    int? revision,
    String? statusMessage,
    List<CombatEvent>? events,
    Set<GridPosition>? selectedDropZones,
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
      dropPodCoverTiles: dropPodCoverTiles ?? this.dropPodCoverTiles,
      revision: revision ?? this.revision + 1,
      statusMessage: statusMessage ?? this.statusMessage,
      events: events ?? this.events,
      selectedDropZones: selectedDropZones ?? this.selectedDropZones,
    );
  }
}
