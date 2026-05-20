import 'package:flutter/foundation.dart';
import '../models/playing_card.dart';
import '../models/status_effect.dart';

class Player extends ChangeNotifier {
  final String name;
  final bool isEnemy;

  int _hp = 100;
  int _maxHp = 100;

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

  void addEffect(StatusEffect effect) {
    final existingIndex = activeEffects.indexWhere((e) => e.type == effect.type);
    
    if (existingIndex != -1) {
      activeEffects[existingIndex].duration += effect.duration;
    } else {
      activeEffects.add(effect);
    }
    notifyListeners();
  }

  void updateEffectsTick() {
    for (var effect in activeEffects) {
      effect.decreaseDuration();
    }
    activeEffects.removeWhere((effect) => effect.isExpired);
    notifyListeners();
  }

  bool get hasDamageDebuff => activeEffects.any((e) => e.type == EffectType.damageReduce);
}