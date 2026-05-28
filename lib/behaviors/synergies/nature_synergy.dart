import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class NatureSynergy implements SynergyBehavior {
  @override
  String get id => 'nature';

  @override
  String apply(Player player, Player enemy, int count) {
    if (count >= 9) {
      player.addEffect(StatusEffect(type: EffectType.heal, value: 10));
      return "+10 Heal";
    } else if (count >= 6) {
      player.addEffect(StatusEffect(type: EffectType.heal, value: 5));
      return "+5 Heal";
    } else if (count >= 3) {
      player.addEffect(StatusEffect(type: EffectType.heal, value: 2));
      return "+2 Heal";
    }
    return "";
  }
}
