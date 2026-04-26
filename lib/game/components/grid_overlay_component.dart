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
  final Paint _blockedPaint = Paint()..color = const Color(0x66101218);
  final Paint _voidPaint = Paint()..color = const Color(0x992A0D16);
  final Paint _bridgePaint = Paint()..color = const Color(0x3333D6A6);
  final Paint _hazardPaint = Paint()..color = const Color(0x66E56B2F);

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

        if (snapshot.map.isWalkable(tile)) {
          _drawWalkableBase(canvas, rect);
        }

        if (snapshot.map.voidTiles.contains(tile)) {
          canvas.drawRect(rect, _voidPaint);
          _drawWarningBorder(canvas, rect);
        } else if (snapshot.map.blockedTiles.contains(tile)) {
          canvas.drawRect(rect, _blockedPaint);
          _drawWarningBorder(canvas, rect);
        } else if (snapshot.map.bridgeTiles.contains(tile)) {
          canvas.drawRect(rect, _bridgePaint);
        } else if (snapshot.map.hazardTiles.contains(tile)) {
          canvas.drawRect(rect, _hazardPaint);
        }

        if (snapshot.coverTiles.contains(tile)) {
          _drawCover(canvas, rect);
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
          _drawTileGlyph(canvas, rect, Icons.cell_tower, const Color(0xFF33D6A6));
        }
        if (snapshot.activationPhase == ActivationPhase.deployment) {
          if (snapshot.map.marineSpawns.contains(tile)) {
            canvas.drawRect(
              rect,
              Paint()..color = const Color(0x3333D6A6),
            );
            canvas.drawRect(
              rect.deflate(2),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = const Color(0xAA33D6A6),
            );
          }
          if (snapshot.selectedDropZones.contains(tile)) {
            _drawTileGlyph(canvas, rect, Icons.my_location, const Color(0xFF33D6A6));
          }
        }
        if (snapshot.highlightedTiles.contains(tile)) {
          var paint = _movePaint;
          if (snapshot.actionMode == ActionMode.move) {
            final threat = snapshot.movementThreats[tile];
            paint = switch (threat) {
              ThreatLevel.safe => Paint()..color = const Color(0x6633D6A6), // Green
              ThreatLevel.warning => Paint()..color = const Color(0x77FFB15E), // Yellow
              ThreatLevel.danger => Paint()..color = const Color(0x77FF6B5F), // Red
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

  void _drawWarningBorder(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE56B2F);
    canvas.drawRect(rect.deflate(2), paint);
    
    // Draw some diagonal stripes on the edges
    final stripePaint = Paint()
      ..color = const Color(0x44E56B2F)
      ..strokeWidth = 2;
    for (var i = 0; i < rect.width; i += 8) {
      canvas.drawLine(
        Offset(rect.left + i, rect.top),
        Offset(rect.left + i + 4, rect.top + 4),
        stripePaint,
      );
    }
  }

  void _drawWalkableBase(Canvas canvas, Rect rect) {
    final paint = Paint()..color = const Color(0xFF1E293B); // Slate-800
    canvas.drawRect(rect, paint);
    
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x11FFFFFF);
    
    // Draw an inner border for the metal plate look
    canvas.drawRect(rect.deflate(2), gridPaint);
  }

  void _drawCover(Canvas canvas, Rect rect) {
    final basePaint = Paint()..color = const Color(0xFF334155); // Slate-700
    final topPaint = Paint()..color = const Color(0xFF475569); // Slate-600
    
    // Draw a blocky barricade
    final block = Rect.fromLTRB(rect.left + 4, rect.top + 8, rect.right - 4, rect.bottom - 8);
    canvas.drawRect(block, basePaint);
    
    // Draw top highlight
    final highlight = Rect.fromLTRB(block.left, block.top, block.right, block.top + 4);
    canvas.drawRect(highlight, topPaint);
  }
}
