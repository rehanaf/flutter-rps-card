import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../board/player_run.dart';
import '../board/board_state.dart';
import '../models/consumable_card.dart';
import '../models/status_effect.dart';
import '../models/playing_card.dart';
import '../services/app_localizations.dart';
import '../services/settings_provider.dart';
import '../screens/gameplay/widgets/game_card_widget.dart';

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;

  const GameAppBar({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final playerRun = context.watch<PlayerRun>();
    // Safely check if BoardState is available in context (e.g., active battle screen)
    final boardState = Provider.of<BoardState?>(context, listen: true);

    int currentHp = playerRun.currentHp;
    int maxHp = playerRun.maxHp;
    bool inBattle = false;

    if (boardState != null) {
      try {
        // This will throw a LateInitializationError if battle has not started
        currentHp = boardState.player.hp;
        maxHp = boardState.player.maxHp;
        inBattle = true;
      } catch (_) {
        currentHp = playerRun.currentHp;
        maxHp = playerRun.maxHp;
        inBattle = false;
      }
    }

    return AppBar(
      backgroundColor: const Color(0xFF141416),
      foregroundColor: const Color(0xFFC5A059),
      automaticallyImplyLeading: showBackButton,
      elevation: 0,
      centerTitle: false,
      titleSpacing: showBackButton ? 0 : 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. HP DISPLAY
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                '$currentHp/$maxHp',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 1.2, height: 16, color: Colors.white24),
          const SizedBox(width: 16),

          // 2. POTION SLOTS (Icon Only & Interactive in Battle)
          _buildAppBarPotionSlots(context, playerRun, inBattle ? boardState : null),
          const SizedBox(width: 16),
          Container(width: 1.2, height: 16, color: Colors.white24),
          const SizedBox(width: 16),

          // 3. GOLD DISPLAY
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 6),
              Text(
                '${playerRun.gold}G',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // 4. DECK ICON BUTTON
        IconButton(
          icon: const Icon(Icons.style_rounded, color: Color(0xFFC5A059), size: 22),
          tooltip: 'Lihat Deck Utama',
          splashRadius: 20,
          onPressed: () {
            final deck = inBattle ? boardState!.player.deck : playerRun.masterDeck;
            _showCardListOverlay(context, "DECK UTAMA (${deck.length})", deck);
          },
        ),
        // 5. SETTINGS ICON BUTTON
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Color(0xFFC5A059), size: 22),
          tooltip: 'Pengaturan',
          splashRadius: 20,
          onPressed: () {
            _showSettingsOverlay(context);
          },
        ),
        const SizedBox(width: 12),
      ],
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

  Widget _buildAppBarPotionSlots(BuildContext context, PlayerRun playerRun, BoardState? boardState) {
    final List<String> slots = playerRun.consumableSlots;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (index) {
        final bool hasConsumable = index < slots.length;
        final String? consumableId = hasConsumable ? slots[index] : null;
        final consumable = consumableId != null ? ConsumableCard.getById(consumableId) : null;

        if (consumable != null) {
          final icon = _getConsumableIcon(consumable.iconName);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Tooltip(
              message: "${consumable.name}\n${consumable.description}\n${boardState != null ? 'Ketuk untuk gunakan' : 'Gunakan saat pertempuran'}",
              child: GestureDetector(
                onTap: () {
                  if (boardState != null) {
                    _useConsumableInBattle(context, boardState, playerRun, consumable);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ramuan hanya dapat digunakan dalam pertempuran!')),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: consumable.themeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: consumable.themeColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: consumable.themeColor.withValues(alpha: 0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: consumable.themeColor,
                    size: 15,
                  ),
                ),
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Tooltip(
              message: "Slot Ramuan Kosong",
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.0),
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  color: Colors.white24,
                  size: 15,
                ),
              ),
            ),
          );
        }
      }),
    );
  }

  void _useConsumableInBattle(
    BuildContext context,
    BoardState boardState,
    PlayerRun playerRun,
    ConsumableCard consumable,
  ) {
    final index = playerRun.consumableSlots.indexOf(consumable.id);
    if (index == -1) return;

    bool success = false;
    String effectMsg = "";

    switch (consumable.id) {
      case 'potion_heal':
        if (boardState.player.hp >= boardState.player.maxHp) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('HP Anda sudah penuh!')),
          );
          return;
        }
        boardState.player.heal(20);
        success = true;
        effectMsg = "menggunakan ${consumable.name} (+20 HP)!";
        break;

      case 'potion_shield':
        boardState.player.addEffect(StatusEffect(type: EffectType.shield, value: 15));
        success = true;
        effectMsg = "menggunakan ${consumable.name} (+15 Shield)!";
        break;

      case 'adrenaline':
        boardState.triggerDrawSequence(2);
        success = true;
        effectMsg = "menggunakan ${consumable.name} (Tarik 2 Kartu)!";
        break;

      case 'sharpening_stone':
        boardState.player.addEffect(StatusEffect(type: EffectType.strength, value: 6));
        success = true;
        effectMsg = "menggunakan ${consumable.name} (+6 Strength)!";
        break;

      case 'poison_flask':
        boardState.enemy.addEffect(StatusEffect(type: EffectType.dot, value: 6));
        success = true;
        effectMsg = "melempar ${consumable.name} ke musuh (DoT +6)!";
        break;
    }

    if (success) {
      playerRun.removeConsumableAt(index);
      playerRun.updateHpAfterBattle(boardState.player.hp);
      boardState.battleLog = "✨ [Ramuan] ${boardState.player.name} $effectMsg\n${boardState.battleLog}";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menggunakan ${consumable.name}!'),
          backgroundColor: consumable.themeColor,
        ),
      );
    }
  }

  void _showCardListOverlay(BuildContext context, String title, List<PlayingCard> cards) {
    showDialog(
      context: context,
      builder: (context) {
        final double screenWidth = MediaQuery.of(context).size.width;

        return Dialog(
          backgroundColor: const Color(0xEC0F0F0F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFC5A059), width: 1.5),
          ),
          child: Container(
            width: screenWidth * 0.85,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFC5A059),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Color(0x33C5A059), thickness: 1, height: 10),
                const SizedBox(height: 10),
                if (cards.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Tidak ada kartu saat ini.",
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: MediaQuery.of(context).size.width * 0.1 + 30,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        return GameCardWidget(
                          card: cards[index],
                          isPlayerCard: true,
                          width: MediaQuery.of(context).size.width * 0.1,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                const double dialogWidth = 460;

                return Container(
                  width: dialogWidth,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFA1E1E1E),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
