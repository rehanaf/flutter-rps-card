import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../board/player_run.dart';
import '../../services/app_localizations.dart';
import '../../components/settings_dialog.dart';
import '../collection/collection_screen.dart';
import '../how_to_play/how_to_play_screen.dart';
import '../map/map_screen.dart';
import '../../board/board_state.dart';
import '../gameplay/gameplay_screen.dart';

class MainMenuScreen extends StatelessWidget {
  static const String routeName = '/main_menu';

  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil fungsi translate dari service pelokalan yang sudah kita buat
    final localization = AppLocalizations.of(context)!;
    // Watch status PlayerRun agar menu utama langsung bereaksi jika progres dihapus/dibuat
    final playerRun = context.watch<PlayerRun>();

    return Scaffold(
      body: Stack(
        children: [
          // LAYER 1: Gambar Latar Belakang Menu Utama
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/main_menu.jpg', 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback jika file gambar background belum dimasukkan ke assets
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1F1F1F), Color(0xFF0A0A0A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              },
            ),
          ),

          // Layer Hitam Transparan untuk memberikan kontras pada teks
          Positioned.fill(
            child: Container(color: Colors.black45),
          ),

          // LAYER 2: Konten Menu Utama (Judul Game & Tombol-Tombol Aksi)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double screenHeight = MediaQuery.of(context).size.height;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // JUDUL BESAR GAME (Skala responsif dengan FittedBox)
                            SizedBox(
                              width: constraints.maxWidth * 0.9,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  localization.getUiText('appTitle').toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFC5A059),
                                    letterSpacing: 6,
                                    shadows: [
                                      Shadow(color: Colors.black87, offset: Offset(0, 6), blurRadius: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // SUBTITLE (Skala responsif dengan FittedBox)
                            SizedBox(
                              width: constraints.maxWidth * 0.8,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text(
                                  "101-CARD CIRCULAR STRATEGY",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 16,
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: screenHeight * 0.05),

                            // DAFTAR TOMBOL UTAMA DENGAN DUKUNGAN CONTINUATION
                            if (playerRun.hasActiveRun) ...[
                              // 1. LANJUTKAN PETUALANGAN (Glow emas premium)
                              _buildMenuButton(
                                context,
                                label: localization.getUiText('continueButton'),
                                icon: Icons.map_rounded,
                                isHighlighted: true,
                                onPressed: () {
                                  if (playerRun.inBattle && playerRun.selectedNodeId != null) {
                                    final boardState = Provider.of<BoardState>(context, listen: false);
                                    try {
                                      final node = playerRun.mapNodes.firstWhere((n) => n.id == playerRun.selectedNodeId);
                                      final enemyMeta = localization.getEnemyMetadata(node.enemyId);
                                      if (enemyMeta != null) {
                                        boardState.initializeBattle(
                                          playerRun: playerRun,
                                          enemyMeta: enemyMeta,
                                          allCards: localization.allCardsMetadata,
                                        );
                                        Navigator.pushNamed(context, GameplayScreen.routeName);
                                        return;
                                      }
                                    } catch (e) {
                                      debugPrint("Failed to resume battle: $e");
                                    }
                                  }
                                  Navigator.pushNamed(context, MapScreen.routeName);
                                },
                              ),
                              const SizedBox(height: 12),
                              
                              // 2. PETUALANGAN BARU (Menggantikan tombol play biasa dengan konfirmasi)
                              _buildMenuButton(
                                context,
                                label: localization.getUiText('newRunButton'),
                                icon: Icons.restart_alt_rounded,
                                onPressed: () {
                                  _showNewRunConfirmation(context, playerRun, localization);
                                },
                              ),
                            ] else ...[
                              // TAMPILAN DEFAULT: HANYA TOMBOL PLAY BIASA
                              _buildMenuButton(
                                context,
                                label: localization.getUiText('playButton'),
                                icon: Icons.play_arrow_rounded,
                                onPressed: () {
                                  playerRun.startNewRun();
                                  Navigator.pushNamed(context, MapScreen.routeName);
                                },
                              ),
                            ],
                            
                            const SizedBox(height: 12),
                            
                            _buildMenuButton(
                              context,
                              label: localization.getUiText('collectionButton'),
                              icon: Icons.collections_rounded,
                              onPressed: () {
                                Navigator.pushNamed(context, CollectionScreen.routeName);
                              },
                            ),
                            
                            const SizedBox(height: 12),

                            _buildMenuButton(
                              context,
                              label: localization.getUiText('howToPlayButton'),
                              icon: Icons.menu_book_rounded,
                              onPressed: () {
                                Navigator.pushNamed(context, HowToPlayScreen.routeName);
                              },
                            ),
                            
                            const SizedBox(height: 12),
                            
                            _buildMenuButton(
                              context,
                              label: localization.getUiText('settingsButton'),
                              icon: Icons.settings_rounded,
                              onPressed: () {
                                _showSettingsOverlay(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan overlay pengaturan interaktif dan premium
  void _showSettingsOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const SettingsDialog();
      },
    );
  }

  /// Dialog konfirmasi jika ingin menimpa petualangan yang sedang berjalan
  void _showNewRunConfirmation(BuildContext context, PlayerRun playerRun, AppLocalizations localization) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFC5A059), width: 2),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFC5A059), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localization.getUiText('confirmNewRunTitle'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              localization.getUiText('confirmNewRunMessage'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  localization.getUiText('cancelButton').toUpperCase(),
                  style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5A059),
                  foregroundColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog konfirmasi
                  playerRun.startNewRun(); // Reset progres petualangan
                  Navigator.pushNamed(context, MapScreen.routeName); // Buka peta petualangan
                },
                child: Text(
                  localization.getUiText('startNewButton').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper khusus untuk membangun desain tombol menu bertema game yang konsisten
  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isHighlighted = false,
  }) {
    return SizedBox(
      width: 260,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: const Color(0xFFC5A059),
          elevation: isHighlighted ? 12 : 5,
          shadowColor: isHighlighted ? const Color(0x99C5A059) : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFFC5A059),
              width: isHighlighted ? 2.5 : 1.5,
            ), // Frame Emas tipis/tebal
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700, // Bold
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}