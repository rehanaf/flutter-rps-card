import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'effect_behavior.dart';

class StrengthEffect implements EffectBehavior {
  @override
  String get id => 'strength';

  @override
  String apply(Player caster, Player target, int value) {
    caster.addEffect(StatusEffect(type: EffectType.strength, value: value));
    return "Strength (+$value)";
  }
}
