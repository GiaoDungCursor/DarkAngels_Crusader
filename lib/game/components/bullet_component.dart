import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import '../crusade_game.dart';

class BulletComponent extends SpriteComponent
    with HasGameReference<CrusadeGame> {
  final Vector2 target;
  final double damage;

  BulletComponent({
    required Vector2 position,
    required this.target,
    required this.damage,
  }) : super(position: position, size: Vector2(18, 18)) {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await game.loadSprite('sprites/objects/projectile.png');
    final direction = (target - position).normalized();
    angle = direction.screenAngle();
    add(
      MoveToEffect(
        target,
        EffectController(duration: 0.18, curve: Curves.easeOutCubic),
        onComplete: removeFromParent,
      ),
    );
  }
}
