import 'dart:math';
import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class AirSynergy implements SynergyBehavior {
  @override
  String get id => 'air';

  @override
  String apply(Player player, Player enemy, int count) {
    double chance = 0.0;
    if (count >= 5) {
      chance = 0.5;
    } else if (count >= 4) {
      chance = 0.3;
    } else if (count >= 2) {
      chance = 0.15;
    }

    if (chance > 0 && Random().nextDouble() < chance) {
      player.addEffect(StatusEffect(type: EffectType.immunity, value: 1));
      return "Immunity (1 Turn)";
    }
    return "";
  }
}
