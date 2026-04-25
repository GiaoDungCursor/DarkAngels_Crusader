import 'grid_position.dart';

enum EnemyKind { orkBoy, nob, loota, cultist, genestealer, hereticAstartes }

class EnemyUnit {
  const EnemyUnit({
    required this.id,
    required this.name,
    required this.kind,
    required this.hp,
    required this.maxHp,
    required this.position,
    this.path = const [],
    this.commandProgress = 0,
    this.attackRange = 1,
    this.damage = 12,
    this.speed = 2.2,
    this.rpReward = 5,
  });

  final String id;
  final String name;
  final EnemyKind kind;
  final int hp;
  final int maxHp;
  final GridPosition position;
  final List<GridPosition> path;
  final double commandProgress;
  final int attackRange;
  final int damage;
  final double speed;
  final int rpReward;

  EnemyUnit copyWith({
    int? hp,
    GridPosition? position,
    List<GridPosition>? path,
    double? commandProgress,
  }) {
    return EnemyUnit(
      id: id,
      name: name,
      kind: kind,
      hp: hp ?? this.hp,
      maxHp: maxHp,
      position: position ?? this.position,
      path: path ?? this.path,
      commandProgress: commandProgress ?? this.commandProgress,
      attackRange: attackRange,
      damage: damage,
      speed: speed,
      rpReward: rpReward,
    );
  }
}
