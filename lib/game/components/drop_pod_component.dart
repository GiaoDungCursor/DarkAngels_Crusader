import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../../models/grid_position.dart';
import '../crusade_game.dart';

class DropPodComponent extends SpriteComponent with HasGameReference<CrusadeGame> {
  DropPodComponent({
    required this.gridPosition,
    required this.targetPosition,
    required this.onLanded,
  }) : super(size: Vector2(CrusadeGame.tileSize, CrusadeGame.tileSize * 2));

  final GridPosition gridPosition;
  final Vector2 targetPosition;
  final VoidCallback onLanded;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('sprites/objects/drop_pod.png');
    
    // Start high up above the target
    position = Vector2(targetPosition.x, targetPosition.y - 800);
    anchor = Anchor.bottomCenter;

    // Fall down effect
    add(
      MoveEffect.to(
        targetPosition,
        EffectController(
          duration: 0.5,
          curve: Curves.easeInQuad,
        ),
        onComplete: () {
          _land();
        },
      ),
    );
  }

  void _land() {
    // Basic camera shake effect
    game.camera.viewfinder.add(
      MoveEffect.by(
        Vector2(0, 10),
        EffectController(
          duration: 0.05,
          alternate: true,
          repeatCount: 3,
        ),
      ),
    );

    // Call the callback to spawn the marine
    onLanded();

    // Fade out and remove the drop pod after a short delay
    add(
      OpacityEffect.fadeOut(
        EffectController(
          duration: 0.5,
          startDelay: 1.0,
        ),
        onComplete: removeFromParent,
      ),
    );
  }
}
