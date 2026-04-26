import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/grid_position.dart';
import '../crusade_game.dart';

class CoverComponent extends PositionComponent
    with HasGameReference<CrusadeGame> {
  CoverComponent({required this.gridPosition})
    : super(size: Vector2.all(CrusadeGame.tileSize)) {
    anchor = Anchor.topLeft;
  }

  final GridPosition gridPosition;

  final Paint _basePaint = Paint()..color = const Color(0xAA3E4C59);
  final Paint _edgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = const Color(0x665D6D7E);
  final Paint _shadowPaint = Paint()..color = const Color(0x44000000);
  final Paint _stripePaint = Paint()..color = const Color(0x337F8C8D);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = game.gridToTileTopLeft(gridPosition);
  }

  @override
  void render(Canvas canvas) {
    final crate = Rect.fromLTWH(11, 14, size.x - 22, size.y - 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(crate.translate(3, 4), const Radius.circular(3)),
      _shadowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(crate, const Radius.circular(3)),
      _basePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(crate, const Radius.circular(3)),
      _edgePaint,
    );

    for (var x = crate.left + 4; x < crate.right - 8; x += 14) {
      final path = Path()
        ..moveTo(x, crate.bottom - 7)
        ..lineTo(x + 7, crate.bottom - 7)
        ..lineTo(x + 14, crate.bottom - 18)
        ..lineTo(x + 7, crate.bottom - 18)
        ..close();
      canvas.drawPath(path, _stripePaint);
    }

    canvas.drawLine(
      Offset(crate.left + 6, crate.top + 12),
      Offset(crate.right - 6, crate.top + 12),
      Paint()
        ..strokeWidth = 2
        ..color = const Color(0xFF151A1F),
    );
  }
}
