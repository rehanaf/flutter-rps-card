import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../board/board_state.dart';
import '../../board/player_run.dart';
import '../../models/playing_card.dart';
import '../../services/app_localizations.dart';
import 'widgets/battle_log_widget.dart';
import 'widgets/game_card_widget.dart';
import 'widgets/hud_widget.dart';
import 'widgets/player_hand_widget.dart';

class GameplayScreen extends StatelessWidget {
  static const String routeName = '/gameplay';

  const GameplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();
    final playerRun = context.read<PlayerRun>();
    final localization = AppLocalizations.of(context)!;
    final Size screenSize = MediaQuery.of(context).size;
    final double statusBarPadding = MediaQuery.of(context).padding.top;

    final double cardWidth = screenSize.width * 0.13;

    final double tableCardWidth = screenSize.width * 0.40;
    final double tableCardHeight = screenSize.height * 0.25;

    return Scaffold(
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

            // HUD PLAYER
            Positioned(
              top: statusBarPadding + 12,
              left: 24,
              child: HudWidget(
                name: boardState.player.name,
                hp: boardState.player.hp,
                maxHp: boardState.player.maxHp,
                isEnemy: false,
              ),
            ),

            // HUD MUSUH
            Positioned(
              top: statusBarPadding + 12,
              right: 24,
              child: HudWidget(
                name: boardState.enemy.name,
                hp: boardState.enemy.hp,
                maxHp: boardState.enemy.maxHp,
                isEnemy: true,
              ),
            ),

            // BATTLE LOG TEXT
            Positioned(
              top: statusBarPadding + 15,
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
                // 1. HORIZONTAL CENTER: Mengambil 40% lebar layar, posisinya otomatis di tengah
                left: (screenSize.width / 2) - ((screenSize.width * 0.40) / 2),

                // 2. VERTICAL POSITION: Pas di tengah-tengah ruang kosong meja (antara kartu musuh & tangan)
                top: (screenSize.height / 2) - 30,

                child: DragTarget<PlayingCard>(
                  builder: (context, candidateData, rejectedData) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),

                      // 3. UKURAN MEJA ARENA (Jauh lebih besar & luas)
                      width: tableCardWidth,
                      height: tableCardHeight,

                      decoration: BoxDecoration( // Emas menyala saat kartu ditahan di atasnya
                        border: Border.all(
                          color: candidateData.isNotEmpty
                              ? const Color(0xFFC5A059)
                              : const Color(0x26C5A059),
                          width: candidateData.isNotEmpty ? 2.5 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16), // Menyala tipis
                        color: candidateData.isNotEmpty // Hitbox transparan agar tetap peka sentuhan
                            ? const Color(0x14C5A059)
                            : const Color(0x01FFFFFF),
                        boxShadow: candidateData.isNotEmpty
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
                              color: candidateData.isNotEmpty
                                  ? const Color(0xFFC5A059)
                                  : Colors.white12,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              candidateData.isNotEmpty
                                  ? "Lepas Kartu Sekarang!"
                                  : "Geser Kartu ke Sini untuk Bertarung",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: candidateData.isNotEmpty
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
                    boardState.playCardOnTable(
                      details.data,
                      details.offset.dx,
                      details.offset.dy,
                      screenSize,
                    );
                  },
                ),
              ),
            // IKON DECK (KIRI TENGAH)
            Positioned(
              left: 24,
              top: (screenSize.height / 2) - 45,
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

            // IKON DISCARD PILE (KANAN TENGAH)
            Positioned(
              right: 24,
              top: (screenSize.height / 2) - 45,
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
                      playerRun.updateHpAfterBattle(boardState.player.hp);
                      playerRun.addGold(25);
                      playerRun.completeNode('current_node');
                      Navigator.pop(context);
                    } else {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                  child: Text(
                    isWin
                        ? localization.getUiText('playAgainButton')
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
}
