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
  int? _hoveredCardIndex;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final List<PlayingCard> handCards = widget.boardState.player.hand;
    final int cardCount = handCards.length;

    if (cardCount == 0) return const SizedBox.shrink();

    final double dynamicCardWidth = widget.screenSize.width * 0.13;

    // Generate seluruh list widget kartu tangan
    List<Widget> fannedCards = List.generate(cardCount, (index) {
      final card = handCards[index];
      
      final double midIndex = (cardCount - 1) / 2;
      final double offsetFromCenter = index - midIndex;

      final double rotationAngle = offsetFromCenter * 0.05; 
      final double translateX = offsetFromCenter * (widget.screenSize.width * 0.11);
      final double translateY = ((offsetFromCenter * offsetFromCenter) * 5.0) + (dynamicCardWidth / 2);

      final bool isHovered = index == _hoveredCardIndex && !_isDragging;
      final bool tooltipOnRight = translateX < 0; // Kiri -> Tampil Kanan, Kanan -> Tampil Kiri

      return Positioned(
        key: ValueKey('${card.id}_$index'), 
        width: dynamicCardWidth + 20, 
        height: (dynamicCardWidth * 1.4) + 20,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
          transform: Matrix4.identity()
            ..translateByDouble(translateX, translateY + (isHovered ? -(dynamicCardWidth / 2) : 0.0), 0.0, 1.0)
            ..rotateZ(isHovered ? 0 : rotationAngle),
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  if (_hoveredCardIndex == index) {
                    _hoveredCardIndex = null; // Tutup kartu jika diketuk ulang
                  } else {
                    _hoveredCardIndex = index; // Buka kartu ini
                  }
                });
              },
              child: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _hoveredCardIndex = index;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _hoveredCardIndex = null;
                  });
                },
                child: Draggable<PlayingCard>(
                  data: card,
                  hitTestBehavior: HitTestBehavior.opaque,
                  onDragStarted: () {
                    setState(() {
                      _hoveredCardIndex = null;
                      _isDragging = true;
                    });
                  },
                  onDragEnd: (details) {
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
                      tooltipOnRight: tooltipOnRight,
                      disableTooltip: true,
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.15,
                    child: GameCardWidget(
                      card: card,
                      isPlayerCard: true,
                      width: dynamicCardWidth,
                      disableTooltip: true,
                    ),
                  ),
                  child: GameCardWidget(
                    card: card,
                    isPlayerCard: true,
                    width: dynamicCardWidth,
                    tooltipOnRight: tooltipOnRight,
                    forceShowTooltip: isHovered,
                    disableTooltip: _isDragging,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  });

    // Jika ada kartu yang sedang di-hover, naikkan ke tumpukan paling depan
    if (_hoveredCardIndex != null && _hoveredCardIndex! < fannedCards.length) {
      final Widget hoveredWidget = fannedCards.removeAt(_hoveredCardIndex!);
      fannedCards.add(hoveredWidget);
    }

    return Center(
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: fannedCards,
      ),
    );
  }
}