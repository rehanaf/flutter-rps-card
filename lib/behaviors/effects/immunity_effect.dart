import '../../board/player.dart';
import '../../models/status_effect.dart';
import 'effect_behavior.dart';

class ImmunityEffect implements EffectBehavior {
  @override
  String get id => 'immunity';

  @override
  String apply(Player caster, Player target, int value) {
    caster.addEffect(StatusEffect(type: EffectType.immunity, value: value));
    return "Immunity (Kebal) selama $value turn";
  }
}
