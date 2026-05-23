import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../board/board_state.dart';
import '../../../../models/playing_card.dart';
import '../../../../models/status_effect.dart';
import '../../../../services/app_localizations.dart';

class GameCardWidget extends StatefulWidget {
  final PlayingCard card;
  final bool isPlayerCard;
  final double width;
  final bool? tooltipOnRight; // Mengatur penempatan tooltip di kanan/kiri
  final bool forceShowTooltip; // Mengaktifkan tampilan tooltip secara paksa (untuk tap di mobile)

  // DATA WARNA SINERGI SESUAI KONFIGURASI PROYEK
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
    this.tooltipOnRight,
    this.forceShowTooltip = false,
  });

  @override
  State<GameCardWidget> createState() => _GameCardWidgetState();
}

class _GameCardWidgetState extends State<GameCardWidget> {
  bool _isHovered = false;

  Color _parseHexColor(String hexStr) {
    final String cleanHex = hexStr.replaceAll('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  String _getAbilityExplanation(String abilityId) {
    switch (abilityId.toUpperCase()) {
      case "COUNTER_SHIELD":
        return "Jika KALAH: Dapatkan +15 Shield.\nJika MENANG: Dapatkan +4 Strength.";
      case "EXPLODE":
        return "Dapatkan +5 Strength.";
      case "BLOCK":
      case "DEFEND":
      case "BARRIER":
        return "Dapatkan +12 Shield.";
      case "BURN":
      case "POISON":
        return "Berikan efek DoT (+6) ke musuh.";
      case "TRAP":
      case "BIND":
        return "Berikan efek Weaken (-25% Damage) ke musuh selama 2 turn.";
      case "GLOW":
      case "ORBIT":
        return "Peluang 25% untuk mendapatkan Immunity (Kebal) selama 1 turn.";
      case "BLEED":
      case "STRIKE":
        return "Berikan efek Vulnerable (+50% Damage masuk) ke musuh selama 2 turn.";
      case "CALCULATE":
      case "COMPUTE":
        return "Dapatkan efek Counter (+8 Damage balasan) ketika diserang.";
      default:
        return "Memiliki kemampuan taktis khusus.";
    }
  }

  String _getKeywordExplanation(String abilityId) {
    switch (abilityId.toUpperCase()) {
      case "COUNTER_SHIELD":
        return "Shield: Menyerap damage.\nStrength: Meningkatkan damage serangan.";
      case "EXPLODE":
        return "Strength: Meningkatkan daya serang dasar Anda secara permanen selama pertempuran.";
      case "BLOCK":
      case "DEFEND":
      case "BARRIER":
        return "Shield: Mengubah status menjadi Block di awal giliran berikutnya untuk menyerap serangan.";
      case "BURN":
      case "POISON":
        return "DoT (Damage over Time): Mengurangi HP target di awal gilirannya secara berkala.";
      case "TRAP":
      case "BIND":
        return "Weaken: Mengurangi kekuatan serangan target sebesar 25%.";
      case "GLOW":
      case "ORBIT":
        return "Immunity: Membuat target kebal dari segala jenis serangan langsung selama aktif.";
      case "BLEED":
      case "STRIKE":
        return "Vulnerable: Target menerima 50% damage lebih besar dari serangan langsung.";
      case "CALCULATE":
      case "COMPUTE":
        return "Counter: Membalas penyerang dengan damage langsung saat Anda terkena serangan.";
      default:
        return "";
    }
  }

  Color _getSynergyColor(String synergy) {
    switch (synergy.toLowerCase()) {
      case 'fire': return const Color(0xFFFF4500);
      case 'liquid': return const Color(0xFF1E90FF);
      case 'nature': return const Color(0xFF8B4513);
      case 'air': return const Color(0xFF87CEEB);
      case 'robot': return const Color(0xFF9DA5A8);
      case 'cosmic': return const Color(0xFF9370DB);
      case 'energy': return const Color(0xFFFFD700);
      case 'spirit': return const Color(0xFF00CED1);
      case 'dark': return const Color(0xFF4B0082);
      case 'ancient': return const Color(0xFFFFD700);
      case 'toxic': return const Color(0xFFADFF2F);
      default: return const Color(0xFFC5A059);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final cardMeta = localization.getCardMetadata(widget.card.id);
    final cardName = localization.getCardName(widget.card.id);
    
    BoardState? boardState;
    try {
      boardState = context.watch<BoardState>();
    } catch (_) {
      boardState = null;
    }

    final double computedHeight = widget.width * 1.4;
    final String synergyType = (cardMeta?.synergy ?? 'basic').toLowerCase();

    final Map<String, String> currentColors =
        GameCardWidget.synergyColors[synergyType] ?? GameCardWidget.synergyColors["basic"]!;
    final Color mainColor = _parseHexColor(currentColors["main"]!);

    Color powerNumberColor = const Color(0xFFFFD700); 
    int displayPower = cardMeta?.power ?? 0;

    bool shouldCheckStatus = false;
    if (widget.isPlayerCard && boardState != null) {
      try {
        // Cek apakah player sudah terinisialisasi
        boardState.player;
        shouldCheckStatus = true;
      } catch (_) {
        shouldCheckStatus = false;
      }
    }

    if (shouldCheckStatus && boardState != null) {
      if (boardState.player.hasEffect(EffectType.damageReduce)) {
        powerNumberColor = Colors.redAccent;
        displayPower = (displayPower * 0.75).round();
      } else if (boardState.player.hasEffect(EffectType.strength)) {
        powerNumberColor = Colors.greenAccent;
        final strength = boardState.player.getEffect(EffectType.strength);
        displayPower = displayPower + strength.value;
      }
    }

    final bool isRight = widget.tooltipOnRight ?? true;
    final double tooltipWidth = 220;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. WIDGET KARTU UTAMA
          Container(
            width: widget.width,
            height: computedHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(widget.width * 0.1),
              border: Border.all(color: mainColor.withAlpha(204), width: widget.width * 0.015),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.width * 0.09),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/cards/${widget.card.id}.jpg',
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
                              size: widget.width * 0.3,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
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

                  Positioned(
                    top: computedHeight * 0.04,
                    left: widget.width * 0.04,
                    right: widget.width * 0.04,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.card.id.toUpperCase(),
                          style: TextStyle(
                            color: const Color(0xFFD3D3D3),
                            fontFamily: 'Electrolize',
                            fontSize: widget.width * 0.11,
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
                                fontSize: widget.width * 0.08,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                        _buildSynergyIcon(synergyType, mainColor, widget.width * 0.12),
                      ],
                    ),
                  ),

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
                              fontSize: widget.width * 0.08,
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
          ),

          // 2. DETAIL TOOLTIP SLAY THE SPIRE (MELAYANG DI SAMPING KIRI/KANAN KARTU)
          if ((_isHovered || widget.forceShowTooltip) && cardMeta != null)
            Positioned(
              top: 0,
              left: isRight ? widget.width + 12 : null,
              right: !isRight ? widget.width + 12 : null,
              width: tooltipWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isRight ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  // Balon Penjelasan Utama
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xEC1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC5A059), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                cardMeta.abilityId.replaceAll('_', ' '),
                                style: TextStyle(
                                  color: _getSynergyColor(cardMeta.synergy),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getSynergyColor(cardMeta.synergy).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cardMeta.synergy,
                                style: TextStyle(
                                  color: _getSynergyColor(cardMeta.synergy),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0x26C5A059), height: 10),
                        Text(
                          _getAbilityExplanation(cardMeta.abilityId),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Balon Penjelasan Keyword (Jika Ada)
                  _buildKeywordWidget(cardMeta.abilityId),
                ],
              )
              .animate()
              .fadeIn(duration: 120.ms)
              .moveX(begin: isRight ? -6 : 6, end: 0, duration: 120.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildKeywordWidget(String abilityId) {
    final keyText = _getKeywordExplanation(abilityId);
    if (keyText.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(
        padding: const EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xE12A2215), // Kecokelatan antik khas Slay the Spire
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x80C5A059), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "KEYWORD:",
              style: TextStyle(
                color: Color(0xFFC5A059),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              keyText,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 8.5,
                height: 1.25,
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