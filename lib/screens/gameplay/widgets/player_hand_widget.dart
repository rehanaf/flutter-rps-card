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
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final List<PlayingCard> handCards = widget.boardState.player.hand;
    final int cardCount = handCards.length;

    if (cardCount == 0) return const SizedBox.shrink();

    final double dynamicCardWidth = widget.screenSize.width * 0.1;

    // Generate seluruh list widget kartu tangan
    List<Widget> fannedCards = List.generate(cardCount, (index) {
      final card = handCards[index];
      
      final double midIndex = (cardCount - 1) / 2;
      final double offsetFromCenter = index - midIndex;

      final double rotationAngle = offsetFromCenter * 0.05; 
      final double translateX = offsetFromCenter * (widget.screenSize.width * 0.08);
      final double translateY = ((offsetFromCenter * offsetFromCenter) * 5.0) + (dynamicCardWidth / 2);

      final int? activeHoverIndex = widget.boardState.hoveredCardIndex;
      final bool isHovered = index == activeHoverIndex && !widget.boardState.isDragOverTarget;
      final bool tooltipOnRight = translateX < 0; // Kiri -> Tampil Kanan, Kanan -> Tampil Kiri

      final bool isDraggingThisCard = card == widget.boardState.draggingCard;
      final bool isSnappedToTable = isDraggingThisCard && widget.boardState.isDragOverTarget;

      final double cardHeight = (dynamicCardWidth * 1.4) + 20;

      // 1. Hitung koordinat transformasi untuk center-fly & drop-snap
      final double finalTranslateX;
      final double finalTranslateY;
      final double finalRotation;
      final double finalScale;

      if (isSnappedToTable) {
        finalTranslateX = -widget.screenSize.width * 0.10;
        finalTranslateY = -((widget.screenSize.height - 56.0) * 0.50 - cardHeight / 2);
        finalRotation = 0.0;
        finalScale = 1.0;
      } else if (isHovered) {
        finalTranslateX = 0.0;
        finalTranslateY = -(widget.screenSize.height * 0.50 - cardHeight / 2);
        finalRotation = 0.0;
        finalScale = 2.0;
      } else {
        finalTranslateX = translateX;
        finalTranslateY = translateY;
        finalRotation = rotationAngle;
        finalScale = 1.0;
      }

      return Positioned(
        key: ValueKey('${card.id}_$index'), 
        width: dynamicCardWidth + 20, 
        height: (dynamicCardWidth * 1.4) + 20,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(finalTranslateX, finalTranslateY, 0.0, 1.0)
            ..rotateZ(finalRotation)
            ..scale(finalScale, finalScale, 1.0),
          child: OverflowBox(
            minWidth: 0.0,
            minHeight: 0.0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                widget.boardState.setHoveredCardIndex(index);
                final pos = details.globalPosition;
                widget.boardState.updateActiveGesture("HOLDING", x: pos.dx, y: pos.dy);
                widget.boardState.addGestureLog("Card #${index} (${card.id}) onTapDown - Zoom Active at (${pos.dx.toStringAsFixed(0)}, ${pos.dy.toStringAsFixed(0)})");
              },
              onTapUp: (details) {
                widget.boardState.setHoveredCardIndex(null);
                widget.boardState.updateActiveGesture("IDLE");
                final pos = details.globalPosition;
                widget.boardState.addGestureLog("Card #${index} (${card.id}) onTapUp - Zoom Released at (${pos.dx.toStringAsFixed(0)}, ${pos.dy.toStringAsFixed(0)})");
              },
              child: Draggable<PlayingCard>(
                data: card,
                hitTestBehavior: HitTestBehavior.opaque,
                onDragStarted: () {
                  widget.boardState.draggingCard = card;
                  widget.boardState.isDragOverTarget = false;
                  widget.boardState.updateActiveGesture("DRAGGING");
                  widget.boardState.addGestureLog("Card #${index} (${card.id}) onDragStarted - Drag Active");
                  setState(() {
                    _isDragging = true;
                  });
                },
                onDragUpdate: (details) {
                  final pos = details.globalPosition;
                  widget.boardState.updateActiveGesture("DRAGGING", x: pos.dx, y: pos.dy);
                },
                onDragEnd: (details) {
                  widget.boardState.setHoveredCardIndex(null); // Jari dilepas -> hover mati!
                  widget.boardState.draggingCard = null;
                  widget.boardState.isDragOverTarget = false;
                  widget.boardState.previewPlayerCard = null;
                  widget.boardState.updateActiveGesture("IDLE");
                  widget.boardState.addGestureLog("Card onDragEnd - Drag Released at (${details.offset.dx.toStringAsFixed(0)}, ${details.offset.dy.toStringAsFixed(0)})");
                  setState(() {
                    _isDragging = false;
                  });
                },
                feedback: const SizedBox.shrink(),
                childWhenDragging: GameCardWidget(
                  card: card,
                  isPlayerCard: true,
                  width: dynamicCardWidth,
                  tooltipOnRight: tooltipOnRight,
                  disableTooltip: true,
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
      );
  });

    // Jika ada kartu yang sedang di-hover, naikkan ke tumpukan paling depan
    final int? activeHoverIndex = widget.boardState.hoveredCardIndex;
    if (activeHoverIndex != null && activeHoverIndex < fannedCards.length) {
      final Widget hoveredWidget = fannedCards.removeAt(activeHoverIndex);
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