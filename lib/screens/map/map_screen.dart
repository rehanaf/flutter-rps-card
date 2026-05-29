import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../board/board_state.dart';
import '../../board/player_run.dart';
import '../../services/app_localizations.dart';
import '../../components/game_app_bar.dart';
import '../gameplay/gameplay_screen.dart';
import '../shop/shop_screen.dart';
import '../../models/map_node_data.dart';

class MapScreen extends StatelessWidget {
  static const String routeName = '/map';

  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerRun = context.watch<PlayerRun>();
    final localization = AppLocalizations.of(context)!;
    final Size screenSize = MediaQuery.of(context).size;

    final mapNodes = playerRun.mapNodes;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GameAppBar(showBackButton: true),
      body: Stack(
        children: [
          // Wallpaper Background dengan overlay gelap
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/default.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF141414), Color(0xFF0F0F0F)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.75)),
          ),

          // Konten Utama
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: 720,
                height: 320,
                child: Stack(
                  children: [
                    // 1. GAMBAR GARIS KONEKSI CABANG (CustomPaint)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: MapConnectionsPainter(
                          nodes: mapNodes,
                          completedNodeIds: playerRun.completedNodeIds,
                          lastCompletedNodeId: playerRun.lastCompletedNodeId,
                          currentFloor: playerRun.currentFloor,
                        ),
                      ),
                    ),

                    // 2. RENDERING TOMBOL-TOMBOL NODE
                    ...mapNodes.map((node) {
                      final bool isCompleted = playerRun.completedNodeIds.contains(node.id);
                      
                      // Node aktif dicek dari: lantai aktif pemain DAN memiliki relasi parent dengan node terakhir yang diselesaikan
                      final bool isCurrent = node.floor == playerRun.currentFloor &&
                          (node.parentIds.isEmpty || node.parentIds.contains(playerRun.lastCompletedNodeId));
                      
                      final bool isLocked = !isCompleted && !isCurrent;

                      return Positioned(
                        left: node.x - 34, // Centered (width 68)
                        top: node.y - 34,  // Centered (height 68)
                        child: _buildMapNodeButton(
                          context,
                          node: node,
                          isCurrent: isCurrent,
                          isCompleted: isCompleted,
                          isLocked: isLocked,
                          localization: localization,
                          screenSize: screenSize,
                          playerRun: playerRun,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapNodeButton(
    BuildContext context, {
    required MapNodeData node,
    required bool isCurrent,
    required bool isCompleted,
    required bool isLocked,
    required AppLocalizations localization,
    required Size screenSize,
    required PlayerRun playerRun,
  }) {
    IconData nodeIcon = Icons.gavel_rounded;
    Color nodeColor = const Color(0xFF2C2C2C);
    Color borderColor = Colors.white24;

    if (node.type == 'SHOP') {
      nodeIcon = Icons.shopping_bag_rounded;
      if (isCurrent) nodeColor = Colors.blueGrey[800]!;
    } else if (node.type == 'BOSS') {
      nodeIcon = Icons.brightness_auto_sharp;
      if (isCurrent) nodeColor = Colors.red[900]!;
    } else {
      if (isCurrent) nodeColor = const Color(0xFF8B7343);
    }

    if (isCurrent) {
      borderColor = const Color(0xFFC5A059);
    } else if (isCompleted) {
      borderColor = const Color(0x80C5A059);
      nodeColor = Colors.black45;
    }

    return GestureDetector(
      onTap: isCurrent 
          ? () => _handleNodeTap(context, node, localization, screenSize, playerRun)
          : null,
      child: Opacity(
        opacity: isLocked ? 0.35 : 1.0,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: nodeColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: isCurrent ? 3.5 : 2),
            boxShadow: isCurrent
                ? [
                    const BoxShadow(
                      color: Color(0xFFC5A059),
                      blurRadius: 14,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Icon(
            nodeIcon,
            color: isCurrent ? const Color(0xFFC5A059) : (isCompleted ? Colors.white54 : Colors.white24),
            size: node.type == 'BOSS' ? 34 : 26,
          ),
        ),
      ),
    );
  }

  void _handleNodeTap(
    BuildContext context,
    MapNodeData node,
    AppLocalizations localization,
    Size screenSize,
    PlayerRun playerRun,
  ) {
    if (node.type == 'BATTLE' || node.type == 'BOSS') {
      final enemyMeta = localization.getEnemyMetadata(node.enemyId);
      
      if (enemyMeta == null) {
        debugPrint('Error: Profil musuh ${node.enemyId} gagal ditemukan!');
        return;
      }

      final boardState = Provider.of<BoardState>(context, listen: false);

      // Simpan node terpilih saat ini ke playerRun
      playerRun.selectedNodeId = node.id;
      playerRun.inBattle = true;

      boardState.initializeBattle(
        playerRun: playerRun,
        enemyMeta: enemyMeta,
        allCards: localization.allCardsMetadata,
      );

      Navigator.pushNamed(context, GameplayScreen.routeName);
      
    } else if (node.type == 'SHOP') {
      // Buka Shop Screen interaktif
      playerRun.selectedNodeId = node.id;

      Navigator.pushNamed(context, ShopScreen.routeName);
    }
  }
}

/// Painter khusus untuk menggambar garis penghubung rute cabang di Peta
class MapConnectionsPainter extends CustomPainter {
  final List<MapNodeData> nodes;
  final List<String> completedNodeIds;
  final String? lastCompletedNodeId;
  final int currentFloor;

  MapConnectionsPainter({
    required this.nodes,
    required this.completedNodeIds,
    required this.lastCompletedNodeId,
    required this.currentFloor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint activePaint = Paint()
      ..color = const Color(0xFFC5A059)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Paint inactivePaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var node in nodes) {
      if (node.parentIds.isEmpty) continue;
      
      for (var parentId in node.parentIds) {
        final parent = nodes.firstWhere((n) => n.id == parentId);
        
        // Rute dianggap terlewati jika parent dan node ini sudah diselesaikan
        final bool isPathCompleted = completedNodeIds.contains(parent.id) && completedNodeIds.contains(node.id);
        
        // Rute dianggap aktif jika parent merupakan node terakhir yang selesai DAN node adalah node saat ini di lantai aktif
        final bool isPathCurrent = parent.id == lastCompletedNodeId &&
            node.floor == currentFloor;

        final Paint paintToUse = (isPathCompleted || isPathCurrent) ? activePaint : inactivePaint;

        canvas.drawLine(
          Offset(parent.x, parent.y),
          Offset(node.x, node.y),
          paintToUse,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapConnectionsPainter oldDelegate) {
    return oldDelegate.currentFloor != currentFloor ||
        oldDelegate.lastCompletedNodeId != lastCompletedNodeId ||
        oldDelegate.completedNodeIds.length != completedNodeIds.length;
  }
}