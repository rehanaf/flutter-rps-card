import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class AncientSynergy implements SynergyBehavior {
  @override
  String get id => 'ancient';

  @override
  String apply(Player player, Player enemy, int count) {
    if (count >= 6) {
      player.addEffect(StatusEffect(type: EffectType.shield, value: 15));
      return "+15 Shield";
    } else if (count >= 4) {
      player.addEffect(StatusEffect(type: EffectType.shield, value: 8));
      return "+8 Shield";
    } else if (count >= 2) {
      player.addEffect(StatusEffect(type: EffectType.shield, value: 4));
      return "+4 Shield";
    }
    return "";
  }
}
