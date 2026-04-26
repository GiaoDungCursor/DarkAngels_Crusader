import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

import '../../models/grid_position.dart';
import '../crusade_game.dart';

/// Animated drop pod that falls from orbit, shakes the camera on impact,
/// then converts into a persistent debris sprite (visible cover marker).
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
    // Camera shake on impact
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

    // Call the callback to show the marine
    onLanded();

    // Shrink the pod sprite into a compact debris marker instead of removing it
    // This keeps a visible object on the tile so the player sees the cover source
    add(
      SizeEffect.to(
        Vector2.all(CrusadeGame.tileSize * 0.6),
        EffectController(
          duration: 0.6,
          startDelay: 0.8,
          curve: Curves.easeInOut,
        ),
        onComplete: () {
          // Settle as debris
          anchor = Anchor.center;
          position = targetPosition;
          opacity = 0.7;
          priority = 2; // Same level as cover
        },
      ),
    );
  }
}
