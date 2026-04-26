import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../models/grid_position.dart';
import '../../providers/game_state_provider.dart';
import '../crusade_game.dart';

class GridOverlayComponent extends PositionComponent
    with HasGameReference<CrusadeGame>, TapCallbacks {
  GridOverlayComponent()
    : super(position: CrusadeGame.boardOrigin, size: Vector2.zero());

  GameState? state;

  final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0x663E4C59);
  final Paint _movePaint = Paint()..color = const Color(0x553A8DFF);
  final Paint _shootPaint = Paint()..color = const Color(0x55FFB15E);
  final Paint _meleePaint = Paint()..color = const Color(0x55FF6B5F);
  final Paint _deployPaint = Paint()..color = const Color(0x6633D6A6);
  final Paint _plantBombPaint = Paint()..color = const Color(0x66C04040);
  final Paint _blockedPaint = Paint()..color = const Color(0x70313A42);
  final Paint _blockedStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const Color(0xAA7B8794);
  final Paint _voidPaint = Paint()..color = const Color(0xB0000000);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final snapshot = state;
    if (snapshot == null) return;

    for (var y = 0; y < snapshot.rows; y++) {
      for (var x = 0; x < snapshot.columns; x++) {
        final tile = GridPosition(x, y);
        final rect = Rect.fromLTWH(
          x * CrusadeGame.tileSize,
          y * CrusadeGame.tileSize,
          CrusadeGame.tileSize,
          CrusadeGame.tileSize,
        ).deflate(3);

        if (snapshot.map.voidTiles.contains(tile)) {
          canvas.drawRect(rect, _voidPaint);
          _drawCross(canvas, rect, const Color(0xFF2B3440));
        } else if (snapshot.map.blockedTiles.contains(tile)) {
          final blockedRect = rect.deflate(4);
          canvas.drawRRect(
            RRect.fromRectAndRadius(blockedRect, const Radius.circular(4)),
            _blockedPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(blockedRect, const Radius.circular(4)),
            _blockedStrokePaint,
          );
          _drawCornerTicks(canvas, blockedRect, const Color(0xCCB8C0CA));
        }

        if (snapshot.coverTiles.contains(tile) ||
            snapshot.dropPodCoverTiles.contains(tile)) {
          _drawTileGlyph(
            canvas,
            rect,
            Icons.shield_outlined,
            const Color(0x88708090),
          );
        }

        if (snapshot.shieldedMarines.contains(tile)) {
          // Draw shield on the marine
          _drawTileGlyph(canvas, rect, Icons.shield, const Color(0xFF3A8DFF));
        }
        if (snapshot.objectiveHighlights.contains(tile)) {
          canvas.drawRect(
            rect.deflate(8),
            Paint()..color = const Color(0x6633D6A6),
          );
        }
        if (snapshot.activeDropBeacons.contains(tile)) {
          canvas.drawRect(
            rect.deflate(6),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0xAA33D6A6),
          );
          _drawTileGlyph(
            canvas,
            rect,
            Icons.cell_tower,
            const Color(0xFF33D6A6),
          );
        }
        // Deployment rendering removed
        if (snapshot.highlightedTiles.contains(tile)) {
          var paint = _movePaint;
          if (snapshot.actionMode == ActionMode.move) {
            final threat = snapshot.movementThreats[tile];
            paint = switch (threat) {
              ThreatLevel.safe => Paint()..color = const Color(0x332ECC71),
              ThreatLevel.warning => Paint()..color = const Color(0x44F1C40F),
              ThreatLevel.danger => Paint()..color = const Color(0x44E74C3C),
              null => _movePaint,
            };
          } else {
            paint = switch (snapshot.actionMode) {
              ActionMode.shoot => _shootPaint,
              ActionMode.melee => _meleePaint,
              ActionMode.ability => _shootPaint,
              ActionMode.overwatch => _shootPaint,
              ActionMode.deployReserve => _deployPaint,
              ActionMode.plantBomb => _plantBombPaint,
              _ => _movePaint,
            };
          }
          canvas.drawRect(rect, paint);
        }
        canvas.drawRect(rect, _linePaint);
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tile = game.worldToGrid(event.localPosition + position);
    if (tile != null) {
      game.handleTileTap(tile);
    }
  }

  void _drawTileGlyph(Canvas canvas, Rect rect, IconData icon, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  void _drawCross(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
    canvas.drawLine(rect.topRight, rect.bottomLeft, paint);
  }

  void _drawCornerTicks(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const length = 8.0;
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(length, 0),
      paint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(0, length),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(-length, 0),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, length),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(length, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(0, -length),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(-length, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(0, -length),
      paint,
    );
  }
}
