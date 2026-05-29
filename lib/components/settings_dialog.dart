import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../board/player_run.dart';
import '../services/settings_provider.dart';
import '../services/app_localizations.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool tempMusic;
  late bool tempSfx;
  late Locale tempLocale;
  bool isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final playerRun = context.watch<PlayerRun>();

    if (!isInitialized) {
      tempMusic = settingsProvider.isMusicEnabled;
      tempSfx = settingsProvider.isSfxEnabled;
      tempLocale = settingsProvider.locale;
      isInitialized = true;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFA1E1E1E), // Solid dark dengan efek premium gloss
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
                // TITLE / JUDUL PENGATURAN
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

                // KONTEN PENGATURAN
                // 1. Musik Latar
                _buildSettingRow(
                  icon: Icons.music_note_rounded,
                  title: tempLocale.languageCode == 'id' ? 'Musik Latar' : 'Background Music',
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

                // 2. Efek Suara (SFX)
                _buildSettingRow(
                  icon: Icons.volume_up_rounded,
                  title: tempLocale.languageCode == 'id' ? 'Efek Suara' : 'Sound Effects',
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

                // 3. Pilihan Bahasa
                _buildSettingRow(
                  icon: Icons.language_rounded,
                  title: tempLocale.languageCode == 'id' ? 'Bahasa' : 'Language',
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

                // 4. TOMBOL HAPUS DATA GAME (Hanya muncul jika ada game aktif)
                if (playerRun.hasActiveRun) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0x1AC5A059), thickness: 1.5),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B2626), // Merah gelap bertema game
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFC5A059), width: 1.2),
                        ),
                      ),
                      onPressed: () => _showDeleteConfirmation(context, playerRun, localization),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_forever_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            localization.getUiText('deleteDataButton').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Divider(color: Color(0x1AC5A059), thickness: 1.5),
                const SizedBox(height: 12),

                // DEVELOPER INFO / CREDITS
                Text(
                  tempLocale.languageCode == 'id'
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
                    // Tombol Simpan & Keluar (Hanya muncul saat berada dalam pertempuran)
                    if (playerRun.inBattle) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC5A059),
                          foregroundColor: const Color(0xFF1E1E1E),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFC5A059), width: 1.5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {
                          // Simpan perubahan setting terlebih dahulu
                          settingsProvider.setMusic(tempMusic);
                          settingsProvider.setSfx(tempSfx);
                          settingsProvider.setLocale(tempLocale);
                          
                          // Tutup dialog pengaturan
                          Navigator.pop(context);
                          
                          // Kembali ke Menu Utama (Root Route)
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: Text(
                          localization.getUiText('saveQuitButton').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Tombol Batal
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
                    // Tombol Simpan
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
        ),
      ),
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

  void _showDeleteConfirmation(BuildContext context, PlayerRun playerRun, AppLocalizations localization) {
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
              side: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localization.getUiText('confirmDeleteTitle'),
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
              localization.getUiText('confirmDeleteMessage'),
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
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  // Hapus data progres game
                  await playerRun.deleteSaveData();
                  
                  if (context.mounted) {
                    // Tutup dialog konfirmasi
                    Navigator.pop(context);
                    // Tutup dialog pengaturan
                    Navigator.pop(context);
                    
                    // Kembali ke Main Menu (First Route)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
                child: Text(
                  localization.getUiText('yesButton').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
