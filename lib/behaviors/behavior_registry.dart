import 'effects/effect_behavior.dart';
import 'effects/strength_effect.dart';
import 'effects/shield_effect.dart';
import 'effects/counter_effect.dart';
import 'effects/immunity_effect.dart';
import 'effects/heal_effect.dart';
import 'effects/dot_effect.dart';
import 'effects/weaken_effect.dart';
import 'effects/vulnerable_effect.dart';

import 'synergies/synergy_behavior.dart';
import 'synergies/basic_synergy.dart';
import 'synergies/nature_synergy.dart';
import 'synergies/robot_synergy.dart';
import 'synergies/ancient_synergy.dart';
import 'synergies/spirit_synergy.dart';
import 'synergies/fire_synergy.dart';
import 'synergies/toxic_synergy.dart';
import 'synergies/cosmic_synergy.dart';
import 'synergies/liquid_synergy.dart';
import 'synergies/energy_synergy.dart';
import 'synergies/air_synergy.dart';

class BehaviorRegistry {
  // Map registering card ability effect behaviors
  static final Map<String, EffectBehavior> _effects = {
    'strength': StrengthEffect(),
    'shield': ShieldEffect(),
    'counter': CounterEffect(),
    'immunity': ImmunityEffect(),
    'heal': HealEffect(),
    'dot': DotEffect(),
    'weaken': WeakenEffect(),
    'damagereduce': WeakenEffect(), // Dual mapping for compatibility
    'vulnerable': VulnerableEffect(),
  };

  // Map registering archetype synergy behaviors
  static final Map<String, SynergyBehavior> _synergies = {
    'basic': BasicSynergy(),
    'nature': NatureSynergy(),
    'robot': RobotSynergy(),
    'ancient': AncientSynergy(),
    'spirit': SpiritSynergy(),
    'fire': FireSynergy(),
    'toxic': ToxicSynergy(),
    'cosmic': CosmicSynergy(),
    'liquid': LiquidSynergy(),
    'energy': EnergySynergy(),
    'air': AirSynergy(),
  };

  /// Resolves an effect behavior by its ID.
  static EffectBehavior? getEffect(String id) => _effects[id.toLowerCase()];

  /// Resolves a synergy behavior by its ID.
  static SynergyBehavior? getSynergy(String id) => _synergies[id.toLowerCase()];
}
