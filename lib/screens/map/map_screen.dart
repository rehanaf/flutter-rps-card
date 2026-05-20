import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../board/board_state.dart';
import '../../board/player_run.dart';
import '../../services/app_localizations.dart';
import '../gameplay/gameplay_screen.dart';

/// Struktur data internal khusus untuk mendefinisikan tipe dan konten node di Peta
class MapNodeData {
  final String id;
  final String type; // 'BATTLE', 'SHOP', 'BOSS'
  final String enemyId; // ID Musuh dari enemies.json (jika bertipe BATTLE/BOSS)

  MapNodeData({required this.id, required this.type, this.enemyId = ''});
}

class MapScreen extends StatelessWidget {
  static const String routeName = '/map';

  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerRun = context.watch<PlayerRun>();
    final localization = AppLocalizations.of(context)!;
    final Size screenSize = MediaQuery.of(context).size; // Ambil ukuran layar dasar

    // SIMULASI STRUKTUR JALUR MAP (Kiri ke Kanan - Total 6 Lantai/Node)
    final List<MapNodeData> horizontalMapNodes = [
      MapNodeData(id: 'node_1', type: 'BATTLE', enemyId: 'e_fire_mage'),
      MapNodeData(id: 'node_2', type: 'BATTLE', enemyId: 'e_golem'),
      MapNodeData(id: 'node_3', type: 'SHOP'),
      MapNodeData(id: 'node_4', type: 'BATTLE', enemyId: 'e_fire_mage'),
      MapNodeData(id: 'node_5', type: 'SHOP'),
      MapNodeData(id: 'node_6', type: 'BOSS', enemyId: 'e_golem'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DUNGEON MAP - FLOOR ${playerRun.currentFloor}',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFC5A059),
        automaticallyImplyLeading: false,
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141414), Color(0xFF0F0F0F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              itemCount: horizontalMapNodes.length,
              itemBuilder: (context, index) {
                final node = horizontalMapNodes[index];
                
                final bool isCurrentNode = index == (playerRun.currentFloor - 1);
                final bool isCompleted = index < (playerRun.currentFloor - 1);
                final bool isLocked = index > (playerRun.currentFloor - 1);

                return Row(
                  children: [
                    _buildMapNodeButton(
                      context,
                      node: node,
                      isCurrent: isCurrentNode,
                      isCompleted: isCompleted,
                      isLocked: isLocked,
                      localization: localization,
                      screenSize: screenSize, // Oper ukuran layar ke pembangun tombol
                    ),
                    if (index < horizontalMapNodes.length - 1)
                      Container(
                        width: 80,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFFC5A059) : Colors.white10,
                          boxShadow: isCompleted
                              ? [const BoxShadow(color: Color(0xFFC5A059), blurRadius: 4)]
                              : null,
                        ),
                      ),
                  ],
                );
              },
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
    required Size screenSize, // Terima parameter ukuran layar
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
      borderColor = const Color(0x80C5A059); // 0x80 adalah setara dengan 0.5 opacity (50% dari 255 = 128)
      nodeColor = Colors.black45;
    }

    return GestureDetector(
      onTap: isCurrent 
          ? () => _handleNodeTap(context, node, localization, screenSize) // Kirim screenSize asli ke handler klik
          : null,
      child: Opacity(
        opacity: isLocked ? 0.35 : 1.0,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: nodeColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: isCurrent ? 4 : 2),
            boxShadow: isCurrent
                ? [
                    const BoxShadow(
                      color: Color(0xFFC5A059),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Icon(
            nodeIcon,
            color: isCurrent ? const Color(0xFFC5A059) : (isCompleted ? Colors.white54 : Colors.white24),
            size: node.type == 'BOSS' ? 38 : 30,
          ),
        ),
      ),
    );
  }

  /// Mengatur logika navigasi ketika node tujuan aktif diklik oleh pemain
  void _handleNodeTap(BuildContext context, MapNodeData node, AppLocalizations localization, Size screenSize) {
    if (node.type == 'BATTLE' || node.type == 'BOSS') {
      final enemyMeta = localization.getEnemyMetadata(node.enemyId);
      
      if (enemyMeta == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Profil musuh ${node.enemyId} gagal ditemukan!')),
        );
        return;
      }

      final playerRun = Provider.of<PlayerRun>(context, listen: false);
      final boardState = Provider.of<BoardState>(context, listen: false);

      // FIXED: Masukkan screenSize ke parameter inisialisasi agar kartu meluncur presisi sejak awal match
      boardState.initializeBattle(
        playerRun: playerRun,
        enemyMeta: enemyMeta,
        allCards: localization.allCardsMetadata
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masuk ke arena pertempuran melawan: ${enemyMeta.name}!')),
      );
      
      Navigator.pushNamed(context, GameplayScreen.routeName);
      
    } else if (node.type == 'SHOP') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membuka area merchant Toko Emas...')),
      );
    }
  }
}