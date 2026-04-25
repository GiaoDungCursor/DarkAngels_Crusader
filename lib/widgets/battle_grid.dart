import 'package:flutter/material.dart';
import '../models/marine.dart';

class TacticalBoard extends StatelessWidget {
  const TacticalBoard({
    super.key,
    required this.columns,
    required this.rows,
    required this.marines,
    required this.enemies,
    required this.ruins,
    required this.selectedMarine,
    required this.onSelectMarine,
    required this.onMove,
  });

  final int columns;
  final int rows;
  final List<Marine> marines;
  final List<Offset> enemies;
  final Set<Offset> ruins;
  final int selectedMarine;
  final ValueChanged<int> onSelectMarine;
  final ValueChanged<Offset> onMove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1,
      ),
      itemCount: columns * rows,
      itemBuilder: (context, index) {
        final x = index % columns;
        final y = index ~/ columns;
        final position = Offset(x.toDouble(), y.toDouble());
        final marineIndex = marines.indexWhere(
          (marine) => marine.position == position,
        );
        final enemy = enemies.contains(position);
        final ruin = ruins.contains(position);
        final selected = marineIndex == selectedMarine;

        return Padding(
          padding: const EdgeInsets.all(3),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              if (marineIndex >= 0) {
                onSelectMarine(marineIndex);
              } else {
                onMove(position);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: enemy
                    ? const Color(0xFF541F21)
                    : ruin
                    ? const Color(0xFF2D3136)
                    : const Color(0xFF172330),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFD8A93A)
                      : const Color(0xFF2F3E4E),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFD8A93A,
                          ).withValues(alpha: 0.26),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 6,
                    top: 4,
                    child: Text(
                      '$x$y',
                      style: const TextStyle(
                        color: Color(0xFF617080),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Center(
                    child: BoardMarker(
                      marine: marineIndex >= 0 ? marines[marineIndex] : null,
                      enemy: enemy,
                      ruin: ruin,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class BoardMarker extends StatelessWidget {
  const BoardMarker({
    super.key,
    this.marine,
    required this.enemy,
    required this.ruin,
  });

  final Marine? marine;
  final bool enemy;
  final bool ruin;

  @override
  Widget build(BuildContext context) {
    if (marine != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(marine!.icon, size: 24, color: const Color(0xFFD8A93A)),
          Text(
            marine!.name.split(' ').last.substring(0, 1),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      );
    }
    if (enemy) {
      return const Icon(Icons.dangerous, color: Color(0xFFFF6B5F), size: 28);
    }
    if (ruin) {
      return const Icon(Icons.foundation, color: Color(0xFF8E99A4), size: 24);
    }
    return const SizedBox.shrink();
  }
}
