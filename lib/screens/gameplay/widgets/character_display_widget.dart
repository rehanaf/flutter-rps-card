import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../board/board_state.dart';
import '../../../board/player_run.dart';
import '../../../services/app_localizations.dart';

class CharacterDisplayWidget extends StatelessWidget {
  final bool isPlayer;
  final double width;
  final double height;

  const CharacterDisplayWidget({
    super.key,
    required this.isPlayer,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final String assetPath = isPlayer
        ? 'assets/images/characters/default_player.png'
        : 'assets/images/characters/default_enemy.png';

    // UI Tambahan: Balon Niat Musuh (Intent Bubble) di atas kepala musuh
    Widget? intentBubble;
    if (!isPlayer) {
      final boardState = context.watch<BoardState>();
      final playerRun = context.watch<PlayerRun>();
      final localization = AppLocalizations.of(context)!;

      final nextCard = boardState.nextEnemyCard;
      if (nextCard != null && boardState.playerCardOnTable == null) {
        final hintText = boardState.isEnemyCardRevealed
            ? "${localization.getCardName(nextCard.id)} (${localization.getCardMetadata(nextCard.id)?.power ?? 0} Power)"
            : boardState.enemyIntentText ?? "Bersiap...";

        final icon = boardState.enemyIntentIcon;
        final color = boardState.enemyIntentColor;

        intentBubble = Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xEC1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: boardState.isEnemyCardRevealed ? const Color(0xFFC5A059) : Colors.white24,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                hintText,
                style: TextStyle(
                  color: boardState.isEnemyCardRevealed ? const Color(0xFFC5A059) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!boardState.isEnemyCardRevealed) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final success = boardState.revealEnemyCard(playerRun);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Emas tidak cukup! (Butuh 5 Emas)"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5A059),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_rounded, color: Colors.white, size: 10),
                        SizedBox(width: 3),
                        Text(
                          "Teropong (5G)",
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 1500.ms, curve: Curves.easeInOut);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (intentBubble != null) intentBubble,

        // 1. Karakter Sprite dengan Animasi Melayang/Bernapas
        SizedBox(
          width: width,
          height: height,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: isPlayer
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPlayer ? Colors.blue : Colors.red,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    isPlayer ? 'Player' : 'Enemy',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: 0, end: -8, duration: 2200.ms, curve: Curves.easeInOut),

        const SizedBox(height: 6),

        // 2. Bayangan Tanah (Ground Shadow) yang sinkron dengan gerakan melayang
        Container(
          width: width * 0.6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.elliptical(width * 0.6, 6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 0.8, duration: 2200.ms, curve: Curves.easeInOut)
        .fade(begin: 0.7, end: 0.4, duration: 2200.ms, curve: Curves.easeInOut),
      ],
    );
  }
}
