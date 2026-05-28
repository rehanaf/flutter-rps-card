import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class BasicSynergy implements SynergyBehavior {
  @override
  String get id => 'basic';

  @override
  String apply(Player player, Player enemy, int count) {
    if (count >= 12) {
      player.addEffect(StatusEffect(type: EffectType.counter, value: 8));
      player.addEffect(StatusEffect(type: EffectType.strength, value: 3));
      return "+8 Counter, +3 Strength";
    } else if (count >= 8) {
      player.addEffect(StatusEffect(type: EffectType.counter, value: 4));
      player.addEffect(StatusEffect(type: EffectType.strength, value: 1));
      return "+4 Counter, +1 Strength";
    } else if (count >= 4) {
      player.addEffect(StatusEffect(type: EffectType.counter, value: 2));
      return "+2 Counter";
    }
    return "";
  }
}
