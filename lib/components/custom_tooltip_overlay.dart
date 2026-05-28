import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomTooltipOverlay extends StatefulWidget {
  final Widget child;
  final Widget tooltipContent;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;

  const CustomTooltipOverlay({
    super.key,
    required this.child,
    required this.tooltipContent,
    this.targetAnchor = Alignment.topCenter,
    this.followerAnchor = Alignment.bottomCenter,
    this.offset = const Offset(0, -6),
  });

  @override
  State<CustomTooltipOverlay> createState() => _CustomTooltipOverlayState();
}

class _CustomTooltipOverlayState extends State<CustomTooltipOverlay> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;

  void _showTooltip() {
    if (!mounted) return;
    _hideTooltip();
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: widget.targetAnchor,
          followerAnchor: widget.followerAnchor,
          offset: widget.offset,
          child: UnconstrainedBox(
            alignment: widget.followerAnchor,
            child: Material(
              color: Colors.transparent,
              child: widget.tooltipContent
                .animate()
                .fadeIn(duration: 120.ms)
                .moveY(begin: 2, end: 0, duration: 120.ms),
            ),
          ),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlayEntry != null) {
        try {
          Overlay.of(context).insert(_overlayEntry!);
        } catch (_) {}
      }
    });
  }

  void _hideTooltip() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _showTooltip();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hideTooltip();
      },
      child: GestureDetector(
        onLongPressStart: (_) => _showTooltip(),
        onLongPressEnd: (_) => _hideTooltip(),
        onTapDown: (_) => _showTooltip(),
        onTapUp: (_) => Future.delayed(const Duration(seconds: 2), _hideTooltip),
        onTapCancel: () => _hideTooltip(),
        child: CompositedTransformTarget(
          link: _layerLink,
          child: widget.child,
        ),
      ),
    );
  }
}
