import 'package:flutter/material.dart';
import '../../../board/board_state.dart';
import '../../../models/playing_card.dart';
import 'game_card_widget.dart';

class PlayerHandWidget extends StatefulWidget {
  final BoardState boardState;
  final Size screenSize;

  const PlayerHandWidget({
    super.key,
    required this.boardState,
    required this.screenSize,
  });

  @override
  State<PlayerHandWidget> createState() => _PlayerHandWidgetState();
}

class _PlayerHandWidgetState extends State<PlayerHandWidget> {
  // FIXED UNIQUE STATE: Menggunakan index (int) bukan card.id agar kartu duplikat tidak ikut ter-hover
  int? _hoveredCardIndex;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final List<PlayingCard> handCards = widget.boardState.player.hand;
    final int cardCount = handCards.length;

    if (cardCount == 0) return const SizedBox.shrink();

    final double dynamicCardWidth = widget.screenSize.width * 0.13;

    // 1. Generate seluruh list widget kartu terlebih dahulu ke dalam sebuah List variabel
    List<Widget> fannedCards = List.generate(cardCount, (index) {
      final card = handCards[index];
      
      final double midIndex = (cardCount - 1) / 2;
      final double offsetFromCenter = index - midIndex;

      final double rotationAngle = offsetFromCenter * 0.05; 
      final double translateX = offsetFromCenter * (widget.screenSize.width * 0.11);
      final double translateY = ((offsetFromCenter * offsetFromCenter) * 5.0) + (dynamicCardWidth / 2);

      // FIXED UNIQUE CHECK: Kunci perbandingan berbasis index posisi tangan murni
      final bool isHovered = index == _hoveredCardIndex && !_isDragging; // Hanya hover jika index cocok dan tidak sedang drag aktif

      return Positioned(
        // Gunakan ValueKey gabungan ID dan Index agar elemen re-render secara independen dan akurat
        key: ValueKey('${card.id}_$index'), 
        width: dynamicCardWidth + 20, 
        height: (dynamicCardWidth * 1.4) + 20,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
          transform: Matrix4.identity()
            ..translateByDouble(translateX, translateY + (isHovered ? -(dynamicCardWidth / 2) : 0.0), 0.0, 1.0)
            ..rotateZ(isHovered ? 0 : rotationAngle),
          child: UnconstrainedBox(
            child: MouseRegion(
              onEnter: (_) {
                setState(() {
                  _hoveredCardIndex = index; // Menyimpan index unik kartu saat ini
                });
              },
              onExit: (_) {
                setState(() {
                  _hoveredCardIndex = null; // Reset state
                });
              },
              child: AnimatedScale(
                scale: isHovered ? 1.15 : 1.0, 
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: Draggable<PlayingCard>(
                  data: card,
                  hitTestBehavior: HitTestBehavior.opaque,
                  onDragStarted: () {
                    setState(() {
                      _hoveredCardIndex = null;
                      _isDragging = true;
                    });
                  },
                  onDragCompleted: () {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  feedback: Material(
                    color: Colors.transparent,
                    child: GameCardWidget(
                      card: card,
                      isPlayerCard: true,
                      width: dynamicCardWidth * 1.15,
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.15,
                    child: GameCardWidget(
                      card: card,
                      isPlayerCard: true,
                      width: dynamicCardWidth,
                    ),
                  ),
                  child: GameCardWidget(
                    card: card,
                    isPlayerCard: true,
                    width: dynamicCardWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });

    // ========================================================
    // FIXED DYNAMIC Z-INDEX CODES
    // ========================================================
    // Jika ada kartu yang sedang di-hover, cabut widget tersebut dari posisi index lamanya
    // lalu dorong (add) ke tumpukan paling akhir agar posisinya berada di layer paling depan layar.
    if (_hoveredCardIndex != null && _hoveredCardIndex! < fannedCards.length) {
      final Widget hoveredWidget = fannedCards.removeAt(_hoveredCardIndex!);
      fannedCards.add(hoveredWidget);
    }

    return Center(
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: fannedCards, // Merender susunan kartu dengan Z-Index yang telah dimanipulasi secara dinamis
      ),
    );
  }
}