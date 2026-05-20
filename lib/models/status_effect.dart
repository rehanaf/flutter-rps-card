import 'package:flutter/material.dart';

enum EffectType { 
  damageReduce,
  burn,
  healOverTime,
  damageBuff
}

class StatusEffect {
  final EffectType type;
  final String name;
  final double value;
  int duration;

  StatusEffect({
    required this.type,
    required this.name,
    required this.value,
    required this.duration,
  });

  void decreaseDuration() {
    duration--;
  }

  bool get isExpired => duration <= 0;

  IconData get icon {
    switch (type) {
      case EffectType.damageReduce:
        return Icons.heart_broken;
      case EffectType.burn:
        return Icons.local_fire_department;
      case EffectType.healOverTime:
        return Icons.favorite;
      case EffectType.damageBuff:
        return Icons.arrow_upward;
    }
  }

  Color get badgeColor {
    switch (type) {
      case EffectType.damageReduce:
        return Colors.red[900]!;
      case EffectType.burn:
        return Colors.orange[800]!;
      case EffectType.healOverTime:
      case EffectType.damageBuff:
        return Colors.green[700]!;
    }
  }
}