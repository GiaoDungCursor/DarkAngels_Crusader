import 'package:flutter/material.dart';
import 'equipment.dart';
import 'grid_position.dart';

class Marine {
  final String name;
  final String role;
  final IconData? icon;
  final String? portrait;
  final String spriteKey;

  final int maxHp;
  int hp;

  Weapon weapon;
  Armor armor;
  Perk? perk;

  Offset position;
  GridPosition gridPosition;
  Offset? targetPosition; // For RTS movement
  List<GridPosition> commandPath;
  double commandProgress;
  int actionPoints;
  int maxActionPoints;
  bool isOverwatching;

  Marine({
    required this.name,
    required this.role,
    this.icon,
    this.portrait,
    this.spriteKey = 'marine',
    required this.maxHp,
    required this.hp,
    required this.weapon,
    required this.armor,
    this.perk,
    this.position = const Offset(0, 0),
    this.gridPosition = const GridPosition(0, 0),
    this.targetPosition,
    this.commandPath = const [],
    this.commandProgress = 0,
    this.actionPoints = 2,
    this.maxActionPoints = 2,
    this.isOverwatching = false,
  });

  Marine copyWith({
    int? hp,
    Offset? position,
    GridPosition? gridPosition,
    Offset? targetPosition,
    List<GridPosition>? commandPath,
    double? commandProgress,
    Weapon? weapon,
    Armor? armor,
    Perk? perk,
    int? actionPoints,
    int? maxActionPoints,
    bool? isOverwatching,
  }) {
    return Marine(
      name: name,
      role: role,
      icon: icon,
      portrait: portrait,
      spriteKey: spriteKey,
      maxHp: maxHp,
      hp: hp ?? this.hp,
      weapon: weapon ?? this.weapon,
      armor: armor ?? this.armor,
      perk: perk ?? this.perk,
      position: position ?? this.position,
      gridPosition: gridPosition ?? this.gridPosition,
      targetPosition: targetPosition ?? this.targetPosition,
      commandPath: commandPath ?? this.commandPath,
      commandProgress: commandProgress ?? this.commandProgress,
      actionPoints: actionPoints ?? this.actionPoints,
      maxActionPoints: maxActionPoints ?? this.maxActionPoints,
      isOverwatching: isOverwatching ?? this.isOverwatching,
    );
  }
}
