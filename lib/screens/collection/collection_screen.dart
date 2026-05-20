import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../board/player_run.dart';
import '../../models/playing_card.dart';
import '../../services/app_localizations.dart';
import 'widgets/collection_grid.dart';
import 'widgets/collection_header.dart';

class CollectionScreen extends StatelessWidget {
  static const String routeName = '/collection';

  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data run petualangan player yang aktif saat ini
    // final playerRun = context.watch<PlayerRun>();
    final localization = AppLocalizations.of(context)!;

    // Konversi daftar string id dari masterDeck menjadi daftar objek PlayingCard murni
    // final List<PlayingCard> currentDeck = playerRun.masterDeck
    //     .map((id) => PlayingCard(id.toString()))
    //     .toList();
    final List<PlayingCard> currentDeck = List.generate(
      101, 
      (index) => PlayingCard((index + 1).toString()),
    );
    
    return Scaffold(
      body: Container(
        // Latar belakang gradasi gelap yang senada dengan arena gameplay
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F1F1F), Color(0xFF0A0A0A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // 1. Bagian Atas: Header Informasi Deck
                CollectionHeader(
                  totalCards: currentDeck.length,
                  titleText: localization.getUiText('collectionTitle'),
                ),
                
                const SizedBox(height: 20),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),
                
                // 2. Bagian Bawah: Grid Daftar Kartu Milik Pemain
                Expanded(
                  child: CollectionGrid(masterDeck: currentDeck),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}