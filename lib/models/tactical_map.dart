import 'package:flutter/material.dart';

import 'grid_position.dart';

enum ObjectiveType {
  survive,
  eliminateAll,
  destroyBeacon,
  destroyBase,
  extract,
}

enum TileKind {
  floor,
  blocked,
  voidTile,
  bridge,
  cover,
  objective,
  extraction,
  marineSpawn,
  enemySpawn,
  enemyBase,
  hazard,
  dropZone,
}

class MissionObjective {
  const MissionObjective({
    required this.id,
    required this.label,
    required this.type,
    this.requiredValue = 1,
    this.progress = 0,
    this.completed = false,
  });

  final String id;
  final String label;
  final ObjectiveType type;
  final int requiredValue;
  final int progress;
  final bool completed;

  MissionObjective copyWith({int? progress, bool? completed}) {
    return MissionObjective(
      id: id,
      label: label,
      type: type,
      requiredValue: requiredValue,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
    );
  }
}

class TacticalMap {
  const TacticalMap({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.width,
    required this.height,
    required this.tileKinds,
    required this.coverTiles,
    required this.blockedTiles,
    required this.voidTiles,
    required this.bridgeTiles,
    required this.hazardTiles,
    required this.objectiveTiles,
    required this.extractionTiles,
    required this.dropZones,
    required this.marineSpawns,
    required this.enemySpawns,
    required this.enemyBaseTiles,
    this.bossSpawn,
    required this.objectives,
    required this.rewardRP,
    required this.threat,
    required this.control,
  });

  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final String background;
  final int width;
  final int height;
  final Map<GridPosition, TileKind> tileKinds;
  final Set<GridPosition> coverTiles;
  final Set<GridPosition> blockedTiles;
  final Set<GridPosition> voidTiles;
  final Set<GridPosition> bridgeTiles;
  final Set<GridPosition> hazardTiles;
  final Set<GridPosition> objectiveTiles;
  final Set<GridPosition> extractionTiles;
  final List<GridPosition> dropZones;
  final List<GridPosition> marineSpawns;
  final List<GridPosition> enemySpawns;
  final Set<GridPosition> enemyBaseTiles;
  final GridPosition? bossSpawn;
  final List<MissionObjective> objectives;
  final int rewardRP;
  final int threat;
  final int control;

  bool isInside(GridPosition tile) {
    return tile.x >= 0 && tile.x < width && tile.y >= 0 && tile.y < height;
  }

  TileKind kindAt(GridPosition tile) {
    return tileKinds[tile] ?? TileKind.floor;
  }

  bool isWalkable(GridPosition tile) {
    if (!isInside(tile)) return false;
    return switch (kindAt(tile)) {
      TileKind.blocked || TileKind.voidTile || TileKind.cover => false,
      _ => true,
    };
  }

  bool blocksLineOfSight(GridPosition tile) {
    return blockedTiles.contains(tile) ||
        coverTiles.contains(tile) ||
        enemyBaseTiles.contains(tile);
  }

  TacticalMap copyWith({Set<GridPosition>? coverTiles}) {
    return TacticalMap(
      id: id,
      name: name,
      subtitle: subtitle,
      icon: icon,
      background: background,
      width: width,
      height: height,
      tileKinds: tileKinds,
      coverTiles: coverTiles ?? this.coverTiles,
      blockedTiles: blockedTiles,
      voidTiles: voidTiles,
      bridgeTiles: bridgeTiles,
      hazardTiles: hazardTiles,
      objectiveTiles: objectiveTiles,
      extractionTiles: extractionTiles,
      dropZones: dropZones,
      marineSpawns: marineSpawns,
      enemySpawns: enemySpawns,
      enemyBaseTiles: enemyBaseTiles,
      bossSpawn: bossSpawn,
      objectives: objectives,
      rewardRP: rewardRP,
      threat: threat,
      control: control,
    );
  }
}

TacticalMap _tacticalMap({
  required String id,
  required String name,
  required String subtitle,
  required IconData icon,
  required String background,
  required List<String> layout,
  required List<MissionObjective> objectives,
  required int rewardRP,
  required int threat,
  required int control,
}) {
  final height = layout.length;
  final width = layout.first.length;
  final tileKinds = <GridPosition, TileKind>{};
  final coverTiles = <GridPosition>{};
  final blockedTiles = <GridPosition>{};
  final voidTiles = <GridPosition>{};
  final bridgeTiles = <GridPosition>{};
  final hazardTiles = <GridPosition>{};
  final objectiveTiles = <GridPosition>{};
  final extractionTiles = <GridPosition>{};
  final dropZones = <GridPosition>[];
  final marineSpawns = <GridPosition>[];
  final enemySpawns = <GridPosition>[];
  final enemyBaseTiles = <GridPosition>{};
  GridPosition? bossSpawn;

  for (var y = 0; y < layout.length; y++) {
    final row = layout[y];
    assert(row.length == width, 'All tactical map rows must have same width.');
    for (var x = 0; x < row.length; x++) {
      final tile = GridPosition(x, y);
      final kind = switch (row[x]) {
        '#' => TileKind.blocked,
        'v' => TileKind.voidTile,
        'b' => TileKind.bridge,
        'C' => TileKind.cover,
        'h' => TileKind.hazard,
        'O' => TileKind.objective,
        'X' => TileKind.extraction,
        'S' => TileKind.marineSpawn,
        'E' => TileKind.enemySpawn,
        'B' => TileKind.enemyBase,
        'D' => TileKind.dropZone,
        'W' => TileKind.floor, // W is boss spawn, but walks on floor
        _ => TileKind.floor,
      };
      tileKinds[tile] = kind;
      switch (kind) {
        case TileKind.blocked:
          blockedTiles.add(tile);
        case TileKind.voidTile:
          voidTiles.add(tile);
        case TileKind.bridge:
          bridgeTiles.add(tile);
        case TileKind.cover:
          coverTiles.add(tile);
        case TileKind.hazard:
          hazardTiles.add(tile);
        case TileKind.objective:
          objectiveTiles.add(tile);
        case TileKind.extraction:
          extractionTiles.add(tile);
        case TileKind.marineSpawn:
          marineSpawns.add(tile);
        case TileKind.enemySpawn:
          enemySpawns.add(tile);
        case TileKind.enemyBase:
          enemyBaseTiles.add(tile);
        case TileKind.dropZone:
          dropZones.add(tile);
        case TileKind.floor:
          break;
      }

      if (row[x] == 'W') {
        bossSpawn = tile;
      }
    }
  }

  return TacticalMap(
    id: id,
    name: name,
    subtitle: subtitle,
    icon: icon,
    background: background,
    width: width,
    height: height,
    tileKinds: tileKinds,
    coverTiles: coverTiles,
    blockedTiles: blockedTiles,
    voidTiles: voidTiles,
    bridgeTiles: bridgeTiles,
    hazardTiles: hazardTiles,
    objectiveTiles: objectiveTiles,
    extractionTiles: extractionTiles,
    dropZones: dropZones,
    marineSpawns: marineSpawns,
    enemySpawns: enemySpawns,
    enemyBaseTiles: enemyBaseTiles,
    bossSpawn: bossSpawn,
    objectives: objectives,
    rewardRP: rewardRP,
    threat: threat,
    control: control,
  );
}

final campaignMaps = [
  _tacticalMap(
    id: 'drop-zone-epsilon',
    name: 'Drop Zone Epsilon: Broken Landing',
    subtitle: 'Hold the 3-lane landing grid against Ork waves',
    icon: Icons.rocket_launch,
    background: 'maps/map_drop_zone_epsilon_generated.png',
    layout: [
      '################',
      '#D..CC...vv...E#',
      '#...CC...bb#B.E#',
      '#......#Cbb...E#',
      '#vvvvv...vvvvvv#',
      '#vvvvv..##....C#',
      '#SS..#C...O.B.C#',
      '#..D..#C..W....#',
      '#SS..#C...O.B.C#',
      '#vvvvv........C#',
      '#vvvvv..##vvvvv#',
      '#......#Cbb...E#',
      '#...CC...bb#B.E#',
      '#D..CC..#vv...E#',
      '#XX....##.C....#',
      '################',
    ],
    objectives: [
      MissionObjective(
        id: 'destroy_bases',
        label: 'Destroy 3 Enemy Bases',
        type: ObjectiveType.destroyBase,
        requiredValue: 3,
      ),
      MissionObjective(
        id: 'survive',
        label: 'Survive 3 enemy waves',
        type: ObjectiveType.survive,
        requiredValue: 3,
      ),
    ],
    rewardRP: 50,
    threat: 18,
    control: 23,
  ),
  _tacticalMap(
    id: 'hive-gate-primus',
    name: 'Hive Gate Primus',
    subtitle: 'Purge the relay station and hidden cult beacon',
    icon: Icons.fort,
    background: 'maps/map_hive_gate_primus_generated.png',
    layout: [
      '################',
      '#X...C...vv.EE.#',
      '#XSD.C...vv....#',
      '#.S..C..bbb....#',
      '#.......bOb..C.#',
      '#.......bOb..C.#',
      '#...CC..bbb....#',
      '#...CC.....vv..#',
      '#.......C..vvE.#',
      '#..hhh..C...D..#',
      '#..hhh.....CC..#',
      '#......vv..CC..#',
      '#..C...vv......#',
      '#SDC......bbbE.#',
      '#S........bbb..#',
      '################',
    ],
    objectives: [
      MissionObjective(
        id: 'beacon',
        label: 'Destroy the hidden cult beacon',
        type: ObjectiveType.destroyBeacon,
      ),
      MissionObjective(
        id: 'clear',
        label: 'Purge all revealed hostiles',
        type: ObjectiveType.eliminateAll,
      ),
    ],
    rewardRP: 100,
    threat: 38,
    control: 49,
  ),
  _tacticalMap(
    id: 'ash-basilica',
    name: 'Ash Basilica',
    subtitle: 'Secure the Fallen clue and extract',
    icon: Icons.account_balance,
    background: 'maps/map_ash_basilica_generated.png',
    layout: [
      '################',
      '#..vv....C..EE.#',
      '#..vv....C.....#',
      '#SDbb..CC......#',
      '#S.bb..CC..h...#',
      '#..vv......h...#',
      '#..vv..####....#',
      '#......#OO#..E.#',
      '#..C...#OO#....#',
      '#..C...####.CC.#',
      '#......hhh..CC.#',
      '#..bbb.........#',
      '#..bbb.....E...#',
      '#XXSS...vv..D..#',
      '#XX.....vv.....#',
      '################',
    ],
    objectives: [
      MissionObjective(
        id: 'clue',
        label: 'Recover the Fallen cipher',
        type: ObjectiveType.destroyBeacon,
      ),
      MissionObjective(
        id: 'extract',
        label: 'Extract at least one battle-brother',
        type: ObjectiveType.extract,
      ),
    ],
    rewardRP: 250,
    threat: 61,
    control: 72,
  ),
];
