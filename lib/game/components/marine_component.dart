import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../models/marine.dart';
import '../crusade_game.dart';
import 'unit_state.dart';

class MarineComponent extends SpriteAnimationGroupComponent<UnitState>
    with HasGameReference<CrusadeGame>, TapCallbacks {
  MarineComponent({
    required this.index,
    required Marine marine,
    required Vector2 position,
  }) : marineState = marine,
       super(
         position: position,
         size: Vector2.all(
           marine.spriteKey == 'terminator'
               ? CrusadeGame.tileSize * 1.06
               : CrusadeGame.tileSize * 0.92,
         ),
       ) {
    anchor = Anchor.center;
  }

  final int index;
  Marine marineState;
  CircleComponent? _selectionRing;
  RectangleComponent? _actedBadge;
  double _idleTime = 0;
  bool _animationsReady = false;
  bool _selected = false;

  Future<SpriteAnimation> _loadAnim(String path) async {
    final img = await game.images.load(path);
    final isSpriteSheet = path.contains('spritesheet');
    if (isSpriteSheet) {
      return SpriteAnimation.fromFrameData(
        img,
        SpriteAnimationData.sequenced(
          amount: 4,
          amountPerRow: 2,
          stepTime: 0.15,
          textureSize: Vector2(img.width / 2, img.height / 2),
        ),
      );
    } else {
      return SpriteAnimation.spriteList([Sprite(img)], stepTime: 1.0);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final key = marineState.spriteKey;
    animations = {
      UnitState.idle: await _loadAnim('sprites/marines/${key}_idle.png'),
      UnitState.walk: await _loadAnim('sprites/marines/${key}_walk.png'),
      UnitState.attack: await _loadAnim('sprites/marines/${key}_attack.png'),
      UnitState.dead: await _loadAnim('sprites/marines/${key}_dead.png'),
    };

    _animationsReady = true;
    current = UnitState.idle;
    sync(marineState, selected: _selected);
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.selectMarine(index);
  }

  void sync(Marine marine, {required bool selected}) {
    marineState = marine;
    _selected = selected;
    final target = game.gridToWorld(marine.gridPosition);

    if (!_animationsReady) {
      position = target;
      opacity = marine.hp <= 0 ? 0.35 : opacity;
      _syncSelection(selected);
      _syncActedBadge(marine.actionPoints == 0);
      return;
    }

    if (marine.hp <= 0) {
      current = UnitState.dead;
      opacity = 0.8;
      _syncSelection(selected);
      _syncActedBadge(marine.actionPoints == 0);
      return;
    }

    if (position.distanceTo(target) > 1) {
      current = UnitState.walk;
      children.whereType<MoveToEffect>().forEach((e) => e.removeFromParent());
      add(
        MoveToEffect(
          target,
          EffectController(duration: 0.46, curve: Curves.easeOutCubic),
          onComplete: () => current = UnitState.idle,
        ),
      );
    }

    opacity = marine.hp <= 0 ? 0.35 : 1;
    _syncSelection(selected);
    _syncActedBadge(marine.actionPoints == 0);
  }

  void pulseAttack() {
    if (!_animationsReady) return;
    if (current == UnitState.dead) return;

    current = UnitState.attack;
    add(
      ScaleEffect.to(
        Vector2.all(1.15),
        EffectController(duration: 0.08, reverseDuration: 0.1),
        onComplete: () {
          if (marineState.hp > 0) current = UnitState.idle;
        },
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_animationsReady) return;
    if (current != UnitState.idle) return;
    _idleTime += dt;
    final pulse = 1.0 + sin(_idleTime * 5.5 + index) * 0.03;
    scale = Vector2.all(pulse);
  }

  void _syncSelection(bool selected) {
    if (selected && _selectionRing == null) {
      _selectionRing = CircleComponent(
        radius: size.x * 0.58,
        anchor: Anchor.center,
        position: size / 2,
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFD8A93A),
      );
      add(_selectionRing!);
    } else if (!selected && _selectionRing != null) {
      _selectionRing!.removeFromParent();
      _selectionRing = null;
    }
  }

  void _syncActedBadge(bool acted) {
    if (acted && _actedBadge == null) {
      _actedBadge = RectangleComponent(
        size: Vector2(size.x * 0.52, 5),
        position: Vector2(size.x * 0.24, size.y + 2),
        paint: Paint()..color = const Color(0xFF87919C),
      );
      add(_actedBadge!);
    } else if (!acted && _actedBadge != null) {
      _actedBadge!.removeFromParent();
      _actedBadge = null;
    }
  }
}
