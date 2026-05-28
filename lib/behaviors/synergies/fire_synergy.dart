import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class FireSynergy implements SynergyBehavior {
  @override
  String get id => 'fire';

  @override
  String apply(Player player, Player enemy, int count) {
    if (count >= 6) {
      enemy.addEffect(StatusEffect(type: EffectType.dot, value: 12));
      enemy.addEffect(StatusEffect(type: EffectType.vulnerable, value: 2));
      return "DoT 12, Vulnerable (2 Turn)";
    } else if (count >= 4) {
      enemy.addEffect(StatusEffect(type: EffectType.dot, value: 7));
      return "DoT 7";
    } else if (count >= 2) {
      enemy.addEffect(StatusEffect(type: EffectType.dot, value: 3));
      return "DoT 3";
    }
    return "";
  }
}
