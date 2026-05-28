import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class CosmicSynergy implements SynergyBehavior {
  @override
  String get id => 'cosmic';

  @override
  String apply(Player player, Player enemy, int count) {
    if (count >= 5) {
      enemy.addEffect(StatusEffect(type: EffectType.vulnerable, value: 4));
      return "Vulnerable (4 Turn)";
    } else if (count >= 4) {
      enemy.addEffect(StatusEffect(type: EffectType.vulnerable, value: 2));
      return "Vulnerable (2 Turn)";
    } else if (count >= 2) {
      enemy.addEffect(StatusEffect(type: EffectType.vulnerable, value: 1));
      return "Vulnerable (1 Turn)";
    }
    return "";
  }
}
