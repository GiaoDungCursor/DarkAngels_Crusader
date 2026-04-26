import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_state_provider.dart';
import '../models/equipment.dart';

class ArmoryScreen extends ConsumerWidget {
  final int selectedMarineIndex;

  const ArmoryScreen({super.key, required this.selectedMarineIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final marine = state.squad[selectedMarineIndex];

    const plasmaGun = Weapon(
      name: 'Plasma Gun',
      type: WeaponType.plasma,
      damage: 30,
      range: 3.0,
      fireRate: 0.5,
    );
    const terminatorArmor = Armor(
      name: 'Terminator Armor',
      type: ArmorType.terminator,
      defense: 8,
      speedModifier: 0.7,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final cardWidth = compact
              ? MediaQuery.sizeOf(context).width - 96
              : 260.0;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.sizeOf(context).height * 0.86,
            ),
            child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/backgrounds/armory_background.png'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8A93A), width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(compact ? 16 : 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SHIP ARMORY',
                            style: TextStyle(
                              color: Color(0xFFD8A93A),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'RP: ${state.requisitionPoints}',
                            style: const TextStyle(
                              color: Color(0xFF77D48B),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFD8A93A)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xEE0E151D),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF31404C)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD8A93A,
                              ).withValues(alpha: 0.18),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundImage: marine.portrait != null
                                  ? AssetImage(marine.portrait!)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SELECTED BATTLE-BROTHER',
                                    style: TextStyle(
                                      color: Color(0xFFD8A93A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    marine.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${marine.role}\nWeapon: ${marine.weapon.name}\nArmor: ${marine.armor.name}',
                                    style: const TextStyle(
                                      color: Color(0xFFB9C3CC),
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Choose one upgrade. Spending RP applies immediately.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _UpgradeCard(
                              title: 'Plasma Gun',
                              description:
                                  'High damage, low fire rate. Great for heavily armored targets.',
                              cost: 20,
                              icon: Icons.flash_on,
                              canAfford: state.requisitionPoints >= 20,
                              onTap: () {
                                if (ref
                                    .read(gameStateProvider.notifier)
                                    .useRP(20)) {
                                  ref
                                      .read(gameStateProvider.notifier)
                                      .upgradeWeapon(
                                        selectedMarineIndex,
                                        plasmaGun,
                                      );
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _UpgradeCard(
                              title: 'Terminator Armor',
                              description:
                                  'Massive defense boost. Slows movement slightly.',
                              cost: 50,
                              icon: Icons.shield,
                              canAfford: state.requisitionPoints >= 50,
                              onTap: () {
                                if (ref
                                    .read(gameStateProvider.notifier)
                                    .useRP(50)) {
                                  ref
                                      .read(gameStateProvider.notifier)
                                      .upgradeArmor(
                                        selectedMarineIndex,
                                        terminatorArmor,
                                      );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'CLOSE',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final String title;
  final String description;
  final int cost;
  final IconData icon;
  final bool canAfford;
  final VoidCallback onTap;

  const _UpgradeCard({
    required this.title,
    required this.description,
    required this.cost,
    required this.icon,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canAfford ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: canAfford ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xEE131C25),
            border: Border.all(
              color: canAfford
                  ? const Color(0xFFD8A93A)
                  : const Color(0xFF253342),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFFD8A93A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    canAfford ? '$cost RP' : 'Need $cost RP',
                    style: TextStyle(
                      color: canAfford
                          ? const Color(0xFF77D48B)
                          : const Color(0xFFFFB15E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Color(0xFF9FAAB5), fontSize: 12),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    canAfford ? Icons.check_circle : Icons.lock,
                    color: canAfford
                        ? const Color(0xFF77D48B)
                        : const Color(0xFFFFB15E),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    canAfford ? 'Tap to equip' : 'Insufficient RP',
                    style: TextStyle(
                      color: canAfford
                          ? const Color(0xFF77D48B)
                          : const Color(0xFFFFB15E),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
