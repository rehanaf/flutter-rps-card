import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'effect_behavior.dart';

class CounterEffect implements EffectBehavior {
  @override
  String get id => 'counter';

  @override
  String apply(Player caster, Player target, int value) {
    caster.addEffect(StatusEffect(type: EffectType.counter, value: value));
    return "Counter (+$value)";
  }
}
