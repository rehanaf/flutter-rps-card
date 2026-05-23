import 'package:flutter/material.dart';

enum EffectType { 
  strength, 
  shield, 
  counter, 
  immunity, 
  dot, 
  damageReduce, 
  vulnerable,
  heal
}

class StatusEffect {
  final EffectType type;
  int value;

  StatusEffect({
    required this.type,
    required this.value,
  });

  bool get isBuff =>
      type == EffectType.strength ||
      type == EffectType.shield ||
      type == EffectType.counter ||
      type == EffectType.immunity ||
      type == EffectType.heal;

  bool get isDebuff => !isBuff;

  String get name {
    switch (type) {
      case EffectType.strength:
        return "Strength";
      case EffectType.shield:
        return "Shield";
      case EffectType.counter:
        return "Counter";
      case EffectType.immunity:
        return "Immunity";
      case EffectType.dot:
        return "DoT";
      case EffectType.damageReduce:
        return "Weaken";
      case EffectType.vulnerable:
        return "Vulnerable";
      case EffectType.heal:
        return "Heal";
    }
  }

  IconData get icon {
    switch (type) {
      case EffectType.strength:
        return Icons.fitness_center;
      case EffectType.shield:
        return Icons.shield;
      case EffectType.counter:
        return Icons.replay;
      case EffectType.immunity:
        return Icons.gpp_good;
      case EffectType.dot:
        return Icons.water_drop;
      case EffectType.damageReduce:
        return Icons.heart_broken;
      case EffectType.vulnerable:
        return Icons.coronavirus;
      case EffectType.heal:
        return Icons.healing_rounded;
    }
  }

  Color get badgeColor {
    switch (type) {
      case EffectType.strength:
        return Colors.orange[800]!;
      case EffectType.shield:
        return Colors.blue[700]!;
      case EffectType.counter:
        return Colors.amber[700]!;
      case EffectType.immunity:
        return Colors.purple[700]!;
      case EffectType.dot:
        return Colors.red[900]!;
      case EffectType.damageReduce:
        return Colors.grey[700]!;
      case EffectType.vulnerable:
        return Colors.deepOrange[900]!;
      case EffectType.heal:
        return Colors.greenAccent[700]!;
    }
  }
}