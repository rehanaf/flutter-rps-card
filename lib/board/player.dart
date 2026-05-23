import 'package:flutter/foundation.dart';
import '../models/playing_card.dart';
import '../models/status_effect.dart';

class Player extends ChangeNotifier {
  final String name;
  final bool isEnemy;

  int _hp = 100;
  int _maxHp = 100;
  int _shield = 0;

  List<PlayingCard> hand = [];
  List<PlayingCard> deck = [];
  List<PlayingCard> discardPile = [];

  List<StatusEffect> activeEffects = [];

  Player({
    required this.name,
    required this.isEnemy,
  });

  int get hp => _hp;
  set hp(int value) {
    _hp = value.clamp(0, _maxHp);
    notifyListeners();
  }

  int get maxHp => _maxHp;
  set maxHp(int value) {
    _maxHp = value;
    if (_hp > _maxHp) _hp = _maxHp;
    notifyListeners();
  }

  int get shield => _shield;
  set shield(int value) {
    _shield = value.clamp(0, 9999);
    notifyListeners();
  }

  bool get isDead => _hp <= 0;

  void takeDamage(int amount) {
    if (amount <= 0) return;
    hp -= amount;
  }

  void heal(int amount) {
    if (amount <= 0) return;
    hp += amount;
  }

  void drawCards(int count) {
    for (int i = 0; i < count; i++) {
      if (deck.isEmpty) {
        reshuffleDiscardIntoDeck();
      }

      if (deck.isNotEmpty) {
        PlayingCard drawnCard = deck.removeLast();
        hand.add(drawnCard);
      }
    }
    notifyListeners();
  }

  void discardHand() {
    discardPile.addAll(hand);
    hand.clear();
    notifyListeners();
  }

  void reshuffleDiscardIntoDeck() {
    if (discardPile.isEmpty) return;
    deck.addAll(discardPile);
    discardPile.clear();
    deck.shuffle();
    notifyListeners();
  }

  // --- HELPER FUNGSI STATUS EFFECT ---

  bool hasEffect(EffectType type) {
    return activeEffects.any((e) => e.type == type);
  }

  StatusEffect getEffect(EffectType type) {
    return activeEffects.firstWhere((e) => e.type == type);
  }

  void addEffect(StatusEffect newEffect) {
    final existingIndex = activeEffects.indexWhere((e) => e.type == newEffect.type);
    
    if (existingIndex != -1) {
      activeEffects[existingIndex].value += newEffect.value;
    } else {
      activeEffects.add(newEffect);
    }
    notifyListeners();
  }

  void removeEffect(EffectType type) {
    activeEffects.removeWhere((e) => e.type == type);
    notifyListeners();
  }

  // Compatibility getter untuk hasDamageDebuff
  bool get hasDamageDebuff => hasEffect(EffectType.damageReduce);
}