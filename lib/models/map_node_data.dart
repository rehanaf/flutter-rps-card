class MapNodeData {
  final String id;
  final String type; // 'BATTLE', 'SHOP', 'BOSS'
  final String enemyId; // ID Musuh dari enemies.json (jika bertipe BATTLE/BOSS)
  final int floor;
  final double x;
  final double y;
  final List<String> parentIds; // ID parent node yang menuju ke node ini

  MapNodeData({
    required this.id,
    required this.type,
    this.enemyId = '',
    required this.floor,
    required this.x,
    required this.y,
    required this.parentIds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'enemyId': enemyId,
    'floor': floor,
    'x': x,
    'y': y,
    'parentIds': parentIds,
  };

  factory MapNodeData.fromJson(Map<String, dynamic> json) => MapNodeData(
    id: json['id'] as String,
    type: json['type'] as String,
    enemyId: json['enemyId'] as String? ?? '',
    floor: json['floor'] as int,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    parentIds: List<String>.from(json['parentIds'] as List),
  );
}
