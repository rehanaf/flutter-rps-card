import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../board/board_state.dart';
import '../../../../models/playing_card.dart';
import '../../../../models/status_effect.dart';
import '../../../../services/app_localizations.dart';

class GameCardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool isPlayerCard;
  final double width;

  // DIKSTRUKSI DATA WARNA SINERGI SESUAI CONFIG KAMU
  static const Map<String, Map<String, String>> synergyColors = {
    "basic": {"main": "#F9F6EE", "blend": "#7D7B77"},
    "fire": {"main": "#FF4500", "blend": "#802200"},
    "liquid": {"main": "#1E90FF", "blend": "#0F4880"},
    "nature": {"main": "#8B4513", "blend": "#452209"},
    "air": {"main": "#87CEEB", "blend": "#436775"},
    "robot": {"main": "#9DA5A8", "blend": "#4E5254"},
    "cosmic": {"main": "#9370DB", "blend": "#49386D"},
    "energy": {"main": "#FFFF00", "blend": "#808000"},
    "spirit": {"main": "#00CED1", "blend": "#006768"},
    "dark": {"main": "#4B0082", "blend": "#250041"},
    "ancient": {"main": "#FFD700", "blend": "#806B00"},
    "toxic": {"main": "#ADFF2F", "blend": "#567F17"},
  };

  const GameCardWidget({
    super.key,
    required this.card,
    this.isPlayerCard = true,
    required this.width,
  });

  Color _parseHexColor(String hexStr) {
    final String cleanHex = hexStr.replaceAll('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final cardMeta = localization.getCardMetadata(card.id);
    final cardName = localization.getCardName(card.id);
    final boardState = context.watch<BoardState>();

    final double computedHeight = width * 1.4;

    final String synergyType = (cardMeta?.synergy ?? 'basic').toLowerCase();

    final Map<String, String> currentColors =
        synergyColors[synergyType] ?? synergyColors["basic"]!;
    final Color mainColor = _parseHexColor(currentColors["main"]!);

    Color powerNumberColor = const Color(0xFFFFD700); 
    int displayPower = cardMeta?.power ?? 0;

    bool shouldCheckStatus = false;
    try {
      if (isPlayerCard) {
        boardState.player;
        shouldCheckStatus = true;
      }
    } catch (_) {
      shouldCheckStatus = false;
    }

    if (shouldCheckStatus) {
      if (boardState.player.hasDamageDebuff) {
        powerNumberColor = Colors.redAccent;
        final debuff = boardState.player.activeEffects.firstWhere(
          (e) => e.type == EffectType.damageReduce,
        );
        displayPower = (displayPower * (1 - debuff.value)).round();
      } else if (boardState.player.activeEffects.any((e) => e.type == EffectType.damageBuff)) {
        powerNumberColor = Colors.greenAccent;
        final buff = boardState.player.activeEffects.firstWhere(
          (e) => e.type == EffectType.damageBuff,
        );
        displayPower = (displayPower * (1 + buff.value)).round();
      }
    }

    return Container(
      width: width,
      height: computedHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(width * 0.1),
        border: Border.all(color: mainColor.withAlpha(204), width: width * 0.015), // 204 setara dengan 0.8 opacity (0.8 * 255)
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.09),
        child: Stack(
          children: [
            // IMAGE FULL SEUKURAN KARTU
            Positioned.fill(
              child: Image.asset(
                'assets/images/cards/${card.id}.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF25282F), Color(0xFF17191D)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white12,
                        size: width * 0.3,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Lapisan Hitam Transparan
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xB3000000),
                      Colors.transparent,
                      Color(0xD9000000),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // HEADER BAR (Synergy Icon, Name, ID)
            Positioned(
              top: computedHeight * 0.04,
              left: width * 0.04,
              right: width * 0.04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    card.id.toUpperCase(),
                    style: TextStyle(
                      color: const Color(0xFFD3D3D3),
                      fontFamily: 'Electrolize',
                      fontSize: width * 0.11, // Ukuran teks ID proporsional terhadap lebar kartu
                    ),
                  ),
                  
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        cardName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.08, // Ukuran teks nama proporsional
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  _buildSynergyIcon(synergyType, mainColor, width * 0.12),
                ],
              ),
            ),

            // POWER BAR ("60 Damage")
            Positioned(
              bottom: computedHeight * 0.05,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: width * 0.08, // Skala ukuran teks damage proporsional
                        letterSpacing: 0.5,
                        shadows: const [
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            blurRadius: 3,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      children: [
                        TextSpan(
                          text: "$displayPower ",
                          style: TextStyle(
                            color: powerNumberColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: "Damage",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSynergyIcon(String synergy, Color iconColor, double iconSize) {
    IconData iconData;
    switch (synergy) {
      case 'fire': iconData = Icons.local_fire_department_rounded; break;
      case 'liquid': iconData = Icons.water_drop_rounded; break;
      case 'nature': iconData = Icons.forest_rounded; break;
      case 'air': iconData = Icons.wb_cloudy_rounded; break;
      case 'robot': iconData = Icons.precision_manufacturing_rounded; break;
      case 'cosmic': iconData = Icons.auto_awesome_rounded; break;
      case 'energy': iconData = Icons.bolt_rounded; break;
      case 'spirit': iconData = Icons.psychology_rounded; break;
      case 'dark': iconData = Icons.shield_moon_rounded; break;
      case 'ancient': iconData = Icons.gavel_rounded; break;
      case 'toxic': iconData = Icons.science_rounded; break;
      case 'basic':
      default:
        iconData = Icons.layers_rounded;
    }
    return Icon(iconData, color: iconColor, size: iconSize);
  }
}