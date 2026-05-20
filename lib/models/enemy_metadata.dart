class EnemyMetadata {
  final String id;
  final String name;
  final int baseHp;
  final String archetype;
  final int deckSize;
  final int synergyCount;
  final int randomCount;

  EnemyMetadata({
    required this.id,
    required this.name,
    required this.baseHp,
    required this.archetype,
    required this.deckSize,
    required this.synergyCount,
    required this.randomCount,
  });

  factory EnemyMetadata.fromJson(Map<String, dynamic> json) {
    return EnemyMetadata(
      id: json['id'].toString(),
      name: json['name'] as String,
      baseHp: json['base_hp'] as int,
      archetype: json['archetype'] as String,
      deckSize: json['deck_size'] as int,
      synergyCount: json['synergy_count'] as int,
      randomCount: json['random_count'] as int,
    );
  }
}