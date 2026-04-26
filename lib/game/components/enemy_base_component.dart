import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../models/grid_position.dart';
import '../crusade_game.dart';

class EnemyBaseComponent extends SpriteComponent
    with HasGameReference<CrusadeGame> {
  EnemyBaseComponent({required this.gridPosition})
    : super(size: Vector2.all(CrusadeGame.tileSize * 1.15));

  final GridPosition gridPosition;
  SpriteComponent? _bombIndicator;
  late final CircleComponent _targetRing;
  late final TextComponent _label;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('sprites/objects/enemy_base.png');
    anchor = Anchor.center;
    position = game.gridToWorld(gridPosition);

    _targetRing = CircleComponent(
      radius: size.x * 0.54,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFF4E9A),
    );
    add(_targetRing);

    _label = TextComponent(
      text: 'BASE',
      anchor: Anchor.center,
      position: Vector2(size.x / 2, -8),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFE066),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
    add(_label);

    add(
      ScaleEffect.to(
        Vector2.all(1.06),
        EffectController(duration: 0.75, reverseDuration: 0.75, infinite: true),
      ),
    );
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
