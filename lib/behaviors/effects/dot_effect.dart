import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'effect_behavior.dart';

class DotEffect implements EffectBehavior {
  @override
  String get id => 'dot';

  @override
  String apply(Player caster, Player target, int value) {
    target.addEffect(StatusEffect(type: EffectType.dot, value: value));
    return "DoT (+$value) ke ${target.name}";
  }
}
