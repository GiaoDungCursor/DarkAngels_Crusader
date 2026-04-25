import 'package:flutter/material.dart';

class Mission {
  final String name;
  final String subtitle;
  final IconData icon;
  final int control;
  final int threat;
  final int rewardRP; // Requisition points rewarded

  const Mission(
    this.name,
    this.subtitle,
    this.icon,
    this.control,
    this.threat,
    this.rewardRP,
  );
}
