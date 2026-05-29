import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../board/player_run.dart';
import '../board/board_state.dart';
import '../models/consumable_card.dart';
import '../models/status_effect.dart';
import '../models/playing_card.dart';
import '../screens/gameplay/widgets/game_card_widget.dart';
import 'settings_dialog.dart';

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
      backgroundColor: Colors.transparent,
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
                '${playerRun.gold}',
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const SettingsDialog();
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
