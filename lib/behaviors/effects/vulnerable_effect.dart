import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'effect_behavior.dart';

class VulnerableEffect implements EffectBehavior {
  @override
  String get id => 'vulnerable';

  @override
  String apply(Player caster, Player target, int value) {
    target.addEffect(StatusEffect(type: EffectType.vulnerable, value: value));
    return "Vulnerable selama $value turn ke ${target.name}";
  }
}
