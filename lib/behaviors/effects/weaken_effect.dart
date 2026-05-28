import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'effect_behavior.dart';

class WeakenEffect implements EffectBehavior {
  @override
  String get id => 'weaken';

  @override
  String apply(Player caster, Player target, int value) {
    target.addEffect(StatusEffect(type: EffectType.damageReduce, value: value));
    return "Weaken selama $value turn ke ${target.name}";
  }
}
