import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class LiquidSynergy implements SynergyBehavior {
  @override
  String get id => 'liquid';

  @override
  String apply(Player player, Player enemy, int count) {
    if (count >= 6) {
      player.addEffect(StatusEffect(type: EffectType.heal, value: 6));
      player.addEffect(StatusEffect(type: EffectType.shield, value: 6));
      return "+6 Heal, +6 Shield";
    } else if (count >= 4) {
      player.addEffect(StatusEffect(type: EffectType.heal, value: 3));
      player.addEffect(StatusEffect(type: EffectType.shield, value: 3));
      return "+3 Heal, +3 Shield";
    } else if (count >= 2) {
      player.addEffect(StatusEffect(type: EffectType.heal, value: 1));
      player.addEffect(StatusEffect(type: EffectType.shield, value: 1));
      return "+1 Heal, +1 Shield";
    }
    return "";
  }
}
