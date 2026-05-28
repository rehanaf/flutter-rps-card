import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../board/board_state.dart';
import '../../../utils/tooltip_helper.dart';
import '../../../components/custom_tooltip_overlay.dart';
import '../../../models/status_effect.dart';

class _EffectAnimInfo {
  final IconData icon;
  final Color color;
  _EffectAnimInfo(this.icon, this.color);
}

class CharacterDisplayWidget extends StatefulWidget {
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
  State<CharacterDisplayWidget> createState() => _CharacterDisplayWidgetState();
}

class _CharacterDisplayWidgetState extends State<CharacterDisplayWidget> {
  int _prevShield = 0;
  Map<EffectType, int> _prevEffects = {};
  bool _isFirstRun = true;

  // Premium transient animation state
  IconData? _animIcon;
  Color? _animColor;
  int _animTriggerCounter = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final boardState = Provider.of<BoardState>(context);
    final activePlayer = widget.isPlayer ? boardState.player : boardState.enemy;

    // 1. Calculate current total shield
    int currentShield = activePlayer.shield;
    if (activePlayer.hasEffect(EffectType.shield)) {
      currentShield += activePlayer.getEffect(EffectType.shield).value;
    }

    // 2. Compile current effects map (excluding shield)
    Map<EffectType, int> currentEffects = {};
    for (var effect in activePlayer.activeEffects) {
      if (effect.type != EffectType.shield) {
        currentEffects[effect.type] = effect.value;
      }
    }

    // 3. First run initialization to avoid false animations on match start
    if (_isFirstRun) {
      _prevShield = currentShield;
      _prevEffects = currentEffects;
      _isFirstRun = false;
      return;
    }

    // 4. Detect Shield increase
    if (currentShield > _prevShield) {
      _triggerAnim(Icons.shield_rounded, const Color(0xFF60A5FA));
    }

    // 5. Detect other effects increase/addition
    currentEffects.forEach((type, value) {
      final prevVal = _prevEffects[type] ?? 0;
      if (value > prevVal) {
        final info = _getEffectAnimInfo(type);
        _triggerAnim(info.icon, info.color);
      }
    });

    // 6. Update previous values
    _prevShield = currentShield;
    _prevEffects = currentEffects;
  }

  void _triggerAnim(IconData icon, Color color) {
    setState(() {
      _animIcon = icon;
      _animColor = color;
      _animTriggerCounter++;
    });
  }

  _EffectAnimInfo _getEffectAnimInfo(EffectType type) {
    switch (type) {
      case EffectType.strength:
        return _EffectAnimInfo(Icons.fitness_center, Colors.orange[800]!);
      case EffectType.counter:
        return _EffectAnimInfo(Icons.replay, Colors.amber[700]!);
      case EffectType.immunity:
        return _EffectAnimInfo(Icons.gpp_good, Colors.purple[700]!);
      case EffectType.dot:
        return _EffectAnimInfo(Icons.water_drop, Colors.red[900]!);
      case EffectType.damageReduce:
        return _EffectAnimInfo(Icons.heart_broken, Colors.grey[700]!);
      case EffectType.vulnerable:
        return _EffectAnimInfo(Icons.coronavirus, Colors.deepOrange[900]!);
      case EffectType.heal:
        return _EffectAnimInfo(Icons.healing_rounded, Colors.greenAccent[700]!);
      default:
        return _EffectAnimInfo(Icons.flash_on, Colors.yellow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();
    final activePlayer = widget.isPlayer ? boardState.player : boardState.enemy;

    final String assetPath = widget.isPlayer
        ? 'assets/images/characters/default_player.png'
        : 'assets/images/characters/default_enemy.png';

    // ANIMATION STATE DETERMINATION (ATTACK & HIT TRIGGERS)
    final activeOverlay = boardState.activeOverlay;
    String animState = 'idle';
    if (activeOverlay != null) {
      if (activeOverlay.eventType == 'clash_win') {
        animState = widget.isPlayer ? 'attack' : 'hit';
      } else if (activeOverlay.eventType == 'clash_lose') {
        animState = widget.isPlayer ? 'hit' : 'attack';
      }
    }

    // 1. INTENT BUBBLE (Enemy Only)
    Widget? intentBubble;
    if (!widget.isPlayer) {
      final nextCard = boardState.nextEnemyCard;
      if (nextCard != null && boardState.playerCardOnTable == null) {
        final icon = boardState.enemyIntentIcon;
        final sectorIcon = boardState.enemyIntentSectorIcon;
        final color = boardState.enemyIntentColor;

        intentBubble = Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xEC1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white24,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (boardState.enemyIntentText != null) ...[
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 2),
                Icon(sectorIcon, color: Colors.white70, size: 16),
              ] else ...[
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                const Text(
                  "Bersiap...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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

    // Calculate total shield (real shield + pending status effect shield)
    int totalShield = activePlayer.shield;
    if (activePlayer.hasEffect(EffectType.shield)) {
      totalShield += activePlayer.getEffect(EffectType.shield).value;
    }

    final double hpPercent = (activePlayer.hp / activePlayer.maxHp).clamp(0.0, 1.0);
    final double barWidth = widget.width * 0.85;
    final double barHeight = 11.0;

    final Widget hpBar = TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: hpPercent, end: hpPercent),
      builder: (context, catchUpHp, child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          tween: Tween<double>(begin: hpPercent, end: hpPercent),
          builder: (context, mainHp, child) {
            return SizedBox(
              width: barWidth,
              height: barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Background hexagon (empty)
                  ClipPath(
                    clipper: _HexagonClipper(),
                    child: Container(
                      color: Colors.black54,
                    ),
                  ),
                  // Damage Catch-up bar (drains slowly)
                  if (catchUpHp > mainHp)
                    FractionallySizedBox(
                      widthFactor: catchUpHp,
                      child: ClipPath(
                        clipper: _HexagonClipper(),
                        child: Container(
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  // Filled portion (main HP) - BOTH player and enemy are red
                  FractionallySizedBox(
                    widthFactor: mainHp,
                    child: ClipPath(
                      clipper: _HexagonClipper(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF87171), Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Dark red border outline for the HP bar
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HexagonBorderPainter(
                        color: const Color(0xFF5C0606),
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                  // Centered HP text with premium outline stroke
                  Positioned(
                    top: -5.5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Stroke outline
                          Text(
                            '${activePlayer.hp} / ${activePlayer.maxHp}',
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontSize: 18,
                              height: 1.0,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3.5
                                ..color = const Color(0xFF450A0A),
                            ),
                          ),
                          // Text fill
                          Text(
                            '${activePlayer.hp} / ${activePlayer.maxHp}',
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // SHIELD OVERLAY
                  if (totalShield > 0)
                    Positioned(
                      left: widget.isPlayer ? null : -8,
                      right: widget.isPlayer ? -8 : null,
                      top: -4.5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF60A5FA), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 3,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield_rounded,
                              color: Color(0xFF93C5FD),
                              size: 11,
                            ),
                            const SizedBox(width: 2.5),
                            Text(
                              "$totalShield",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    Widget buildTooltipBubble(String title, String description, Color color) {
      return Container(
        padding: const EdgeInsets.all(8),
        width: 150,
        decoration: BoxDecoration(
          color: const Color(0xEC1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.0),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(color: Colors.white70, fontSize: 9, height: 1.2)),
          ],
        ),
      );
    }

    Widget buildStatusEffectsList() {
      final activeEffects = activePlayer.activeEffects
          .where((effect) => effect.type != EffectType.shield)
          .toList();

      if (activeEffects.isEmpty) return const SizedBox(height: 32);

      final List<Widget> effectBadges = activeEffects.map((effect) {
        final String effName = effect.type.toString().split('.').last;
        final String effDesc = TooltipHelper.getStatusEffectExplanation(effName);

        return CustomTooltipOverlay(
          tooltipContent: buildTooltipBubble("Efek: ${effName.toUpperCase()}", effDesc, effect.badgeColor),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
            decoration: BoxDecoration(
              color: effect.badgeColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: effect.isBuff ? Colors.white30 : Colors.redAccent.withValues(alpha: 0.3),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  effect.icon,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  "${effect.value}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList();

      return SizedBox(
        height: 32,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            spacing: 5,
            runSpacing: 3,
            alignment: WrapAlignment.center,
            children: effectBadges,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (intentBubble != null) intentBubble,

        // A. CHARACTER SPRITE WITH BREATHING/FLOATING ANIMATION AND OVERLAY EFFECT
        Stack(
          alignment: Alignment.center,
          children: [
            () {
              Widget sprite = SizedBox(
                width: widget.width,
                height: widget.height,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: widget.isPlayer
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isPlayer ? Colors.blue : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.isPlayer ? 'Player' : 'Enemy',
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
              );

              // Apply target animation based on state
              if (animState == 'attack') {
                return sprite
                    .animate(key: ValueKey(activeOverlay.hashCode))
                    .moveX(
                      begin: 0,
                      end: widget.isPlayer ? 45.0 : -45.0,
                      duration: 200.ms,
                      curve: Curves.easeOutQuad,
                    )
                    .then()
                    .moveX(
                      begin: widget.isPlayer ? 45.0 : -45.0,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeInOut,
                    );
              } else if (animState == 'hit') {
                return sprite
                    .animate(key: ValueKey(activeOverlay.hashCode))
                    .shake(
                      hz: 10,
                      duration: 350.ms,
                      curve: Curves.easeInOut,
                    )
                    .scaleXY(
                      begin: 1.0,
                      end: 0.9,
                      duration: 100.ms,
                    )
                    .then()
                    .scaleXY(
                      begin: 0.9,
                      end: 1.0,
                      duration: 200.ms,
                    )
                    .tint(
                      color: Colors.red.withValues(alpha: 0.45),
                      duration: 150.ms,
                    )
                    .then()
                    .tint(
                      color: Colors.transparent,
                      duration: 150.ms,
                    );
              } else {
                return sprite
                    .animate(key: const ValueKey('idle'), onPlay: (controller) => controller.repeat(reverse: true))
                    .moveY(
                      begin: 0,
                      end: -8,
                      duration: 2200.ms,
                      curve: Curves.easeInOut,
                    );
              }
            }(),

            // Premium Transient Effect Animation Icon (grows, glows and fades out in the center of character)
            if (_animIcon != null)
              Positioned.fill(
                child: Center(
                  child: IgnorePointer(
                    child: KeyedSubtree(
                      key: ValueKey(_animTriggerCounter),
                      child: Icon(
                        _animIcon,
                        color: _animColor,
                        size: 96,
                      )
                      .animate(
                        onComplete: (controller) {
                          if (mounted) {
                            setState(() {
                              _animIcon = null;
                              _animColor = null;
                            });
                          }
                        },
                      )
                      .scale(
                        begin: const Offset(0.2, 0.2),
                        end: const Offset(2.2, 2.2),
                        duration: 1000.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(
                        duration: 200.ms,
                      )
                      .fadeOut(
                        delay: 600.ms,
                        duration: 400.ms,
                      )
                      .shimmer(
                        delay: 200.ms,
                        duration: 600.ms,
                        colors: [Colors.white, _animColor!, Colors.white],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        // B. GROUND SHADOW (Breathing scale synced with sprite)
        Container(
          width: widget.width * 0.6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.elliptical(widget.width * 0.6, 6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 0.8, duration: 2200.ms, curve: Curves.easeInOut)
        .fade(begin: 0.7, end: 0.4, duration: 2200.ms, curve: Curves.easeInOut),

        const SizedBox(height: 12),

        // C. BELOW CHARACTER HUD
        hpBar,
        const SizedBox(height: 4),
        buildStatusEffectsList(),
      ],
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cut = h * 0.5;
    final Path path = Path();
    path.moveTo(cut, 0);
    path.lineTo(w - cut, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w - cut, h);
    path.lineTo(cut, h);
    path.lineTo(0, h * 0.5);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexagonBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _HexagonBorderPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cut = h * 0.5;

    final Path path = Path();
    path.moveTo(cut, 0);
    path.lineTo(w - cut, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w - cut, h);
    path.lineTo(cut, h);
    path.lineTo(0, h * 0.5);
    path.close();

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
