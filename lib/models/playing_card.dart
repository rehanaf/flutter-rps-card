enum BattleResult { win, lose, draw }

class PlayingCard {
  final String id;

  PlayingCard(this.id);

  BattleResult beats(PlayingCard opponentCard) {
    int p1 = int.parse(id);
    int p2 = int.parse(opponentCard.id);
    if (p1 == p2) return BattleResult.draw;
    int diff = (p2 - p1) % 101;
    if (diff < 0) diff += 101;
    if (diff > 0 && diff <= 50) {
      return BattleResult.win;
    } else {
      return BattleResult.lose;
    }
  }
}

class CardMetadata {
  final String id;
  final int power;
  final String synergy;
  final Map<String, int> win;
  final Map<String, int> lose;

  CardMetadata({
    required this.id,
    required this.power,
    required this.synergy,
    required this.win,
    required this.lose,
  });

  factory CardMetadata.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseEffects(dynamic value) {
      if (value is Map) {
        return value.map((key, val) => MapEntry(key.toString(), val is int ? val : int.tryParse(val.toString()) ?? 0));
      }
      return {};
    }

    return CardMetadata(
      id: json['id'].toString(),
      power: json['power'] as int,
      synergy: json['synergy'] as String,
      win: parseEffects(json['win']),
      lose: parseEffects(json['lose']),
    );
  }
}