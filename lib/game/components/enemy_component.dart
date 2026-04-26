import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../models/enemy_unit.dart';
import '../../providers/game_state_provider.dart';
import '../crusade_game.dart';
import 'unit_state.dart';

class EnemyComponent extends SpriteAnimationGroupComponent<UnitState>
    with HasGameReference<CrusadeGame>, TapCallbacks {
  EnemyComponent({
    required this.enemyId,
    required EnemyUnit enemy,
    required Vector2 position,
  }) : enemyState = enemy,
       super(
         position: position,
         size: Vector2.all(
           enemy.kind == EnemyKind.orkWarboss
               ? CrusadeGame.tileSize * 2.2
               : CrusadeGame.tileSize * 0.76,
         ),
       ) {
    anchor = Anchor.center;
  }

  final String enemyId;
  EnemyUnit enemyState;
  RectangleComponent? _hpBar;
  double _idleTime = 0;
  bool _animationsReady = false;

  Future<SpriteAnimation> _loadAnim(String path) async {
    final img = await game.images.load(path);
    return SpriteAnimation.spriteList([Sprite(img)], stepTime: 1.0);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final isBoss = enemyState.kind == EnemyKind.orkWarboss;
    final prefix = isBoss ? 'ork_warboss' : 'enemy';

    animations = {
      UnitState.idle: await _loadAnim('sprites/enemies/${prefix}_idle.png'),
      UnitState.walk: await _loadAnim('sprites/enemies/${prefix}_walk.png'),
      UnitState.attack: await _loadAnim('sprites/enemies/${prefix}_attack.png'),
      UnitState.dead: await _loadAnim('sprites/enemies/${prefix}_dead.png'),
    };
    _animationsReady = true;
    current = UnitState.idle;

    _hpBar = RectangleComponent(
      position: Vector2(size.x * 0.1, -12),
      size: Vector2(size.x * 0.8, 4),
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

    if (!_animationsReady) {
      position = target;
      return;
    }

    if (enemy.hp <= 0) {
      if (current != UnitState.dead) {
        current = UnitState.dead;
        _hpBar?.setOpacity(0);
        // Procedural Death: Fall over
        add(
          RotateEffect.to(
            pi / 2, // 90 degrees
            EffectController(duration: 0.4, curve: Curves.easeIn),
          ),
        );
        add(OpacityEffect.to(0.4, EffectController(duration: 0.8)));
      }
      return;
    }

    if (position.distanceTo(target) > 1) {
      current = UnitState.walk;
      children.whereType<MoveToEffect>().forEach((e) => e.removeFromParent());
      children.whereType<RotateEffect>().forEach((e) => e.removeFromParent());

      // Procedural Walk: Move and Waddle
      add(
        MoveToEffect(
          target,
          EffectController(duration: 0.46, curve: Curves.easeOutCubic),
          onComplete: () {
            current = UnitState.idle;
            angle = 0; // Reset rotation
          },
        ),
      );
      add(
        RotateEffect.by(
          0.15,
          EffectController(
            duration: 0.15,
            reverseDuration: 0.15,
            repeatCount: 2,
          ),
        ),
      );
    }
    _hpBar?.size.x = (size.x - 12) * (enemy.hp / enemy.maxHp).clamp(0, 1);
  }

  void pulseHit() {
    if (!_animationsReady) return;
    if (current == UnitState.dead) return;
    current = UnitState.attack;

    // Procedural Attack: Lunge forward and scale up
    add(
      ScaleEffect.to(
        Vector2.all(1.2), // Lunge big
        EffectController(duration: 0.08, reverseDuration: 0.15),
        onComplete: () {
          if (enemyState.hp > 0) current = UnitState.idle;
        },
      ),
    );
    add(
      RotateEffect.to(
        -0.2, // Lean into the attack
        EffectController(duration: 0.08, reverseDuration: 0.15),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_animationsReady) return;
    if (current != UnitState.idle) return;
    _idleTime += dt;
    // Procedural Idle: Subtle breathing scale and slight float
    final pulseY = 1.0 + sin(_idleTime * 4.0 + enemyId.hashCode) * 0.03;
    final pulseX = 1.0 - sin(_idleTime * 4.0 + enemyId.hashCode) * 0.01;
    scale = Vector2(pulseX, pulseY);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Only draw intent during marine phase and when alive
    final state = game.gameState;
    if (enemyState.hp <= 0 ||
        state.activationPhase != ActivationPhase.marines) {
      return;
    }

    final target = state.getTargetFor(enemyState);
    final selected = state.selectedMarine;
    if (target == null ||
        selected == null ||
        selected.gridPosition.distanceTo(enemyState.position) > 6) {
      return;
    }

    final targetWorldPos = game.gridToWorld(target.gridPosition);
    final localTarget = targetWorldPos - position;

    final paint = Paint()
      ..color = const Color(0x22FF6B5F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw dashed line
    _drawDashedLine(
      canvas,
      Offset.zero,
      Offset(localTarget.x, localTarget.y),
      paint,
      4,
      4,
    );

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

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
    double dash,
    double gap,
  ) {
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
