import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../board/board_state.dart';
import '../../board/player_run.dart';
import '../../services/app_localizations.dart';
import '../../components/game_app_bar.dart';
import '../gameplay/gameplay_screen.dart';
import '../shop/shop_screen.dart';

/// Struktur data internal khusus untuk mendefinisikan tipe dan konten node di Peta bercabang
class MapNodeData {
  final String id;
  final String type; // 'BATTLE', 'SHOP', 'BOSS'
  final String enemyId; // ID Musuh dari enemies.json (jika bertipe BATTLE/BOSS)
  final int floor;
  final double x;
  final double y;
  final List<String> parentIds; // ID parent node yang menuju ke node ini

  MapNodeData({
    required this.id,
    required this.type,
    this.enemyId = '',
    required this.floor,
    required this.x,
    required this.y,
    required this.parentIds,
  });
}

class MapScreen extends StatelessWidget {
  static const String routeName = '/map';

  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerRun = context.watch<PlayerRun>();
    final localization = AppLocalizations.of(context)!;
    final Size screenSize = MediaQuery.of(context).size;

    // DEFINISI STRUKTUR PETA BERCABANG (6 LANTAI - MULTI JALUR MERGE KE BOSS)
    final List<MapNodeData> mapNodes = [
      // Floor 1 (Start)
      MapNodeData(
        id: 'node_1',
        type: 'BATTLE',
        enemyId: 'e_toxic_slime',
        floor: 1,
        x: 60,
        y: 150,
        parentIds: [],
      ),
      
      // Floor 2
      MapNodeData(
        id: 'node_2_1',
        type: 'BATTLE',
        enemyId: 'e_cyber_scout',
        floor: 2,
        x: 180,
        y: 90,
        parentIds: ['node_1'],
      ),
      MapNodeData(
        id: 'node_2_2',
        type: 'BATTLE',
        enemyId: 'e_wind_ranger',
        floor: 2,
        x: 180,
        y: 210,
        parentIds: ['node_1'],
      ),
      
      // Floor 3
      MapNodeData(
        id: 'node_3_1',
        type: 'BATTLE',
        enemyId: 'e_fire_mage',
        floor: 3,
        x: 300,
        y: 50,
        parentIds: ['node_2_1'],
      ),
      MapNodeData(
        id: 'node_3_2',
        type: 'SHOP',
        floor: 3,
        x: 300,
        y: 150,
        parentIds: ['node_2_1', 'node_2_2'],
      ),
      MapNodeData(
        id: 'node_3_3',
        type: 'BATTLE',
        enemyId: 'e_stone_golem',
        floor: 3,
        x: 300,
        y: 250,
        parentIds: ['node_2_2'],
      ),
      
      // Floor 4
      MapNodeData(
        id: 'node_4_1',
        type: 'BATTLE',
        enemyId: 'e_cosmic_spectre',
        floor: 4,
        x: 420,
        y: 90,
        parentIds: ['node_3_1', 'node_3_2'],
      ),
      MapNodeData(
        id: 'node_4_2',
        type: 'BATTLE',
        enemyId: 'e_stone_golem',
        floor: 4,
        x: 420,
        y: 210,
        parentIds: ['node_3_2', 'node_3_3'],
      ),
      
      // Floor 5
      MapNodeData(
        id: 'node_5_1',
        type: 'SHOP',
        floor: 5,
        x: 540,
        y: 90,
        parentIds: ['node_4_1'],
      ),
      MapNodeData(
        id: 'node_5_2',
        type: 'SHOP',
        floor: 5,
        x: 540,
        y: 210,
        parentIds: ['node_4_2'],
      ),
      
      // Floor 6 (Boss - Merged!)
      MapNodeData(
        id: 'node_6',
        type: 'BOSS',
        enemyId: 'e_boss_ancient_golem',
        floor: 6,
        x: 660,
        y: 150,
        parentIds: ['node_5_1', 'node_5_2'],
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GameAppBar(showBackButton: false),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141414), Color(0xFF0F0F0F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Profil musuh ${node.enemyId} gagal ditemukan!')),
        );
        return;
      }

      final boardState = Provider.of<BoardState>(context, listen: false);

      // Simpan node terpilih saat ini ke playerRun
      playerRun.selectedNodeId = node.id;

      boardState.initializeBattle(
        playerRun: playerRun,
        enemyMeta: enemyMeta,
        allCards: localization.allCardsMetadata,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masuk ke arena pertempuran melawan: ${enemyMeta.name}!')),
      );
      
      Navigator.pushNamed(context, GameplayScreen.routeName);
      
    } else if (node.type == 'SHOP') {
      // Buka Shop Screen interaktif
      playerRun.selectedNodeId = node.id;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengunjungi Merchant Tenda Pedagang...')),
      );

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