import '../../board/player.dart';
import 'effect_behavior.dart';

class HealEffect implements EffectBehavior {
  @override
  String get id => 'heal';

  @override
  String apply(Player caster, Player target, int value) {
    caster.heal(value);
    return "Heal (+$value HP)";
  }
}
