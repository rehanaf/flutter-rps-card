import 'package:flutter/material.dart';
import '../../../board/board_state.dart';
import '../../../services/app_localizations.dart';

class TurnOverlayWidget extends StatelessWidget {
  final TurnOverlayData? overlayData;

  const TurnOverlayWidget({super.key, required this.overlayData});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInQuad,
            ),
            child: child,
          ),
        );
      },
      child: overlayData == null
          ? const SizedBox.shrink()
          : _buildOverlayBanner(context, overlayData!),
    );
  }

  Widget _buildOverlayBanner(BuildContext context, TurnOverlayData data) {
    final localization = AppLocalizations.of(context)!;

    Color themeColor;
    String finalTitle = data.title;
    String finalDescription = data.description;

    // Tentukan warna tema dan deskripsi berdasarkan eventType
    switch (data.eventType) {
      case 'player_turn':
        themeColor = const Color(0xFFC5A059); // Gold
        break;
      case 'enemy_turn':
        themeColor = const Color(0xFFEF5350); // Soft Red
        break;
      case 'clash_win':
        themeColor = const Color(0xFF66BB6A); // Soft Green
        if (data.playerCardId != null && data.enemyCardId != null) {
          finalDescription = _buildClashDescription(
            context,
            localization,
            data.playerCardId!,
            data.enemyCardId!,
            true,
          );
        } else {
          final playerCardName = data.playerCardId != null ? localization.getCardName(data.playerCardId!) : "Kartu Anda";
          final enemyCardName = data.enemyCardId != null ? localization.getCardName(data.enemyCardId!) : "Kartu Musuh";
          finalDescription = "$playerCardName menang melawan $enemyCardName";
        }
        break;
      case 'clash_lose':
        themeColor = const Color(0xFFEF5350); // Soft Red
        if (data.playerCardId != null && data.enemyCardId != null) {
          finalDescription = _buildClashDescription(
            context,
            localization,
            data.enemyCardId!,
            data.playerCardId!,
            false,
          );
        } else {
          final playerCardName = data.playerCardId != null ? localization.getCardName(data.playerCardId!) : "Kartu Anda";
          final enemyCardName = data.enemyCardId != null ? localization.getCardName(data.enemyCardId!) : "Kartu Musuh";
          finalDescription = "$enemyCardName menang melawan $playerCardName";
        }
        break;
      case 'clash_draw':
        themeColor = const Color(0xFFFFCA28); // Soft Amber
        final playerCardName = data.playerCardId != null ? localization.getCardName(data.playerCardId!) : "Kartu Anda";
        final enemyCardName = data.enemyCardId != null ? localization.getCardName(data.enemyCardId!) : "Kartu Musuh";
        finalDescription = localization.locale.languageCode == 'id'
            ? "$playerCardName seri melawan $enemyCardName"
            : "$playerCardName draws against $enemyCardName";
        break;
      default:
        themeColor = const Color(0xFFC5A059);
    }

    return KeyedSubtree(
      key: ValueKey(data),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xEC151515), // Sangat gelap transparan
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: themeColor.withAlpha(50),
                blurRadius: 15,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                finalTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 2,
                color: themeColor.withAlpha(120),
              ),
              const SizedBox(height: 10),
              Text(
                finalDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

String _buildClashDescription(
  BuildContext context,
  AppLocalizations localization,
  String winnerId,
  String loserId,
  bool isPlayerWinner,
) {
  final String winnerName = localization.getCardName(winnerId);
  final String loserName = localization.getCardName(loserId);

  final List<dynamic>? rawVerbArray = localization.getClashVerbArray(winnerId, loserId);

  if (rawVerbArray != null && rawVerbArray.isNotEmpty) {
    final List<String> verbArray = rawVerbArray.map((e) {
      String s = e.toString();
      s = s.replaceAll(r"\'", "'").replaceAll(r"\\'", "'").replaceAll(r"\", "");
      return s;
    }).toList();

    final String part1 = verbArray[0];
    if (verbArray.length == 1) {
      return "$winnerName $part1 $loserName";
    } else if (verbArray.length >= 2) {
      final String part2 = verbArray[1];
      if (part1.isEmpty) {
        return "$winnerName $loserName$part2";
      }

      final String middle = part1.endsWith('(') ? "$part1$loserName" : "$part1 $loserName";

      if (part2.isEmpty) {
        return "$winnerName $middle";
      } else if (part2.startsWith("'s") || part2 == ")") {
        return "$winnerName $middle$part2";
      } else {
        return "$winnerName $middle $part2";
      }
    }
  }

  // Fallback default
  if (localization.locale.languageCode == 'id') {
    return "$winnerName menang melawan $loserName";
  } else {
    return "$winnerName wins against $loserName";
  }
}
}
