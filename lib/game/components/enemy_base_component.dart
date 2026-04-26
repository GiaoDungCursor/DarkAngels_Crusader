import 'package:flame/components.dart';
import '../../models/grid_position.dart';
import '../crusade_game.dart';

class EnemyBaseComponent extends SpriteComponent with HasGameReference<CrusadeGame> {
  EnemyBaseComponent({
    required this.gridPosition,
  }) : super(size: Vector2.all(CrusadeGame.tileSize * 0.9));

  final GridPosition gridPosition;
  SpriteComponent? _bombIndicator;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('sprites/objects/enemy_base.png');
    anchor = Anchor.center;
    position = game.gridToWorld(gridPosition);
  }

  Future<void> showPlantedBomb() async {
    if (_bombIndicator != null) return;
    
    final bombSprite = await game.loadSprite('sprites/objects/bomb.png');
    _bombIndicator = SpriteComponent(
      sprite: bombSprite,
      size: Vector2.all(CrusadeGame.tileSize * 0.4),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_bombIndicator!);
  }

  void destroyBase() {
    // Optionally trigger an explosion effect before removal
    removeFromParent();
  }
}
