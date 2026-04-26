import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../models/grid_position.dart';
import '../crusade_game.dart';

class EnemyBaseComponent extends SpriteComponent with HasGameReference<CrusadeGame> {
  EnemyBaseComponent({
    required this.gridPosition,
  }) : super(size: Vector2.all(CrusadeGame.tileSize * 0.9)) {
    // White-Screen Chroma Key: Removes pure white backgrounds (#FFFFFF)
    paint.colorFilter = const ColorFilter.matrix(<double>[
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      -1, -1, -1, 0, 2.8,
    ]);
  }

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
    add(
      ScaleEffect.to(
        Vector2.all(1.5),
        EffectController(duration: 0.3, curve: Curves.easeOutBack),
      ),
    );
    add(
      ColorEffect(
        const Color(0xFFFF4400),
        EffectController(duration: 0.3),
        opacityTo: 0.8,
        onComplete: removeFromParent,
      ),
    );
  }
}
