import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../board/player_run.dart';
import '../../services/app_localizations.dart';
import '../collection/collection_screen.dart';
import '../map/map_screen.dart';

class MainMenuScreen extends StatelessWidget {
  static const String routeName = '/main_menu';

  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil fungsi translate dari service pelokalan yang sudah kita buat
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // LAYER 1: Gambar Latar Belakang Menu Utama
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/main_menu_bg.jpg', 
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // JUDUL BESAR GAME (Pakai Font Outfit)
                  Text(
                    localization.getUiText('appTitle').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900, // Sangat tebal khas font Outfit
                      color: Color(0xFFC5A059),   // Warna emas premium
                      letterSpacing: 6,
                      shadows: [
                        Shadow(color: Colors.black87, offset: Offset(0, 6), blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "101-CARD CIRCULAR STRATEGY",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 80),

                  // DAFTAR TOMBOL UTAMA
                  _buildMenuButton(
                    context,
                    label: localization.getUiText('playButton'),
                    icon: Icons.play_arrow_rounded,
                    onPressed: () {
                      // Ambil state PlayerRun untuk memulai petualangan (New Run)
                      final playerRun = Provider.of<PlayerRun>(context, listen: false);
                      
                      // Berikan ID kartu starter pack awal untuk master deck (misal kartu ID 1, 2, 3)
                      playerRun.startNewRun(['10', '18', '61', '10', '18', '61', '10', '18', '61', '10']);

                      // Nanti di sini tinggal pindah rute ke Map Screen:
                      Navigator.pushNamed(context, MapScreen.routeName);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Petualangan Baru Dimulai! Menuju Map...')),
                      );
                    },
                  ),
                  
                  
                  const SizedBox(height: 18),
                  
                  _buildMenuButton(
                    context,
                    label: localization.getUiText('collectionButton'),
                    icon: Icons.collections_rounded,
                    onPressed: () {
                      Navigator.pushNamed(context, CollectionScreen.routeName);
                    },
                  ),
                  
                  const SizedBox(height: 18),
                  
                  _buildMenuButton(
                    context,
                    label: localization.getUiText('settingsButton'),
                    icon: Icons.settings_rounded,
                    onPressed: () {
                      // Aksi menuju setting screen
                    },
                  ),
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper khusus untuk membangun desain tombol menu bertema game yang konsisten
  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 260,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: const Color(0xFFC5A059),
          elevation: 5,
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFC5A059), width: 1.5), // Frame Emas tipis
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
                fontSize: 18,
                fontWeight: FontWeight.w700, // Bold Outfit
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}