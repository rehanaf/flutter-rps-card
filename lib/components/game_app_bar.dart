import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../board/player_run.dart';

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;

  const GameAppBar({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final playerRun = context.watch<PlayerRun>();

    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      foregroundColor: const Color(0xFFC5A059),
      automaticallyImplyLeading: showBackButton,
      title: const SizedBox.shrink(),
      elevation: 0,
      centerTitle: true,
      actions: [
        Row(
          children: [
            const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
            const SizedBox(width: 6),
            Text(
              '${playerRun.currentHp}/${playerRun.maxHp}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 20),
            const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
            const SizedBox(width: 6),
            Text(
              '${playerRun.gold}G',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 16),
          ],
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
