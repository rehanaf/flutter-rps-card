import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../board/board_state.dart';
import '../../board/player_run.dart';
import '../../models/playing_card.dart';
import '../../models/consumable_card.dart';
import '../../models/status_effect.dart';
import '../../services/app_localizations.dart';
import '../../components/game_app_bar.dart';
import 'widgets/battle_log_widget.dart';
import 'widgets/game_card_widget.dart';
import 'widgets/player_hand_widget.dart';
import 'widgets/character_display_widget.dart';

class GameplayScreen extends StatelessWidget {
  static const String routeName = '/gameplay';

  const GameplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();
    final playerRun = context.read<PlayerRun>();
    final localization = AppLocalizations.of(context)!;
    final Size screenSize = MediaQuery.of(context).size;

    final double cardWidth = screenSize.width * 0.13;

    return Scaffold(
      appBar: const GameAppBar(showBackButton: false),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // WALLPAPER BACKGROUND
            Positioned.fill(
              child: Image.asset(
                'assets/images/background/main_menu_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFF0F0F0F));
                },
              ),
            ),
            Positioned.fill(
              child: Container(color: const Color(0x66000000)),
            ),

            // KARAKTER PLAYER (SLAY THE SPIRE STYLE)
            Positioned(
              left: screenSize.width * 0.08,
              bottom: screenSize.height * 0.32 + 20,
              child: CharacterDisplayWidget(
                isPlayer: true,
                width: screenSize.width * 0.22,
                height: screenSize.height * 0.28,
              ),
            ),

            // KARAKTER MUSUH (SLAY THE SPIRE STYLE)
            Positioned(
              right: screenSize.width * 0.08,
              bottom: screenSize.height * 0.32 + 20,
              child: CharacterDisplayWidget(
                isPlayer: false,
                width: screenSize.width * 0.22,
                height: screenSize.height * 0.28,
              ),
            ),



            Positioned(
              top: 15,
              left: screenSize.width * 0.26,
              right: screenSize.width * 0.26,
              child: Center(
                child: BattleLogWidget(logText: boardState.battleLog),
              ),
            ),

            // KARTU MUSUH DI MEJA (LAYER 4)
            if (boardState.enemyCardOnTable != null)
              Positioned(
                left: screenSize.width * 0.60 - (cardWidth / 2),
                top: (screenSize.height / 2) - (cardWidth / 2),
                child: GameCardWidget(
                  card: boardState.enemyCardOnTable!,
                  isPlayerCard: false,
                  width: cardWidth,
                ),
              ),

            // KARTU PLAYER DI MEJA (LAYER 5)
            if (boardState.playerCardOnTable != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutQuad,
                left: boardState.cardX,
                top: boardState.cardY,
                onEnd: () => boardState.onAnimationGlideComplete(),
                child: GameCardWidget(
                  card: boardState.playerCardOnTable!,
                  isPlayerCard: true,
                  width: cardWidth,
                ),
              ),

            // DRAG TARGET SENSOR MEJA ARENA
            // ========================================================
            // FIXED: SENSOR DRAG TARGET DROP AREA (MEJA TENGAH)
            // ========================================================
            // ========================================================
            // LAYER 6: SENSOR DRAG TARGET DROP AREA (MEJA TENGAH BESAR)
            // ========================================================
            if (boardState.playerCardOnTable == null)
              Positioned(
                left: 16,
                right: 16,
                top: 76,
                bottom: screenSize.height * 0.32 + 8,
                child: DragTarget<Object>(
                  onWillAcceptWithDetails: (details) {
                    return details.data is PlayingCard || details.data is ConsumableCard;
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHighlighted = candidateData.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration( // Emas menyala saat kartu ditahan di atasnya
                        border: Border.all(
                          color: isHighlighted
                              ? const Color(0xFFC5A059)
                              : const Color(0x26C5A059),
                          width: isHighlighted ? 2.5 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16), // Menyala tipis
                        color: isHighlighted // Hitbox transparan agar tetap peka sentuhan
                            ? const Color(0x14C5A059)
                            : const Color(0x01FFFFFF),
                        boxShadow: isHighlighted
                            ? [
                                BoxShadow(
                                  color: const Color(0x33C5A059),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.ads_click_rounded,
                              color: isHighlighted
                                  ? const Color(0xFFC5A059)
                                  : Colors.white12,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isHighlighted
                                  ? "Lepas Kartu Sekarang!"
                                  : "Geser Kartu / Ramuan ke Sini",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isHighlighted
                                  ? const Color(0xFFC5A059)
                                  : Colors.white24,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  onAcceptWithDetails: (details) {
                    if (details.data is PlayingCard) {
                      boardState.playCardOnTable(
                        details.data as PlayingCard,
                        details.offset.dx,
                        details.offset.dy,
                        screenSize,
                      );
                    } else if (details.data is ConsumableCard) {
                      _useConsumableCard(context, boardState, playerRun, details.data as ConsumableCard);
                    }
                  },
                ),
              ),
            // IKON DECK (KIRI BAWAH)
            Positioned(
              left: 24,
              bottom: 24,
              child: GestureDetector(
                onTap: () => _showCardListOverlay(
                  context,
                  "KARTU DECK (${boardState.player.deck.length})",
                  boardState.player.deck,
                ),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.style_rounded,
                          color: Color(0xFFC5A059),
                          size: 46,
                        ),
                        Positioned(
                          bottom: 4,
                          child: Text(
                            "${boardState.player.deck.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "DECK",
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // IKON DISCARD PILE (KANAN BAWAH)
            Positioned(
              right: 24,
              bottom: 24,
              child: GestureDetector(
                onTap: () => _showCardListOverlay(
                  context,
                  "DISCARD PILE (${boardState.player.discardPile.length})",
                  boardState.player.discardPile,
                ),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.delete_sweep_rounded,
                          color: boardState.player.discardPile.isNotEmpty //
                              ? const Color(0xCCFF5252)
                              : Colors.white24,
                          size: 46,
                        ),
                        Positioned(
                          bottom: 4,
                          child: Text(
                            "${boardState.player.discardPile.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "DISCARD",
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // SLOTS KONSUMSI (CONSUMABLE SLOTS) - GAYA BALATRO
            Positioned(
              left: 24,
              top: screenSize.height * 0.35,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SLOT RAMUAN",
                    style: TextStyle(
                      color: Color(0xFFC5A059),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(2, (index) {
                      final slots = playerRun.consumableSlots;
                      final hasConsumable = index < slots.length;
                      final String? consumableId = hasConsumable ? slots[index] : null;
                      final consumable = consumableId != null ? ConsumableCard.getById(consumableId) : null;

                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 58,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: consumable != null
                                ? consumable.themeColor.withAlpha(120)
                                : const Color(0x26C5A059),
                            width: consumable != null ? 1.5 : 1.0,
                          ),
                          boxShadow: consumable != null
                              ? [
                                  BoxShadow(
                                    color: consumable.themeColor.withAlpha(30),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: consumable != null
                            ? Draggable<ConsumableCard>(
                                data: consumable,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: _buildConsumableCardWidget(consumable, 58, 76, true),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.25,
                                  child: _buildConsumableCardWidget(consumable, 58, 76, false),
                                ),
                                child: _buildConsumableCardWidget(consumable, 58, 76, false),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.hourglass_empty_rounded,
                                  color: Colors.white12,
                                  size: 20,
                                ),
                              ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // TANGAN PLAYER (FAN LAYOUT KIPAS RESPONSIF)
            Positioned(
              bottom: 0,
              left: screenSize.width * 0.15,
              right: screenSize.width * 0.15,
              height: screenSize.height * 0.32,
              child: PlayerHandWidget(
                boardState: boardState,
                screenSize: screenSize,
              ),
            ),

            // POPUP OVERLAY AKHIR PERTANDINGAN
            if (boardState.player.isDead || boardState.enemy.isDead)
              Positioned.fill(
                child: _buildEndGameOverlay(
                  context,
                  boardState,
                  playerRun,
                  localization,
                ),
              ),
          ],
        ),
      ),
    );
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
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 110,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        return GameCardWidget(
                          card: cards[index],
                          isPlayerCard: true,
                          width: 80,
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

  void _showCardRewardOverlay(
    BuildContext context,
    BoardState boardState,
    PlayerRun playerRun,
    AppLocalizations localization,
  ) {
    // 1. Ambil semua kunci (ID kartu) dari database kartu
    final allCardIds = localization.allCardsMetadata.keys.toList();
    
    // 2. Acak daftar ID kartu dan pilih 3 kartu unik
    allCardIds.shuffle();
    final List<String> draftCardIds = allCardIds.take(3).toList();

    showDialog(
      context: context,
      barrierDismissible: false, // Pemain wajib memilih atau menekan skip
      builder: (context) {
        final double screenWidth = MediaQuery.of(context).size.width;

        return Dialog(
          backgroundColor: const Color(0xEC0F0F0F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFC5A059), width: 1.5),
          ),
          child: Container(
            width: screenWidth * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "PILIH HADIAH KARTU",
                  style: TextStyle(
                    color: Color(0xFFC5A059),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Pilih 1 kartu untuk dimasukkan ke deck kamu secara permanen.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 20),
                
                // TIGA KARTU ACAK DI TAMPILAN HORIZONTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: draftCardIds.map((cardId) {
                    final playingCard = PlayingCard(cardId);

                    return GestureDetector(
                      onTap: () {
                        // Daftarkan kartu terpilih ke master deck
                        playerRun.addCardToMasterDeck(playingCard);
                        
                        // Selesaikan pertempuran (simpan HP & tambah gold)
                        playerRun.updateHpAfterBattle(boardState.player.hp);
                        playerRun.addGold(25);
                        playerRun.completeNode(playerRun.selectedNodeId ?? 'node_1');
                        
                        // Tutup dialog draf
                        Navigator.pop(context);
                        // Kembali ke Peta (tutup gameplay screen)
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Kartu "${localization.getCardName(cardId)}" ditambahkan ke Deck!'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameCardWidget(
                              card: playingCard,
                              isPlayerCard: true,
                              width: 85,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC5A059),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "PILIH",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                const Divider(color: Color(0x33C5A059), thickness: 1),
                const SizedBox(height: 8),
                
                // TOMBOL SKIP (LEWATI HADIAH)
                SizedBox(
                  width: 160,
                  height: 38,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Selesaikan pertempuran tanpa menambahkan kartu
                      playerRun.updateHpAfterBattle(boardState.player.hp);
                      playerRun.addGold(25);
                      playerRun.completeNode(playerRun.selectedNodeId ?? 'node_1');
                      
                      // Tutup dialog draf
                      Navigator.pop(context);
                      // Kembali ke Peta (tutup gameplay screen)
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Melewati hadiah kartu (Deck tetap).')),
                      );
                    },
                    child: const Text(
                      "LEWATI (SKIP)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEndGameOverlay(
    BuildContext context,
    BoardState boardState,
    PlayerRun playerRun,
    AppLocalizations localization,
  ) {
    final bool isWin = boardState.enemy.isDead;
    return Container(
      color: const Color(0xD9000000),
      child: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWin ? const Color(0xFFC5A059) : Colors.redAccent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isWin ? Icons.emoji_events_rounded : Icons.gavel_rounded,
                color: isWin ? const Color(0xFFC5A059) : Colors.redAccent,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                isWin
                    ? localization.getUiText('winTitle')
                    : localization.getUiText('loseTitle'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isWin
                    ? "Kamu memenangkan pertempuran dan mendapatkan 25 Koin Emas!"
                    : localization.getUiText('loseDescription'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isWin
                        ? const Color(0xFFC5A059)
                        : Colors.red[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (isWin) {
                      _showCardRewardOverlay(context, boardState, playerRun, localization);
                    } else {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                  child: Text(
                    isWin
                        ? "PILIH HADIAH KARTU"
                        : localization.getUiText('mainMenuButton'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _useConsumableCard(
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

  IconData _getIconData(String iconName) {
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

  Widget _buildConsumableCardWidget(ConsumableCard consumable, double w, double h, bool isFeedback) {
    return Tooltip(
      message: "${consumable.name}\n${consumable.description}",
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xEC0F0F0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC5A059), width: 1.0),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0x26000000),
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              consumable.themeColor.withAlpha(40),
              Colors.black54,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconData(consumable.iconName),
              color: consumable.themeColor,
              size: isFeedback ? 26 : 20,
            ),
            const SizedBox(height: 4),
            Text(
              consumable.name.split(' ').last,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: isFeedback ? 9 : 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
