import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class EnergySynergy implements SynergyBehavior {
  @override
  String get id => 'energy';

  @override
  String apply(Player player, Player enemy, int count) {
    if (count >= 3) {
      player.addEffect(StatusEffect(type: EffectType.strength, value: 8));
      return "+8 Strength";
    } else if (count >= 2) {
      player.addEffect(StatusEffect(type: EffectType.strength, value: 3));
      return "+3 Strength";
    } else if (count >= 1) {
      player.addEffect(StatusEffect(type: EffectType.strength, value: 1));
      return "+1 Strength";
    }
    return "";
  }
}
