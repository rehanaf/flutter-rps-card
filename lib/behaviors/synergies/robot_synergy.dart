import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'synergy_behavior.dart';

class RobotSynergy implements SynergyBehavior {
  @override
  String get id => 'robot';

  @override
  String apply(Player player, Player enemy, int count) {
    if (count >= 9) {
      player.addEffect(StatusEffect(type: EffectType.shield, value: 15));
      return "+15 Shield";
    } else if (count >= 6) {
      player.addEffect(StatusEffect(type: EffectType.shield, value: 7));
      return "+7 Shield";
    } else if (count >= 3) {
      player.addEffect(StatusEffect(type: EffectType.shield, value: 3));
      return "+3 Shield";
    }
    return "";
  }
}
