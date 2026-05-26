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
  final String abilityId;
  final int win;
  final int lose;

  CardMetadata({
    required this.id,
    required this.power,
    required this.synergy,
    required this.abilityId,
    this.win = 0,
    this.lose = 0,
  });

  factory CardMetadata.fromJson(Map<String, dynamic> json) {
    return CardMetadata(
      id: json['id'].toString(),
      power: json['power'] as int,
      synergy: json['synergy'] as String,
      abilityId: json['abilityId'] as String,
      win: json['win'] as int? ?? 0,
      lose: json['lose'] as int? ?? 0,
    );
  }
}