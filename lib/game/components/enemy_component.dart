import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../models/enemy_unit.dart';
import '../../providers/game_state_provider.dart';
import '../crusade_game.dart';
import 'unit_state.dart';

class EnemyComponent extends SpriteGroupComponent<UnitState>
    with HasGameReference<CrusadeGame>, TapCallbacks {
  EnemyComponent({
    required this.enemyId,
    required EnemyUnit enemy,
    required Vector2 position,
  }) : enemyState = enemy,
       super(
         position: position,
         size: Vector2.all(CrusadeGame.tileSize * 0.76),
       ) {
    anchor = Anchor.center;
  }

  final String enemyId;
  EnemyUnit enemyState;
  RectangleComponent? _hpBar;
  double _idleTime = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprites = {
      UnitState.idle: await game.loadSprite('enemy_idle.png'),
      UnitState.walk: await game.loadSprite('enemy_walk.png'),
      UnitState.attack: await game.loadSprite('enemy_attack.png'),
      UnitState.dead: await game.loadSprite('enemy_dead.png'),
    };
    current = UnitState.idle;

    _hpBar = RectangleComponent(
      position: Vector2(6, -8),
      size: Vector2(size.x - 12, 5),
      paint: Paint()..color = const Color(0xFFFF6B5F),
    );
    add(_hpBar!);
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.attackEnemy(enemyId);
  }

  void sync(EnemyUnit enemy) {
    enemyState = enemy;
    final target = game.gridToWorld(enemy.position);

    if (enemy.hp <= 0) {
      current = UnitState.dead;
      _hpBar?.setOpacity(0);
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
    _hpBar?.size.x = (size.x - 12) * (enemy.hp / enemy.maxHp).clamp(0, 1);
  }

  void pulseHit() {
    if (current == UnitState.dead) return;
    current = UnitState.attack;
    add(
      ScaleEffect.to(
        Vector2.all(0.84),
        EffectController(duration: 0.08, reverseDuration: 0.1),
        onComplete: () {
          if (enemyState.hp > 0) current = UnitState.idle;
        },
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (current != UnitState.idle) return;
    _idleTime += dt;
    final pulse = 1.0 + sin(_idleTime * 4.8 + enemyId.hashCode) * 0.025;
    scale = Vector2.all(pulse);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Only draw intent during marine phase and when alive
    final state = game.gameState;
    if (enemyState.hp <= 0 || state.activationPhase != ActivationPhase.marines) {
      return;
    }

    final target = state.getTargetFor(enemyState);
    if (target != null) {
      final targetWorldPos = game.gridToWorld(target.gridPosition);
      final localTarget = targetWorldPos - position;
      
      final paint = Paint()
        ..color = const Color(0x66FF6B5F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      // Draw dashed line
      _drawDashedLine(canvas, Offset.zero, Offset(localTarget.x, localTarget.y), paint, 4, 4);
      
      // Draw intent icon (e.g. an exclamation mark or target indicator) at the end or midway
      final iconPaint = TextPainter(
        text: const TextSpan(
          text: '!',
          style: TextStyle(
            color: Color(0xFFFF6B5F),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      final midPoint = Offset(localTarget.x * 0.3, localTarget.y * 0.3);
      iconPaint.paint(canvas, midPoint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, double dash, double gap) {
    var dx = p2.dx - p1.dx;
    var dy = p2.dy - p1.dy;
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return;
    
    dx /= length;
    dy /= length;
    
    var currentLength = 0.0;
    
    while (currentLength < length) {
      final endLength = min(currentLength + dash, length);
      canvas.drawLine(
        Offset(p1.dx + dx * currentLength, p1.dy + dy * currentLength),
        Offset(p1.dx + dx * endLength, p1.dy + dy * endLength),
        paint,
      );
      currentLength += dash + gap;
    }
  }
}
