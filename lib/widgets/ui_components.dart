import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../providers/game_state_provider.dart';

class HeaderCard extends StatelessWidget {
  const HeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15120D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4B3920)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFD8A93A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF101010)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFFB9C3CC)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEE111922),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF263440)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...(action == null ? const <Widget>[] : <Widget>[action!]),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow(this.label, this.value, this.progress, {super.key});

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Color(0xFFB9C3CC)),
                ),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: const Color(0xFF2B343D),
              color: const Color(0xFFD8A93A),
            ),
          ),
        ],
      ),
    );
  }
}

class MissionTile extends StatelessWidget {
  const MissionTile({
    super.key,
    required this.mission,
    required this.selected,
    required this.onTap,
  });

  final Mission mission;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2A2115) : const Color(0xFF121B24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD8A93A)
                  : const Color(0xFF263440),
            ),
          ),
          child: Row(
            children: [
              Icon(mission.icon, color: const Color(0xFFD8A93A)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      mission.subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9FAAB5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${mission.threat}%',
                style: const TextStyle(
                  color: Color(0xFFFFB15E),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BattleLog extends StatelessWidget {
  const BattleLog({super.key, required this.entries});

  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E151D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF263440)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal, size: 18, color: Color(0xFFD8A93A)),
              SizedBox(width: 8),
              Text('Battle Log', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                entry,
                style: const TextStyle(color: Color(0xFFB9C3CC), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class TacticalActionBar extends StatelessWidget {
  const TacticalActionBar({
    super.key,
    required this.currentMode,
    required this.isMissionActive,
    required this.canMove,
    required this.canAttack,
    required this.onModeChanged,
    required this.onOpenArmory,
    required this.onEndTurn,
  });

  final ActionMode? currentMode;
  final bool isMissionActive;
  final bool canMove;
  final bool canAttack;
  final Function(ActionMode) onModeChanged;
  final VoidCallback onOpenArmory;
  final VoidCallback onEndTurn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF151C24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF263440), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  context,
                  label: 'Move 2',
                  icon: Icons.open_with,
                  tooltip: 'Move the active marine up to 2 legal tiles.',
                  isActive: currentMode == ActionMode.move && isMissionActive,
                  isDisabled: !isMissionActive || !canMove,
                  onTap: () => onModeChanged(ActionMode.move),
                ),
                _buildActionButton(
                  context,
                  label: 'Shoot 3',
                  icon: Icons.gps_fixed,
                  tooltip: 'Shoot enemies within 3 tiles and line of sight.',
                  isActive: currentMode == ActionMode.shoot && isMissionActive,
                  isDisabled: !isMissionActive || !canAttack,
                  onTap: () => onModeChanged(ActionMode.shoot),
                ),
                _buildActionButton(
                  context,
                  label: 'Melee 1',
                  icon: Icons.hardware,
                  tooltip: 'Attack an adjacent enemy within 1 tile.',
                  isActive: currentMode == ActionMode.melee && isMissionActive,
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
                  tooltip: 'Hold position and fire at enemies entering sight.',
                  isActive:
                      currentMode == ActionMode.overwatch && isMissionActive,
                  isDisabled: !isMissionActive || !canAttack,
                  onTap: () => onModeChanged(ActionMode.overwatch),
                ),
                _buildActionButton(
                  context,
                  label: 'Armory',
                  icon: Icons.build,
                  tooltip: 'Open ship armory upgrades.',
                  isActive: false,
                  isDisabled: !isMissionActive,
                  onTap: onOpenArmory,
                ),
                _buildActionButton(
                  context,
                  label: 'Beacon',
                  icon: Icons.flare,
                  tooltip: 'Deploy a drop beacon to create a new reserve drop zone. Requires Commander or Techmarine.',
                  isActive:
                      currentMode == ActionMode.deployBeacon && isMissionActive,
                  isDisabled: !isMissionActive || !canAttack,
                  onTap: () => onModeChanged(ActionMode.deployBeacon),
                ),
                _buildActionButton(
                  context,
                  label: 'Plant Bomb',
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
          const SizedBox(width: 16),
          _buildEndTurnButton(context),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? const Color(0xFFD8A93A) : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
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

  Widget _buildEndTurnButton(BuildContext context) {
    return InkWell(
      onTap: isMissionActive ? onEndTurn : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isMissionActive
              ? const Color(0xFF9A3232)
              : const Color(0xFF3A1C1C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMissionActive
                ? const Color(0xFFE55A5A)
                : const Color(0xFF5A2A2A),
            width: 2,
          ),
          boxShadow: isMissionActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFE55A5A).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.skip_next,
              color: isMissionActive ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              'END TURN',
              style: TextStyle(
                color: isMissionActive ? Colors.white : Colors.white54,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
