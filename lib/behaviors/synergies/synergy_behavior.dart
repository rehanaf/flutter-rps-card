import '../../board/player.dart';

abstract class SynergyBehavior {
  String get id;

  /// Evaluates the count threshold and applies the synergy bonus effects.
  /// Returns a log string description, or an empty string if no threshold is met.
  String apply(Player player, Player enemy, int count);
}
