import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../models/marine.dart';
import '../crusade_game.dart';
import 'unit_state.dart';

class MarineComponent extends SpriteGroupComponent<UnitState>
    with HasGameReference<CrusadeGame>, TapCallbacks {
  MarineComponent({
    required this.index,
    required Marine marine,
    required Vector2 position,
  }) : marineState = marine,
       super(
         position: position,
         size: Vector2.all(CrusadeGame.tileSize * 0.78),
       ) {
    anchor = Anchor.center;
  }

  final int index;
  Marine marineState;
  CircleComponent? _selectionRing;
  RectangleComponent? _actedBadge;
  double _idleTime = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final idleSprite = await game.loadSprite('marine_idle.png');
    final walkSprite = await game.loadSprite('marine_walk.png');
    final attackSprite = await game.loadSprite('marine_attack.png');
    final deadSprite = await game.loadSprite('marine_dead.png');

    sprites = {
      UnitState.idle: idleSprite,
      UnitState.walk: walkSprite,
      UnitState.attack: attackSprite,
      UnitState.dead: deadSprite,
    };

    current = UnitState.idle;
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.selectMarine(index);
  }

  void sync(Marine marine, {required bool selected}) {
    marineState = marine;
    final target = game.gridToWorld(marine.gridPosition);

    if (marine.hp <= 0) {
      current = UnitState.dead;
      opacity = 0.8;
      _syncSelection(selected);
      _syncActedBadge(marine.hasMoved && marine.hasAttacked);
      return;
    }

    if (position.distanceTo(target) > 1) {
      current = UnitState.walk;
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
    _syncActedBadge(marine.hasMoved && marine.hasAttacked);
  }

  void pulseAttack() {
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
