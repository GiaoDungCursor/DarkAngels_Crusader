import 'package:flutter/material.dart';
import '../models/marine.dart';
import '../providers/game_state_provider.dart';

class CommandSquarePanel extends StatelessWidget {
  const CommandSquarePanel({
    super.key,
    required this.marine,
    required this.currentMode,
    required this.isMissionActive,
    required this.canMove,
    required this.canAttack,
    required this.onModeChanged,
    required this.onOpenArmory,
  });

  final Marine marine;
  final ActionMode? currentMode;
  final bool isMissionActive;
  final bool canMove;
  final bool canAttack;
  final Function(ActionMode) onModeChanged;
  final VoidCallback onOpenArmory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: const Color(0xE60A1017),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF263440), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF121B24),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD8A93A),
                        width: 2,
                      ),
                      image: marine.portrait != null
                          ? DecorationImage(image: AssetImage(marine.portrait!))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          marine.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          marine.role,
                          style: const TextStyle(
                            color: Color(0xFF9FAAB5),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: marine.hp / marine.maxHp,
                                  backgroundColor: const Color(0xFF1D2630),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFF77D48B),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${marine.hp}/${marine.maxHp}',
                              style: const TextStyle(
                                color: Color(0xFF77D48B),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMMAND CARD',
                    style: TextStyle(
                      color: Color(0xFF9FAAB5),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _CommandToken(
                    label:
                        'AP: ${marine.actionPoints}/${marine.maxActionPoints}',
                    color: marine.actionPoints > 0
                        ? const Color(0xFF3A8DFF)
                        : const Color(0xFF87919C),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getInstruction(currentMode),
                    style: const TextStyle(
                      color: Color(0xFF77D48B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _buildActionButton(
                    context,
                    label: 'Move 1/2 AP',
                    icon: Icons.open_with,
                    tooltip:
                        'Move the active marine up to 2 tiles (1 AP) or 4 tiles (2 AP).',
                    isActive: currentMode == ActionMode.move && isMissionActive,
                    isDisabled: !isMissionActive || !canMove,
                    onTap: () => onModeChanged(ActionMode.move),
                  ),
                  _buildActionButton(
                    context,
                    label: 'Shoot 1 AP',
                    icon: Icons.gps_fixed,
                    tooltip:
                        'Shoot enemies within 3 tiles and line of sight. Costs 1 AP.',
                    isActive:
                        currentMode == ActionMode.shoot && isMissionActive,
                    isDisabled: !isMissionActive || !canAttack,
                    onTap: () => onModeChanged(ActionMode.shoot),
                  ),
                  _buildActionButton(
                    context,
                    label: 'Melee 1 AP',
                    icon: Icons.hardware,
                    tooltip:
                        'Attack an adjacent enemy within 1 tile. Costs 1 AP.',
                    isActive:
                        currentMode == ActionMode.melee && isMissionActive,
                    isDisabled: !isMissionActive || !canAttack,
                    onTap: () => onModeChanged(ActionMode.melee),
                  ),
                  _buildActionButton(
                    context,
                    label: 'Skill CP',
                    icon: Icons.auto_fix_high,
                    tooltip: 'Spend CP on this marine class ability.',
                    isActive:
                        currentMode == ActionMode.ability && isMissionActive,
                    isDisabled: !isMissionActive || !canAttack,
                    onTap: () => onModeChanged(ActionMode.ability),
                  ),
                  _buildActionButton(
                    context,
                    label: 'Guard',
                    icon: Icons.visibility,
                    tooltip:
                        'Hold position and fire at enemies entering sight.',
                    isActive:
                        currentMode == ActionMode.overwatch && isMissionActive,
                    isDisabled: !isMissionActive || !canAttack,
                    onTap: () => onModeChanged(ActionMode.overwatch),
                  ),
                  _buildActionButton(
                    context,
                    label: 'Beacon',
                    icon: Icons.flare,
                    tooltip:
                        'Deploy a drop beacon to create a new reserve drop zone. Requires Commander or Techmarine.',
                    isActive:
                        currentMode == ActionMode.deployBeacon &&
                        isMissionActive,
                    isDisabled: !isMissionActive || !canAttack,
                    onTap: () => onModeChanged(ActionMode.deployBeacon),
                  ),
                  _buildActionButton(
                    context,
                    label: 'Bomb',
                    icon: Icons.dangerous,
                    tooltip:
                        'Plant an explosive charge on an adjacent enemy base.',
                    isActive:
                        currentMode == ActionMode.plantBomb && isMissionActive,
                    isDisabled: !isMissionActive || !canAttack,
                    onTap: () => onModeChanged(ActionMode.plantBomb),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    final color = isActive ? const Color(0xFFD8A93A) : const Color(0xFF9FAAB5);
    final bgColor = isActive
        ? const Color(0xFF4A3A17)
        : const Color(0xFF1D2630);

    return Tooltip(
      message: isDisabled ? 'Unavailable for this activation.' : tooltip,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 96,
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? const Color(0xFFD8A93A) : Colors.transparent,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInstruction(ActionMode? mode) {
    return switch (mode) {
      ActionMode.move => 'Click a highlighted tile to move.',
      ActionMode.shoot => 'Click a gold target to attack.',
      ActionMode.melee => 'Target an adjacent enemy.',
      ActionMode.ability => 'Use class special ability.',
      ActionMode.overwatch => 'Selected marine is guarding.',
      ActionMode.deployReserve => 'Choose a drop zone for reserve.',
      ActionMode.plantBomb => 'Stand next to enemy base to bomb.',
      ActionMode.deployBeacon => 'Place beacon within 2 tiles.',
      null => 'Select an order, then commit.',
    };
  }
}

class _CommandToken extends StatelessWidget {
  const _CommandToken({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class EndTurnButton extends StatelessWidget {
  const EndTurnButton({
    super.key,
    required this.isMissionActive,
    required this.onEndTurn,
  });

  final bool isMissionActive;
  final VoidCallback onEndTurn;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isMissionActive ? onEndTurn : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMissionActive
              ? const Color(0xFF9A3232)
              : const Color(0xFF3A1C1C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMissionActive
                ? const Color(0xFFE55A5A)
                : const Color(0xFF5A2A2A),
            width: 1.5,
          ),
          boxShadow: isMissionActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFE55A5A).withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.skip_next,
                color: isMissionActive ? Colors.white : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 6),
              const Text(
                'END TURN',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
