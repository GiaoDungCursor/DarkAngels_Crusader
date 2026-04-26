import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enemy_unit.dart';
import '../models/equipment.dart';
import '../models/grid_position.dart';
import '../models/marine.dart';
import '../models/tactical_map.dart';
import '../models/game_enums.dart';
import '../models/combat_event.dart';
import '../models/game_state.dart';
import '../services/pathfinder.dart';
import 'settings_provider.dart';

export '../models/game_enums.dart';
export '../models/combat_event.dart';
export '../models/game_state.dart';

part 'game_logic/enemy_ai.dart';
part 'game_logic/combat_logic.dart';
part 'game_logic/mission_logic.dart';
part 'game_logic/mission_setup.dart';
part 'game_logic/player_actions.dart';

class GameStateNotifier extends Notifier<GameState> {
  static const _pathfinder = Pathfinder();

  @override
  GameState build() {
    return newMissionState(0, requisitionPoints: 0);
  }

  void startMission(int index, {GridPosition? selectedDropZone}) {
    final safeIndex = index.clamp(0, campaignMaps.length - 1);
    state = newMissionState(
      safeIndex,
      requisitionPoints: state.requisitionPoints,
      selectedDropZone: selectedDropZone,
      event: 'Mission loaded: ${campaignMaps[safeIndex].name}.',
    );
  }

  void selectUnit(int index) => selectMarine(index);

  void selectMarine(int index) {
    if (index < 0 || index >= state.squad.length) return;
    if (state.squad[index].hp <= 0) return;
    if (state.missionStatus != MissionStatus.active) {
      state = emit(state, 'Mission already resolved.');
      return;
    }
    if (state.activationPhase != ActivationPhase.marines) {
      state = emit(state, 'Enemy activation in progress.');
      return;
    }

    state = emit(
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
      state = emit(state, 'Mission already resolved.');
      return;
    }
    state = emit(
      state.copyWith(
        actionMode: mode,
        clearSelectedReserve: mode != ActionMode.deployReserve,
      ),
      'Mode: ${modeName(mode)}.',
    );
  }

  void togglePause() {
    final next = state.speed == SimulationSpeed.paused
        ? SimulationSpeed.normal
        : SimulationSpeed.paused;
    state = emit(
      state.copyWith(speed: next),
      next == SimulationSpeed.paused
          ? 'Tactical pause engaged.'
          : 'Realtime execution resumed.',
    );
  }

  void setSpeed(SimulationSpeed speed) {
    state = emit(
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
      state = emit(state, 'Mission already resolved.');
      return;
    }
    
    // Deployment phase check removed

    if (state.activationPhase != ActivationPhase.marines) {
      state = emit(state, 'Wait for the enemy phase to resolve.');
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
          state = emit(state, 'Select a reserve marine first.');
        } else {
          deployReserveMarineAt(reserveIndex, tile);
        }
      case ActionMode.plantBomb:
        plantBomb(tile);
      case ActionMode.deployBeacon:
        deployBeacon(tile);
      case null:
        state = emit(state, 'Choose a command mode first.');
    }
  }




  void setOverwatch() {
    final marine = state.selectedMarine;
    if (marine == null || marine.actionPoints == 0) return;
    final squad = List<Marine>.from(state.squad);
    squad[state.selectedMarineIndex] = marine.copyWith(
      actionPoints: max(0, marine.actionPoints - 1),
      isOverwatching: true,
    );
    state = emit(
      state.copyWith(squad: squad),
      '${marine.name} enters Overwatch.',
    );
  }


  void tickSimulation(double rawDt) {
    if (state.missionStatus != MissionStatus.active) return;
    state = checkMissionEnd(refreshObjectives(state));
  }

  void completeMission() {
    state = checkMissionEnd(
      state.copyWith(missionStatus: MissionStatus.victory),
    );
  }

  void endSquadTurn() {
    if (state.missionStatus != MissionStatus.active) return;
    if (state.activationPhase != ActivationPhase.marines) return;

    final squad = List<Marine>.from(state.squad);

    // Process bomb timers before enemy activation
    var nextState = processBombs(
      state.copyWith(
        squad: squad,
        activationPhase: ActivationPhase.enemies,
        activeEnemyIndex: 0,
        clearActionMode: true,
        elapsedSeconds: state.elapsedSeconds + 10,
      ),
    );

    var afterEnemies = runEnemyActivationRound(nextState);
    afterEnemies = maybeSpawnWave(afterEnemies);
    afterEnemies = refreshObjectives(afterEnemies);
    afterEnemies = checkMissionEnd(afterEnemies);
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
          actionPoints: marine.maxActionPoints,
          isOverwatching: false,
        ),
    ];
    state = emit(
      afterEnemies.copyWith(
        squad: resetSquad,
        activationPhase: ActivationPhase.marines,
        activeEnemyIndex: 0,
        activationRound: afterEnemies.activationRound + 1,
        actionMode: ActionMode.move,
        clearSelectedReserve: true,
        commandPoints: min(GameState.maxCommandPoints, afterEnemies.commandPoints + 1),
      ),
      'Squad Phase Begins. Command points regenerated.',
      important: true,
    );
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
      state = emit(state, 'No valid drop zone available.');
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
      state = emit(state, 'Mission already resolved.');
      return;
    }
    if (state.commandPoints < cost) {
      state = emit(state, 'Need $cost CP to deploy reinforcement.');
      return;
    }
    if (state.freeReserveDropTiles.isEmpty) {
      state = emit(state, 'No valid drop zone available.');
      return;
    }

    state = emit(
      state.copyWith(
        selectedReserveIndex: reserveIndex,
        actionMode: ActionMode.deployReserve,
      ),
      'Select a green drop tile for ${state.reserveSquad[reserveIndex].name}.',
      important: true,
    );
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

  GameState newMissionState(
    int index, {
    required int requisitionPoints,
    GridPosition? selectedDropZone,
    String? event,
  }) {
    var activeMap = campaignMaps[index];
    final squad = _initSquad(activeMap, selectedDropZone);
    final dropBeacon = selectedDropZone ?? (squad.isNotEmpty ? squad.first.gridPosition : null);
    return GameState(
      commandPoints: 5,
      requisitionPoints: requisitionPoints,
      missionIndex: index,
      map: activeMap,
      objectives: activeMap.objectives,
      squad: squad,
      reserveSquad: _initReserveSquad(activeMap, selectedDropZone),
      enemies: _initEnemies(index),
      selectedMarineIndex: 0,
      selectedReserveIndex: null,
      actionMode: null,
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
      activeEnemyBases: Set<GridPosition>.from(activeMap.enemyBaseTiles),
      plantedBombs: const {},
      activeDropBeacons: dropBeacon != null ? {dropBeacon} : const {},
      dropPodCoverTiles: dropBeacon != null ? {dropBeacon} : const {},
      revision: 0,
      statusMessage:
          'Drop pod landed. Cpt. Varro is active. Four marines deployed.',
      events: [
        CombatEvent(event ?? 'Mission loaded: ${activeMap.name}.', important: true),
      ],
      selectedDropZones: dropBeacon != null ? {dropBeacon} : const {},
    );
  }

  static List<Marine> _initSquad(TacticalMap map, GridPosition? selectedDropZone) {
    return _allMarines(map, selectedDropZone).take(4).toList();
  }

  static List<Marine> _initReserveSquad(TacticalMap map, GridPosition? selectedDropZone) {
    return _allMarines(map, selectedDropZone).skip(4).toList();
  }

  static List<Marine> _allMarines(TacticalMap map, GridPosition? selectedDropZone) {
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

    // (name, role, portrait, hp, spriteKey)
    final data = [
      ('Cpt. Varro', 'Commander - Deathwing', 'assets/portraits/cpt_varro.png', 110, 'terminator'),
      ('Iolan', 'Plasma Gunner', 'assets/portraits/iolan.png', 90, 'marine'),
      ('Marek', 'Apothecary', 'assets/portraits/marek.png', 90, 'marine'),
      ('Soren', 'Heavy Bolter', 'assets/portraits/soren.png', 95, 'marine'),
      ('Rusk', 'Assault - Ravenwing', 'assets/portraits/rusk.png', 88, 'marine'),
      ('Galen', 'Marksman', 'assets/portraits/galen.png', 84, 'marine'),
      ('Titus', 'Bladeguard Veteran', 'assets/portraits/titus.png', 115, 'terminator'),
      ('Nero', 'Techmarine', 'assets/portraits/nero.png', 92, 'marine'),
      ('Cassian', 'Veteran', 'assets/portraits/cassian.png', 96, 'marine'),
      ('Sevran', 'Flamer', 'assets/portraits/sevran.png', 90, 'marine'),
    ];

    // If selectedDropZone is provided, spawn around it via BFS.
    // Otherwise fallback to marineSpawns from map layout, or (1,1).
    final spawnPoints = <GridPosition>[];
    if (selectedDropZone != null) {
      // Tiles that are not safe to spawn a marine on
      final forbidden = <GridPosition>{
        selectedDropZone, // the pod itself
        ...selectedDropZone.neighbors(), // keep landing area clear for reinforcements
        ...map.enemyBaseTiles,
        ...map.enemySpawns,
        ...map.hazardTiles,
        ...map.objectiveTiles,
      };

      final queue = [selectedDropZone];
      final visited = {selectedDropZone};
      var iterations = 0;

      while (queue.isNotEmpty && spawnPoints.length < 10 && iterations < 200) {
        iterations++;
        final current = queue.removeAt(0);

        if (!forbidden.contains(current) &&
            map.isInside(current) &&
            map.isWalkable(current)) {
          spawnPoints.add(current);
        }

        for (final neighbor in current.neighbors()) {
          if (!visited.contains(neighbor) && map.isInside(neighbor)) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }
    } else if (map.marineSpawns.isNotEmpty) {
      spawnPoints.addAll(map.marineSpawns);
    } else {
      spawnPoints.add(const GridPosition(1, 1));
    }

    // Safety: if BFS found no tiles (map too blocked), scan full map as fallback
    if (spawnPoints.isEmpty) {
      // Define a generic forbidden set if not already in the BFS branch
      final forbidden = <GridPosition>{
        ...map.enemyBaseTiles,
        ...map.enemySpawns,
        ...map.hazardTiles,
        ...map.objectiveTiles,
      };

      outer:
      for (var y = 0; y < map.height; y++) {
        for (var x = 0; x < map.width; x++) {
          final tile = GridPosition(x, y);
          if (map.isInside(tile) && map.isWalkable(tile) && !forbidden.contains(tile)) {
            spawnPoints.add(tile);
            if (spawnPoints.length >= 10) break outer;
          }
        }
      }
    }
    // Final fallback – guarantee at least one point to avoid modulo-zero crash
    if (spawnPoints.isEmpty) {
       // Search for ANY walkable tile if everything else is forbidden
       for (var y = 0; y < map.height; y++) {
         for (var x = 0; x < map.width; x++) {
           final tile = GridPosition(x, y);
           if (map.isWalkable(tile)) {
             spawnPoints.add(tile);
             break;
           }
         }
         if (spawnPoints.isNotEmpty) break;
       }
       if (spawnPoints.isEmpty) spawnPoints.add(const GridPosition(1, 1));
    }

    return [
      for (var i = 0; i < data.length; i++)
        Marine(
          name: data[i].$1,
          role: data[i].$2,
          portrait: data[i].$3,
          maxHp: data[i].$4,
          hp: data[i].$4,
          spriteKey: data[i].$5,
          weapon: defaultWeapon,
          armor: defaultArmor,
          gridPosition: spawnPoints[i % spawnPoints.length],
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
    final enemies = [
      for (var i = 0; i < names.length; i++)
        enemyForKind(
          '${map.id}-enemy-$i',
          names[i],
          map.enemySpawns[i % map.enemySpawns.length],
          mult,
        ),
    ];

    if (map.bossSpawn != null) {
      enemies.add(
        enemyForKind(
          '${map.id}-boss',
          EnemyKind.orkWarboss,
          map.bossSpawn!,
          mult,
        ),
      );
    }

    return enemies;
  }

  EnemyUnit enemyForKind(
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
      EnemyKind.orkWarboss => EnemyUnit(
        id: id,
        name: 'Ork Warboss',
        kind: kind,
        hp: (180 * mult).round(),
        maxHp: (180 * mult).round(),
        position: spawn,
        damage: (35 * mult).round(),
        rpReward: 50,
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




  EnemyUnit moveEnemyOffMarineTile(
    GameState current,
    EnemyUnit enemy,
    List<EnemyUnit> resolvedEnemies,
  ) {
    final marineTiles = {
      for (final marine in current.squad)
        if (marine.hp > 0) marine.gridPosition,
    };
    if (!marineTiles.contains(enemy.position)) return enemy;

    final destination = safeEnemyDestination(
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






  void damageEnemy(
    int enemyIndex,
    int rawDamage,
    String message, {
    required GridPosition attackerPosition,
    int apCost = 0,
  }) {
    final enemy = state.enemies[enemyIndex];
    final inCover = GameState.hasDirectionalCover(
      target: enemy.position,
      attacker: attackerPosition,
      map: state.map,
      dropPods: state.dropPodCoverTiles,
    );
    final damage = inCover ? (rawDamage * 0.65).round() : rawDamage;
    final nextHp = enemy.hp - damage;
    final enemies = List<EnemyUnit>.from(state.enemies);
    enemies[enemyIndex] = enemy.copyWith(hp: nextHp);
    var squad = state.squad;
    if (apCost > 0) {
      squad = List<Marine>.from(state.squad);
      final marine = squad[state.selectedMarineIndex];
      squad[state.selectedMarineIndex] = marine.copyWith(
        actionPoints: max(0, marine.actionPoints - apCost),
        isOverwatching: false,
      );
    }
    final defeated = nextHp <= 0;
    state = emit(
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
        actionMode: apCost > 0 ? ActionMode.move : state.actionMode,
      ),
      defeated
          ? '$message ${enemy.name} eliminated.'
          : '$message $damage damage.',
    );

    if (enemy.kind == EnemyKind.orkWarboss && 
        enemy.hp > enemy.maxHp / 2 && 
        nextHp <= enemy.maxHp / 2) {
      state = triggerWaaagh(state);
    }
  }


  GameState damageMarine(
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
      dropPods: current.dropPodCoverTiles,
    );
    final mitigated = max(2, rawDamage - marine.armor.defense);
    final damage = covered ? (mitigated * 0.55).round() : mitigated;
    final squad = List<Marine>.from(current.squad);
    squad[marineIndex] = marine.copyWith(hp: max(0, marine.hp - damage));
    return emit(current.copyWith(squad: squad), '$message $damage damage.');
  }


  // Deployment phase removed
  GameState emit(GameState next, String message, {bool important = false}) {
    final events = [
      CombatEvent(message, important: important),
      ...next.events.take(7),
    ];
    return next.copyWith(statusMessage: message, events: events);
  }

  String modeName(ActionMode? mode) {
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
