import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../board/player_run.dart';
import '../../services/app_localizations.dart';
import '../../services/settings_provider.dart';
import '../collection/collection_screen.dart';
import '../how_to_play/how_to_play_screen.dart';
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

                            // DAFTAR TOMBOL UTAMA
                            _buildMenuButton(
                              context,
                              label: localization.getUiText('playButton'),
                              icon: Icons.play_arrow_rounded,
                              onPressed: () {
                                final playerRun = context.read<PlayerRun>();
                                // Memulai petualangan baru dengan starter deck default terpusat
                                playerRun.startNewRun();

                                // Pindah rute ke Map Screen
                                Navigator.pushNamed(context, MapScreen.routeName);
                              },
                            ),
                            
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
    final localization = AppLocalizations.of(context)!;
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    bool tempMusic = settingsProvider.isMusicEnabled;
    bool tempSfx = settingsProvider.isSfxEnabled;
    Locale tempLocale = settingsProvider.locale;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFA1E1E1E), // Solid dark with premium gloss
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC5A059), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 15,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TITLE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.settings_rounded,
                              color: Color(0xFFC5A059),
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              localization.getUiText('settingsTitle').toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFC5A059),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0x33C5A059), thickness: 1.5),
                        const SizedBox(height: 16),

                        // SETTINGS CONTENT
                        // 1. Music Setting Row
                        _buildSettingRow(
                          icon: Icons.music_note_rounded,
                          title: localization.locale.languageCode == 'id' ? 'Musik Latar' : 'Background Music',
                          control: Switch(
                            value: tempMusic,
                            activeThumbColor: const Color(0xFFC5A059),
                            activeTrackColor: const Color(0x4DC5A059),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.black26,
                            onChanged: (val) {
                              setState(() {
                                tempMusic = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. SFX Setting Row
                        _buildSettingRow(
                          icon: Icons.volume_up_rounded,
                          title: localization.locale.languageCode == 'id' ? 'Efek Suara' : 'Sound Effects',
                          control: Switch(
                            value: tempSfx,
                            activeThumbColor: const Color(0xFFC5A059),
                            activeTrackColor: const Color(0x4DC5A059),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.black26,
                            onChanged: (val) {
                              setState(() {
                                tempSfx = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3. Language Setting Row
                        _buildSettingRow(
                          icon: Icons.language_rounded,
                          title: localization.locale.languageCode == 'id' ? 'Bahasa' : 'Language',
                          control: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLanguageOption(
                                label: "ID",
                                isSelected: tempLocale.languageCode == 'id',
                                onTap: () {
                                  setState(() {
                                    tempLocale = const Locale('id');
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildLanguageOption(
                                label: "EN",
                                isSelected: tempLocale.languageCode == 'en',
                                onTap: () {
                                  setState(() {
                                    tempLocale = const Locale('en');
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: Color(0x1AC5A059), thickness: 1.5),
                        const SizedBox(height: 12),

                        // DEVELOPER INFO / CREDITS
                        Text(
                          localization.locale.languageCode == 'id'
                              ? "VERSI 1.0.0 • DIKEMBANGKAN OLEH ANTIGRAVITY"
                              : "VERSION 1.0.0 • DEVELOPED BY ANTIGRAVITY",
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ACTION BUTTONS (Simpan / Batal)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Batal Button
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                localization.getUiText('cancelButton').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Simpan Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC5A059),
                                foregroundColor: const Color(0xFF1E1E1E),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: () {
                                // Terapkan perubahan ke provider global
                                settingsProvider.setMusic(tempMusic);
                                settingsProvider.setSfx(tempSfx);
                                settingsProvider.setLocale(tempLocale);
                                Navigator.pop(context);
                              },
                              child: Text(
                                localization.getUiText('saveButton').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required Widget control,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xCCC5A059), size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        control,
      ],
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC5A059) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFFC5A059) : const Color(0x33C5A059),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E1E1E) : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
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