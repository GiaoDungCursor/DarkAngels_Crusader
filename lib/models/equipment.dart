import 'package:flutter/material.dart';

enum WeaponType { boltgun, plasma, heavyBolter, flamer, chainsword, sniper }

enum ArmorType { scout, powerArmor, terminator }

class Weapon {
  final String name;
  final WeaponType type;
  final int damage;
  final double range;
  final double fireRate; // attacks per second
  final bool canOverheat;
  final bool isAoE;

  const Weapon({
    required this.name,
    required this.type,
    required this.damage,
    required this.range,
    required this.fireRate,
    this.canOverheat = false,
    this.isAoE = false,
  });
}

class Armor {
  final String name;
  final ArmorType type;
  final int defense;
  final double speedModifier;

  const Armor({
    required this.name,
    required this.type,
    required this.defense,
    required this.speedModifier,
  });
}

class Perk {
  final String name;
  final String description;
  final IconData icon;

  const Perk(this.name, this.description, this.icon);
}
