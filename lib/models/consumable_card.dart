import 'package:flutter/material.dart';

class ConsumableCard {
  final String id;
  final String name;
  final String description;
  final int price;
  final String iconName;
  final Color themeColor;

  const ConsumableCard({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.iconName,
    required this.themeColor,
  });

  static const List<ConsumableCard> allConsumables = [
    ConsumableCard(
      id: 'potion_heal',
      name: 'Ramuan Kebugaran',
      description: 'Pulihkan +20 HP secara instan.',
      price: 30,
      iconName: 'healing',
      themeColor: Colors.tealAccent,
    ),
    ConsumableCard(
      id: 'potion_shield',
      name: 'Ramuan Pelindung',
      description: 'Dapatkan +15 Block instan untuk turn ini.',
      price: 25,
      iconName: 'shield',
      themeColor: Colors.blueAccent,
    ),
    ConsumableCard(
      id: 'adrenaline',
      name: 'Adrenalin',
      description: 'Tarik 2 kartu gratis dari Deck ke Tangan.',
      price: 35,
      iconName: 'flash_on',
      themeColor: Colors.orangeAccent,
    ),
    ConsumableCard(
      id: 'sharpening_stone',
      name: 'Batu Pengasah',
      description: 'Dapatkan Strength (+6) untuk meningkatkan daya serang.',
      price: 30,
      iconName: 'hardware',
      themeColor: Colors.redAccent,
    ),
    ConsumableCard(
      id: 'poison_flask',
      name: 'Labu Racun',
      description: 'Infeksi musuh dengan DoT (+6) setiap giliran.',
      price: 30,
      iconName: 'science',
      themeColor: Colors.greenAccent,
    ),
  ];

  static ConsumableCard? getById(String id) {
    for (var c in allConsumables) {
      if (c.id == id) return c;
    }
    return null;
  }
}
