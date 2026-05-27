import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../board/board_state.dart';
import '../../../models/playing_card.dart';
import '../../../models/status_effect.dart';
import '../../../utils/tooltip_helper.dart';
import '../../../services/app_localizations.dart';

class GameCardWidget extends StatefulWidget {
  final PlayingCard card;
  final bool isPlayerCard;
  final double width;
  final bool? tooltipOnRight; // Mengatur penempatan tooltip di kanan/kiri
  final bool forceShowTooltip; // Mengaktifkan tampilan tooltip secara paksa (untuk tap di mobile)
  final bool disableTooltip; // Menonaktifkan tooltip (berguna saat mode drag aktif)

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
    this.disableTooltip = false,
  });

  @override
  State<GameCardWidget> createState() => _GameCardWidgetState();
}

class _GameCardWidgetState extends State<GameCardWidget> {
  bool _isHovered = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.forceShowTooltip && mounted) {
        _showTooltipOverlay();
      }
    });
  }

  @override
  void didUpdateWidget(covariant GameCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disableTooltip && !oldWidget.disableTooltip) {
      _hideTooltipOverlay();
    } else if (widget.forceShowTooltip != oldWidget.forceShowTooltip) {
      if (widget.forceShowTooltip && !widget.disableTooltip) {
        _showTooltipOverlay();
      } else if (!_isHovered) {
        _hideTooltipOverlay();
      }
    }
  }

  @override
  void dispose() {
    _hideTooltipOverlay();
    super.dispose();
  }

  void _showTooltipOverlay() {
    if (!mounted || widget.disableTooltip) return;
    _hideTooltipOverlay(); // Hapus yang lama jika ada
    
    final localization = AppLocalizations.of(context)!;
    final cardMeta = localization.getCardMetadata(widget.card.id);
    if (cardMeta == null) return;
    final cardName = localization.getCardName(widget.card.id);
    
    BoardState? boardState;
    try {
      boardState = context.read<BoardState>();
    } catch (_) {
      boardState = null;
    }
    
    int displayPower = cardMeta.power;
    bool shouldCheckStatus = false;
    if (widget.isPlayerCard && boardState != null) {
      try {
        boardState.player;
        shouldCheckStatus = true;
      } catch (_) {
        shouldCheckStatus = false;
      }
    }
    if (shouldCheckStatus && boardState != null) {
      if (boardState.player.hasEffect(EffectType.damageReduce)) {
        displayPower = (displayPower * 0.75).round();
      } else if (boardState.player.hasEffect(EffectType.strength)) {
        final strength = boardState.player.getEffect(EffectType.strength);
        displayPower = displayPower + strength.value;
      }
    }

    final double tooltipWidth = 220;
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topLeft,
          // Offset: 6px dari batas kanan kartu
          offset: const Offset(6, 0),
          child: UnconstrainedBox(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: tooltipWidth,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  cardName,
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
                            "When Winning:\n${_formatWinEffects(displayPower, cardMeta.win)}\n\nWhen Losing:\n${_formatLoseEffects(cardMeta.lose)}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              height: 1.3,
                            ),
                          ),
                          if (TooltipHelper.getSynergyExplanation(cardMeta.synergy).isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Divider(color: Color(0x26C5A059), height: 10),
                            Text(
                              TooltipHelper.getSynergyExplanation(cardMeta.synergy),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 9.5,
                                height: 1.3,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Balon Penjelasan Keyword (Jika Ada)
                    _buildKeywordWidget(cardMeta.win, cardMeta.lose),
                  ],
                )
                .animate()
                .fadeIn(duration: 120.ms)
                .moveX(begin: -2, end: 0, duration: 120.ms),
              ),
            ),
          ),
        );
      },
    );
    
    // Defer insertion to post-frame callback to prevent setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlayEntry != null) {
        try {
          Overlay.of(context).insert(_overlayEntry!);
        } catch (_) {}
      }
    });
  }
  
  void _hideTooltipOverlay() {
    if (_overlayEntry != null) {
      final OverlayEntry entry = _overlayEntry!;
      _overlayEntry = null;
      // Defer removal to post-frame callback to prevent setState during build error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          entry.remove();
        } catch (_) {}
      });
    }
  }


  // Helper methods now in TooltipHelper

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
        displayPower = (displayPower * 0.75).round();
      } else if (boardState.player.hasEffect(EffectType.strength)) {
        final strength = boardState.player.getEffect(EffectType.strength);
        displayPower = displayPower + strength.value;
      }
    }

    return MouseRegion(
      onEnter: (_) {
        if (widget.disableTooltip) return;
        setState(() => _isHovered = true);
        _showTooltipOverlay();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        if (!widget.forceShowTooltip) {
          _hideTooltipOverlay();
        }
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: SizedBox(
          width: widget.width,
          height: computedHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double scale = constraints.maxWidth / 600;
              return Container(
                margin: EdgeInsets.all(4 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6E2B0),
                  borderRadius: BorderRadius.circular(32 * scale),
                  border: Border.all(color: const Color(0xFFD2691E), width: 3 * scale),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                padding: EdgeInsets.all(12 * scale),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32 * scale),
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
                        child: CustomPaint(
                          painter: CardPainter(
                            id: widget.card.id,
                            title: cardName,
                            win: _formatWinEffects(displayPower, cardMeta?.win ?? {}),
                            lose: _formatLoseEffects(cardMeta?.lose ?? {}),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatEffect(String key, int value) {
    switch (key.toLowerCase()) {
      case 'strength':
        return 'Gain $value Strength';
      case 'shield':
        return 'Gain $value Shield';
      case 'counter':
        return 'Gain $value Counter';
      case 'immunity':
        return 'Gain $value Immunity';
      case 'heal':
        return 'Heal $value HP';
      case 'dot':
        return 'Apply $value DoT';
      case 'damagereduce':
      case 'weaken':
        return 'Apply $value Weaken';
      case 'vulnerable':
        return 'Apply $value vulnerable';
      default:
        return 'Apply $value $key';
    }
  }

  String _formatWinEffects(int power, Map<String, int> winEffects) {
    final List<String> lines = ["Deal $power damage"];
    winEffects.forEach((key, val) {
      if (val > 0) {
        lines.add(_formatEffect(key, val));
      }
    });
    return lines.join("\n");
  }

  String _formatLoseEffects(Map<String, int> loseEffects) {
    if (loseEffects.isEmpty) return "No effect";
    final List<String> lines = [];
    loseEffects.forEach((key, val) {
      if (val > 0) {
        lines.add(_formatEffect(key, val));
      }
    });
    return lines.isEmpty ? "No effect" : lines.join("\n");
  }

  Widget _buildKeywordWidget(Map<String, int> winEffects, Map<String, int> loseEffects) {
    final Set<String> activeKeys = {};
    winEffects.forEach((key, val) {
      if (val > 0) activeKeys.add(key.toLowerCase());
    });
    loseEffects.forEach((key, val) {
      if (val > 0) activeKeys.add(key.toLowerCase());
    });

    final List<Widget> keywordWidgets = [];

    for (final key in activeKeys) {
      final explanation = TooltipHelper.getStatusEffectExplanation(key);
      if (explanation.isNotEmpty && explanation != "Efek status khusus.") {
        String displayKeyName = key.toUpperCase();
        if (key == 'damagereduce') displayKeyName = 'WEAKEN';

        keywordWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xE12A2215),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x80C5A059), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "KEYWORD: $displayKeyName",
                    style: const TextStyle(
                      color: Color(0xFFC5A059),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    explanation,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 8.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (keywordWidgets.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keywordWidgets,
    );
  }

}

class CardPainter extends CustomPainter {
  final String id, title, win, lose;
  final Color brown = const Color(0xFFD2691E);
  final Color cream = const Color(0xFFF6E2B0);
  final Color offWhite = const Color(0xFFFDF5E6);

  CardPainter({required this.id, required this.title, required this.win, required this.lose});

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 600;

    // 1. Hexagon Nama (Atas)
    final hexPath = Path();
    hexPath.moveTo(85 * scale, 35 * scale);
    hexPath.lineTo(560 * scale, 35 * scale);
    hexPath.lineTo(580 * scale, 85 * scale);
    hexPath.lineTo(560 * scale, 135 * scale);
    hexPath.lineTo(85 * scale, 135 * scale);
    hexPath.close();
    canvas.drawPath(hexPath, Paint()..color = Colors.black.withOpacity(0.7));
    canvas.drawPath(hexPath, Paint()..color = brown..strokeWidth = 4 * scale..style = PaintingStyle.stroke);

    // 2. Octagon Deskripsi (Bawah)
    final Rect octRect = Rect.fromLTWH(20 * scale, size.height - 240 * scale, 560 * scale, 220 * scale);
    _drawOctagon(canvas, octRect, 30 * scale, Colors.black.withOpacity(0.7), brown, 4 * scale);

    // 3. Circle ID & Title
    _drawTripleBorderCircle(canvas, Offset(85 * scale, 85 * scale), 65 * scale, scale);
    _drawText(canvas, id, Offset(85 * scale, 80 * scale), 60 * scale, FontWeight.bold, maxWidth: 130 * scale, maxLines: 1);
    _drawText(canvas, title, Offset(320 * scale, 85 * scale), 48 * scale, FontWeight.bold, maxWidth: 300 * scale, maxLines: 1);

    // 4. Deskripsi Win/Lose (Di dalam Octagon Bawah)
    _drawDiamond(canvas, Offset(octRect.left + 26 * scale, octRect.top + 53 * scale), 13 * scale, const Color(0xFF4ADE80));
    _drawText(canvas, win, Offset(octRect.left + 59 * scale, octRect.top + 53 * scale), 36 * scale, FontWeight.normal, textAlign: TextAlign.left, maxWidth: 460 * scale);

    // Garis Pemisah (Divider Line)
    final Paint dividerPaint = Paint()
      ..color = brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale;
    canvas.drawLine(
      Offset(octRect.left, octRect.top + 110 * scale),
      Offset(octRect.right, octRect.top + 110 * scale),
      dividerPaint,
    );

    _drawDiamond(canvas, Offset(octRect.left + 26 * scale, octRect.top + 163 * scale), 13 * scale, const Color(0xFFF87171));
    _drawText(canvas, lose, Offset(octRect.left + 59 * scale, octRect.top + 163 * scale), 36 * scale, FontWeight.normal, textAlign: TextAlign.left, maxWidth: 460 * scale);

    // 5. Ikon Kanan Bawah
    final Offset iconPos = Offset(size.width - 70 * scale, size.height - 70 * scale);
    _drawTripleBorderCircle(canvas, iconPos, 50 * scale, scale);
    final Paint paintLine = Paint()..color = offWhite..style = PaintingStyle.stroke..strokeWidth = 5 * scale;
    canvas.drawLine(iconPos - Offset(20 * scale, -20 * scale), iconPos + Offset(20 * scale, -20 * scale), paintLine);
  }

  void _drawTripleBorderCircle(Canvas canvas, Offset center, double radius, double scale) {
    canvas.drawCircle(center, radius, Paint()..color = Colors.black.withOpacity(0.7));
    canvas.drawCircle(center, radius - 2 * scale, Paint()..color = brown..style = PaintingStyle.stroke..strokeWidth = 2 * scale);
    canvas.drawCircle(center, radius + 2 * scale, Paint()..color = cream..style = PaintingStyle.stroke..strokeWidth = 10 * scale);
    canvas.drawCircle(center, radius + 5 * scale, Paint()..color = brown..style = PaintingStyle.stroke..strokeWidth = 2 * scale);
  }

  void _drawOctagon(Canvas canvas, Rect rect, double cut, Color fill, Color stroke, double strokeWidth) {
    final path = Path();
    path.moveTo(rect.left + cut, rect.top);
    path.lineTo(rect.right - cut, rect.top);
    path.lineTo(rect.right, rect.top + cut);
    path.lineTo(rect.right, rect.bottom - cut);
    path.lineTo(rect.right - cut, rect.bottom);
    path.lineTo(rect.left + cut, rect.bottom);
    path.lineTo(rect.left, rect.bottom - cut);
    path.lineTo(rect.left, rect.top + cut);
    path.close();
    canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Color color) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size, center.dy);
    path.close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawText(Canvas canvas, String text, Offset position, double fontSize, FontWeight weight, {TextAlign textAlign = TextAlign.center, required double maxWidth, int? maxLines, Color? color}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color ?? offWhite, fontSize: fontSize, fontWeight: weight, fontFamily: 'Familjen Grotesk')),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    final offset = textAlign == TextAlign.center ? Offset(tp.width / 2, tp.height / 2) : Offset(0, tp.height / 2);
    tp.paint(canvas, position - offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}