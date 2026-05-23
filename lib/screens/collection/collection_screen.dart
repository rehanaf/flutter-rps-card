import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../board/player_run.dart';
import '../../models/playing_card.dart';
import '../../services/app_localizations.dart';
import 'widgets/collection_grid.dart';
import 'widgets/collection_header.dart';

class CollectionScreen extends StatefulWidget {
  static const String routeName = '/collection';

  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String _selectedSynergy = 'Semua';

  final List<String> _synergies = [
    'Semua', 'Basic', 'Nature', 'Robot', 'Ancient', 'Spirit', 
    'Fire', 'Toxic', 'Cosmic', 'Liquid', 'Energy', 'Air'
  ];

  @override
  Widget build(BuildContext context) {
    // Ambil data run petualangan player yang aktif saat ini
    // final playerRun = context.watch<PlayerRun>();
    final localization = AppLocalizations.of(context)!;

    // Konversi daftar string id dari masterDeck menjadi daftar objek PlayingCard murni
    // final List<PlayingCard> currentDeck = playerRun.masterDeck
    //     .map((id) => PlayingCard(id.toString()))
    //     .toList();
    final List<PlayingCard> allCards = List.generate(
      101, 
      (index) => PlayingCard((index + 1).toString()),
    );
    
    final List<PlayingCard> currentDeck = allCards.where((card) {
      if (_selectedSynergy == 'Semua') return true;
      final meta = localization.getCardMetadata(card.id);
      if (meta == null) return false;
      return meta.synergy.toLowerCase() == _selectedSynergy.toLowerCase();
    }).toList();
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
                  totalCards: allCards.length,
                  titleText: localization.getUiText('collectionTitle'),
                ),
                
                const SizedBox(height: 15),
                
                // Filter Tab Sinergi
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _synergies.length,
                    itemBuilder: (context, index) {
                      final synergy = _synergies[index];
                      final isSelected = _selectedSynergy == synergy;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            synergy,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFC5A059),
                          backgroundColor: const Color(0x33C5A059),
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : const Color(0x66C5A059),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedSynergy = synergy;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 15),
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