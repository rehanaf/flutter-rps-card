import '../../board/player.dart';

abstract class EffectBehavior {
  String get id;

  /// Applies the status effect or action to the caster/target.
  /// Returns a user-friendly description of what was applied.
  String apply(Player caster, Player target, int value);
}
