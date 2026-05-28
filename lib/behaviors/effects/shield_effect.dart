import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'effect_behavior.dart';

class ShieldEffect implements EffectBehavior {
  @override
  String get id => 'shield';

  @override
  String apply(Player caster, Player target, int value) {
    caster.addEffect(StatusEffect(type: EffectType.shield, value: value));
    return "Shield (+$value)";
  }
}
