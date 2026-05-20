import 'package:flutter/material.dart';
import '../../../../models/playing_card.dart';
import '../../gameplay/widgets/game_card_widget.dart';

class CollectionGrid extends StatelessWidget {
  final List<PlayingCard> masterDeck;

  const CollectionGrid({super.key, required this.masterDeck});

  @override
  Widget build(BuildContext context) {
    if (masterDeck.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada kartu di dalam deck milikmu.",
          style: TextStyle(color: Colors.white30, fontSize: 14),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 30),
      physics: const BouncingScrollPhysics(),
      // ====================================================================
      // FIXED: Menggunakan MaxCrossAxisExtent agar Jumlah Kolom Otomatis (Responsive)
      // ====================================================================
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,     // Batas lebar maksimal satu kolom (kartu 150 + sisa padding)
        crossAxisSpacing: 16,        // Jarak antar kolom
        mainAxisSpacing: 20,         // Jarak antar baris
        childAspectRatio: 150 / 210, // Mengunci rasio fisik kartu 1:1.4
      ),
      // ====================================================================
      itemCount: masterDeck.length,
      itemBuilder: (context, index) {
        final PlayingCard card = masterDeck[index];
        
        return Center(
          child: GameCardWidget(
            card: card,
            isPlayerCard: true,
            width: 150,
          ),
        );
      },
    );
  }
}