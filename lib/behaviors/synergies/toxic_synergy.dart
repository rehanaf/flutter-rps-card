import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class ToxicSynergy implements SynergyBehavior {
  @override
  String get id => 'toxic';

  @override
  String apply(Player player, Player enemy, int count) {
    if (count >= 6) {
      enemy.addEffect(StatusEffect(type: EffectType.dot, value: 10));
      enemy.addEffect(StatusEffect(type: EffectType.damageReduce, value: 2));
      return "DoT 10, Weaken (2 Turn)";
    } else if (count >= 4) {
      enemy.addEffect(StatusEffect(type: EffectType.dot, value: 5));
      return "DoT 5";
    } else if (count >= 2) {
      enemy.addEffect(StatusEffect(type: EffectType.dot, value: 2));
      return "DoT 2";
    }
    return "";
  }
}
