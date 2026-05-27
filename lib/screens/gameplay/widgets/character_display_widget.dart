import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../board/board_state.dart';
import '../../../utils/tooltip_helper.dart';
import '../../../components/custom_tooltip_overlay.dart';

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
    final boardState = context.watch<BoardState>();
    final activePlayer = isPlayer ? boardState.player : boardState.enemy;

    final String assetPath = isPlayer
        ? 'assets/images/characters/default_player.png'
        : 'assets/images/characters/default_enemy.png';

    // 1. INTENT BUBBLE (Enemy Only)
    Widget? intentBubble;
    if (!isPlayer) {
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
                color: Colors.black.withOpacity(0.4),
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

    // 2. NAME AND SHIELD ROW
    final Widget nameAndShieldRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          activePlayer.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 3,
                color: Colors.black87,
              ),
            ],
          ),
        ),
        if (activePlayer.shield > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.blue[900]!.withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue[300]!, width: 1.2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1.5)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield,
                  color: Colors.blue[100]!,
                  size: 11,
                ),
                const SizedBox(width: 2),
                Text(
                  "${activePlayer.shield}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    // 3. HP BAR
    final double hpPercent = (activePlayer.hp / activePlayer.maxHp).clamp(0.0, 1.0);
    final double barWidth = width * 0.85;

    final Widget hpBar = Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${activePlayer.hp} / ${activePlayer.maxHp}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1.0, 1.0),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: barWidth,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: hpPercent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPlayer
                          ? [const Color(0xFF4ADE80), const Color(0xFF16A34A)]
                          : [const Color(0xFFF87171), const Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // 4. STATUS EFFECTS AND SYNERGIES WRAP (Below Ground Shadow)
    IconData getSynergyIcon(String synergy) {
      switch (synergy.toLowerCase()) {
        case 'fire': return Icons.local_fire_department_rounded;
        case 'liquid': return Icons.water_drop_rounded;
        case 'nature': return Icons.forest_rounded;
        case 'air': return Icons.wb_cloudy_rounded;
        case 'robot': return Icons.precision_manufacturing_rounded;
        case 'cosmic': return Icons.auto_awesome_rounded;
        case 'energy': return Icons.bolt_rounded;
        case 'spirit': return Icons.psychology_rounded;
        case 'dark': return Icons.shield_moon_rounded;
        case 'ancient': return Icons.gavel_rounded;
        case 'toxic': return Icons.science_rounded;
        default: return Icons.layers_rounded;
      }
    }

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
      final activeEffects = activePlayer.activeEffects;
      final activeSynergies = isPlayer ? boardState.playerSynergies : <String, int>{};

      if (activeEffects.isEmpty && activeSynergies.isEmpty) return const SizedBox.shrink();

      final List<Widget> synergyBadges = activeSynergies.entries.where((e) => e.value > 0).map((entry) {
        final syn = entry.key;
        final count = entry.value;
        final Color syncColor = TooltipHelper.getSynergyColor(syn);
        final IconData syncIcon = getSynergyIcon(syn);
        final String explanation = TooltipHelper.getSynergyExplanation(syn);

        return CustomTooltipOverlay(
          tooltipContent: buildTooltipBubble("Synergy: ${syn.toUpperCase()}", explanation, syncColor),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
            decoration: BoxDecoration(
              color: syncColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFC5A059), width: 1.0),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(syncIcon, color: Colors.white, size: 12),
                const SizedBox(width: 2),
                Text(
                  "$count",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }).toList();

      final List<Widget> effectBadges = activeEffects.map((effect) {
        final String effName = effect.type.toString().split('.').last;
        final String effDesc = TooltipHelper.getStatusEffectExplanation(effName);

        return CustomTooltipOverlay(
          tooltipContent: buildTooltipBubble("Efek: ${effName.toUpperCase()}", effDesc, effect.badgeColor),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
            decoration: BoxDecoration(
              color: effect.badgeColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: effect.isBuff ? Colors.white30 : Colors.redAccent.withOpacity(0.3),
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

      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Wrap(
          spacing: 5,
          runSpacing: 3,
          alignment: WrapAlignment.center,
          children: [...synergyBadges, ...effectBadges],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (intentBubble != null) intentBubble,

        // A. CHARACTER SPRITE WITH BREATHING/FLOATING ANIMATION
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

        // B. GROUND SHADOW (Breathing scale synced with sprite)
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

        const SizedBox(height: 12),

        // C. BELOW CHARACTER HUD: NAME, SHIELD & HP BAR
        nameAndShieldRow,
        hpBar,

        // D. ACTIVE STATUS EFFECTS & SYNERGIES
        buildStatusEffectsList(),
      ],
    );
  }
}


