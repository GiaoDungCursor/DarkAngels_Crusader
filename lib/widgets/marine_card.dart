import 'package:flutter/material.dart';
import '../models/marine.dart';

class MarineTile extends StatelessWidget {
  const MarineTile({
    super.key,
    required this.marine,
    required this.selected,
    required this.onTap,
    this.orderLabel,
  });

  final Marine marine;
  final bool selected;
  final VoidCallback onTap;
  final String? orderLabel;

  @override
  Widget build(BuildContext context) {
    final hpPercent = marine.maxHp > 0 ? marine.hp / marine.maxHp : 0.0;

    final isSpent = marine.actionPoints == 0;
    final actionText = isSpent ? 'spent' : 'AP: ${marine.actionPoints}/${marine.maxActionPoints}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF24313D) : const Color(0xFF131C25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD8A93A)
                  : const Color(0xFF253342),
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: isSpent
                        ? const Color(0xFF30343A)
                        : const Color(0xFF322516),
                    foregroundColor: isSpent
                        ? const Color(0xFF87919C)
                        : const Color(0xFFD8A93A),
                    backgroundImage: marine.portrait == null
                        ? null
                        : AssetImage(marine.portrait!),
                    child: marine.portrait == null
                        ? Icon(marine.icon ?? Icons.shield, size: 20)
                        : null,
                  ),
                  if (orderLabel != null)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 19,
                        height: 19,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFD8A93A)
                              : const Color(0xFF263440),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFF0E151D)),
                        ),
                        child: Text(
                          orderLabel!,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF101010)
                                : const Color(0xFFB9C3CC),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            marine.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          actionText,
                          style: TextStyle(
                            color: isSpent
                                ? const Color(0xFF87919C)
                                : const Color(0xFF77D48B),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${marine.role}  |  AR ${marine.armor.defense}  RNG ${marine.weapon.range.toInt()}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9FAAB5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: hpPercent,
                        minHeight: 5,
                        backgroundColor: const Color(0xFF2B343D),
                        color: hpPercent > 0.45
                            ? const Color(0xFF77D48B)
                            : const Color(0xFFFF6B5F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
