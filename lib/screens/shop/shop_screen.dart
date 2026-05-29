import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../board/player_run.dart';
import '../../models/playing_card.dart';
import '../../models/consumable_card.dart';
import '../../services/app_localizations.dart';
import '../../components/game_app_bar.dart';
import '../gameplay/widgets/game_card_widget.dart';

class ShopScreen extends StatefulWidget {
  static const String routeName = '/shop';

  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final List<String> _shopCardIds = [];
  final List<int> _cardPrices = [];
  final List<bool> _isCardSold = [false, false, false];
  final List<String> _shopConsumableIds = [];
  final List<bool> _isConsumableSold = [false, false];
  bool _hasRestedFree = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final localization = AppLocalizations.of(context)!;
      final allCardIds = localization.allCardsMetadata.keys.toList();

      if (allCardIds.isNotEmpty) {
        // Acak dan pilih 3 kartu unik untuk dijual
        allCardIds.shuffle();
        final selectedIds = allCardIds.take(3).toList();
        
        final random = Random();
        for (var id in selectedIds) {
          _shopCardIds.add(id);
          // Harga kartu berkisar antara 40 hingga 60 koin emas
          _cardPrices.add(40 + random.nextInt(21));
        }
      }

      // Acak dan pilih 2 ramuan unik untuk dijual
      final allConsumables = List<ConsumableCard>.from(ConsumableCard.allConsumables);
      allConsumables.shuffle();
      final selectedConsumables = allConsumables.take(2).toList();
      for (var c in selectedConsumables) {
        _shopConsumableIds.add(c.id);
      }

      _isInitialized = true;
    }
  }

  void _buyCard(PlayerRun playerRun, String cardId, int price, int index) {
    if (playerRun.gold < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emas Anda tidak mencukupi untuk membeli kartu ini!')),
      );
      return;
    }

    if (playerRun.spendGold(price)) {
      playerRun.addCardToMasterDeck(PlayingCard(cardId));
      setState(() {
        _isCardSold[index] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil membeli kartu! Ditambahkan ke Deck Utama.'),
          backgroundColor: const Color(0xFFC5A059),
        ),
      );
    }
  }

  void _restFree(PlayerRun playerRun) {
    if (_hasRestedFree) return;

    if (playerRun.currentHp >= playerRun.maxHp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HP Anda sudah penuh!')),
      );
      return;
    }

    playerRun.heal(15);
    setState(() {
      _hasRestedFree = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Beristirahat di dekat api unggun. HP bertambah +15!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  IconData _getConsumableIcon(String iconName) {
    switch (iconName) {
      case 'healing':
        return Icons.healing_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'flash_on':
        return Icons.flash_on_rounded;
      case 'hardware':
        return Icons.hardware_rounded;
      case 'science':
        return Icons.science_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  void _buyConsumable(PlayerRun playerRun, ConsumableCard consumable, int index) {
    if (playerRun.gold < consumable.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emas Anda tidak mencukupi untuk membeli ${consumable.name}!')),
      );
      return;
    }

    if (playerRun.consumableSlots.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot Ramuan Anda sudah penuh! Gunakan ramuan yang ada terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (playerRun.spendGold(consumable.price)) {
      playerRun.addConsumable(consumable.id);
      setState(() {
        _isConsumableSold[index] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerRun = context.watch<PlayerRun>();
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GameAppBar(showBackButton: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141414), Color(0xFF0F0F0F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // WALLPAPER BACKGROUND (DENGAN OVERLAY GELAP)
            Positioned.fill(
              child: Image.asset(
                'assets/images/background/shop.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFF0F0F0F));
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Color(0xEC0F0F0F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // KONTEN UTAMA
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // HEADER TOKO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.storefront_rounded, color: Color(0xFFC5A059), size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TENDA PEDAGANG",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFC5A059),
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              "Belanjakan koin emas atau pulihkan HP Anda",
                              style: TextStyle(color: const Color(0x4DFFFFFF), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0x26C5A059), thickness: 1),
                    const SizedBox(height: 12),

                    // Main Scrollable Area
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // KARTU DAGANGAN (CARDS FOR SALE)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "KARTU UNTUK DIJUAL",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC5A059),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // RAK 3 KARTU
                            if (_shopCardIds.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text("Toko tidak memiliki barang dagangan saat ini.", style: TextStyle(color: Colors.white24)),
                                ),
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(_shopCardIds.length, (index) {
                                  final cardId = _shopCardIds[index];
                                  final price = _cardPrices[index];
                                  final isSold = _isCardSold[index];
                                  final playingCard = PlayingCard(cardId);

                                  return Opacity(
                                    opacity: isSold ? 0.4 : 1.0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0x14FFFFFF),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSold ? Colors.transparent : const Color(0x1FBAA067),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              GameCardWidget(
                                                card: playingCard,
                                                isPlayerCard: true,
                                                width: screenSize.width * 0.1,
                                              ),
                                              if (isSold)
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black54,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Center(
                                                      child: RotationTransition(
                                                        turns: const AlwaysStoppedAnimation(-15 / 360),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: const BoxDecoration(
                                                            color: Colors.redAccent,
                                                            borderRadius: BorderRadius.all(Radius.circular(4)),
                                                          ),
                                                          child: const Text(
                                                            "SOLD OUT",
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w900,
                                                              letterSpacing: 1.0,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          // INFO HARGA & TOMBOL BELI
                                          Row(
                                            children: [
                                              const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                "$price G",
                                                style: const TextStyle(
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: 80,
                                            height: 30,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isSold
                                                    ? Colors.transparent
                                                    : const Color(0xFFC5A059),
                                                foregroundColor: Colors.white,
                                                elevation: isSold ? 0 : 3,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  side: isSold
                                                      ? const BorderSide(color: Colors.white12)
                                                      : BorderSide.none,
                                                ),
                                              ),
                                              onPressed: isSold
                                                  ? null
                                                  : () => _buyCard(playerRun, cardId, price, index),
                                              child: const Text(
                                                "BELI",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),

                            const SizedBox(height: 24),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "AREA ISTIRAHAT (REST AREA)",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC5A059),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // PILIHAN ISTIRAHAT
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // OPSI API UNGGUN (GRATIS)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0x14FFFFFF),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0x1FBAA067)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Api Unggun",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withAlpha(51),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                "GRATIS",
                                                style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          "Pulihkan +15 HP di dekat hangatnya api unggun. Sekali kunjungan.",
                                          style: TextStyle(color: Colors.white30, fontSize: 10),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 32,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _hasRestedFree
                                                  ? Colors.grey[850]
                                                  : Colors.orange[850],
                                              foregroundColor: Colors.white,
                                              elevation: _hasRestedFree ? 0 : 3,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            onPressed: _hasRestedFree
                                                ? null
                                                : () => _restFree(playerRun),
                                            child: Text(
                                              _hasRestedFree ? "SUDAH REHAT" : "REHAT (+15 HP)",
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // OPSI POTION SEKALI PAKAI (2 PILIHAN ACAK)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0x14FFFFFF),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0x1FBAA067)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.science_rounded, color: Colors.tealAccent, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              "Rak Ramuan Pedagang",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (_shopConsumableIds.isEmpty)
                                          const Center(child: Text("Kosong", style: TextStyle(color: Colors.white24, fontSize: 10)))
                                        else
                                          Column(
                                            children: List.generate(_shopConsumableIds.length, (idx) {
                                              final id = _shopConsumableIds[idx];
                                              final isSold = _isConsumableSold[idx];
                                              final consumable = ConsumableCard.getById(id)!;

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0x0AFFFFFF),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isSold ? Colors.transparent : consumable.themeColor.withAlpha(40),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      _getConsumableIcon(consumable.iconName),
                                                      color: isSold ? Colors.white12 : consumable.themeColor,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            isSold ? "TERJUAL" : consumable.name,
                                                            style: TextStyle(
                                                              color: isSold ? Colors.white24 : Colors.white,
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              decoration: isSold ? TextDecoration.lineThrough : null,
                                                            ),
                                                          ),
                                                          if (!isSold)
                                                            Text(
                                                              consumable.description,
                                                              style: const TextStyle(color: Colors.white30, fontSize: 9),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (!isSold) ...[
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            "${consumable.price} G",
                                                            style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(width: 8),
                                                      SizedBox(
                                                        width: 54,
                                                        height: 24,
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFFC5A059),
                                                            foregroundColor: Colors.white,
                                                            padding: EdgeInsets.zero,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                          ),
                                                          onPressed: () => _buyConsumable(playerRun, consumable, idx),
                                                          child: const Text("BELI", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            }),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // TOMBOL EXIT KELUAR PETUALANGAN
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC5A059),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0x80FFFFFF), width: 1),
                          ),
                        ),
                        onPressed: () {
                          // Selesaikan node aktif
                          playerRun.completeNode(playerRun.selectedNodeId ?? 'shop_node');
                          // Kembali ke Peta
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Melanjutkan perjalanan menjelajah dungeon map!'),
                              backgroundColor: Color(0xFFC5A059),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              "LANJUTKAN PETUALANGAN",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
