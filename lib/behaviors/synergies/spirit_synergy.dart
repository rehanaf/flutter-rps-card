import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class SpiritSynergy implements SynergyBehavior {
  @override
  String get id => 'spirit';

  @override
  String apply(Player player, Player enemy, int count) {
    if (count >= 9) {
      enemy.addEffect(StatusEffect(type: EffectType.damageReduce, value: 4));
      return "Weaken musuh (4 Turn)";
    } else if (count >= 6) {
      enemy.addEffect(StatusEffect(type: EffectType.damageReduce, value: 2));
      return "Weaken musuh (2 Turn)";
    } else if (count >= 3) {
      enemy.addEffect(StatusEffect(type: EffectType.damageReduce, value: 1));
      return "Weaken musuh (1 Turn)";
    }
    return "";
  }
}
