import 'package:flutter/material.dart';
import '../../services/app_localizations.dart';

class HowToPlayScreen extends StatefulWidget {
  static const String routeName = '/how_to_play';

  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Wallpaper Background dengan overlay gelap
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/main_menu_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF0F0F0F));
              },
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color(0xEC0F0F0F)),
          ),

          // 2. Konten Utama
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Bar (Judul & Tombol Kembali)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFFC5A059),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            localization.getUiText('howToPlayButton').toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFC5A059),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Tombol Kembali
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0x80C5A059), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(
                          localization.getUiText('backButton').toUpperCase(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // TabBar Navigation
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x1AC5A059)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFFC5A059),
                      labelColor: const Color(0xFFC5A059),
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                      tabs: const [
                        Tab(text: "RPS-101 WHEEL"),
                        Tab(text: "ENEMY INTENT"),
                        Tab(text: "ABILITIES"),
                        Tab(text: "SYNERGIES"),
                        Tab(text: "DUNGEON RUN"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TabBar Views
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x261E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x33C5A059), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 5)),
                        ],
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildRuleTab(
                            title: "SISTEM RODA 101 ELEMEN",
                            subtitle: "Revolusi Gunting-Batu-Kertas Skala Raksasa",
                            icon: Icons.loop_rounded,
                            description:
                                "Game ini menggunakan roda melingkar yang terdiri dari 101 elemen unik (bernomor 1 sampai 101). Sistem pertarungan dihitung sebagai berikut:\n\n"
                                "• Kartu Anda MENANG jika selisih searah jarum jam antara kartu musuh dan kartu Anda berada di antara 1 sampai 50.\n"
                                "  Rumus: (ID_Musuh - ID_Anda) % 101 bernilai 1 s.d 50.\n"
                                "• Jika selisihnya berada di atas 50, maka kartu Anda KALAH.\n"
                                "• Jika angkanya sama, maka hasilnya SERI (Draw).\n\n"
                                "Contoh: Kartu Batu (ID: 10) menang melawan Gunting (ID: 18) karena (18 - 10) = 8 (berada di rentang 1-50).",
                          ),
                          _buildRuleTab(
                            title: "NIAT MUSUH & TEROPONG",
                            subtitle: "Gunakan Informasi Untuk Menyusun Taktik Sempurna",
                            icon: Icons.visibility_rounded,
                            description:
                                "Untuk menghilangkan tebak-tebakan buta keberuntungan, kami menyediakan Sistem Niat Musuh (Enemy Intent):\n\n"
                                "• Balon Niat di atas kepala musuh membocorkan tipe Sinergi Kartu (misal: Fire, Cosmic, Toxic) dan Sektor Roda RPS kartu tersebut (Low: 1-33, Mid: 34-67, High: 68-101) melalui bahasa visual (Ikon).\n"
                                "• Gunakan informasi ini untuk merencanakan serangan balik terbaik dari kartu tangan Anda.",
                          ),
                          _buildRuleTab(
                            title: "KEMAMPUAN KARTU & STATUS EFEK",
                            subtitle: "Kombinasi Sinergi Buff dan Debuff yang Mematikan",
                            icon: Icons.auto_awesome_rounded,
                            description:
                                "Setiap kartu memiliki efek taktis unik yang terpicu setelah bentrokan kartu diselesaikan:\n\n"
                                "• Buff (Efek Positif): Strength (+Damage permanen), Shield (Pemicu block penyerap damage), Counter (Damage balasan saat dipukul), Immunity (Kebal total).\n"
                                "• Debuff (Efek Negatif): DoT/Damage over Time (Menguras darah setiap turn), Weaken (Mengurangi damage serangan sebesar 25%), Vulnerable (Menerima damage masuk 50% lebih besar).\n"
                                "• Mitigasi Bentrokan: Beberapa kartu (misal: Counter Shield) tetap memberikan keuntungan luar biasa seperti +15 Shield saat Anda kalah dalam bentrokan!",
                          ),
                          _buildRuleTab(
                            title: "AUTO-BATTLER SYNERGY",
                            subtitle: "Bonus Pasif Berdasarkan Komposisi Deck",
                            icon: Icons.layers_rounded,
                            description:
                                "Sistem pertarungan menggunakan mekanik ala Auto-Battler di mana tipe sinergi dari Deck Anda akan memberikan buff pasif yang kuat!\n\n"
                                "• Setiap kali Anda melempar kartu (Play Card), sistem mengecek komposisi elemen di dalam Master Deck Anda.\n"
                                "• Jika jumlah kartu dari elemen tersebut mencapai batas tier tertentu (contoh: [4], [8], [12] untuk Basic), maka efek pasif akan otomatis terpicu secara instan!\n"
                                "• Ini berarti Anda bisa memicu efek menyembuhkan diri (+Heal), mendapat +Shield, melukai musuh (DoT), dsb HANYA dengan melempar kartu, tanpa peduli hasil akhir Gunting-Batu-Kertas!\n\n"
                                "Pilih jalur Peta yang tepat dan bangun Deck dengan 1-3 sinergi yang dominan agar level buff Anda meroket!",
                          ),
                          _buildRuleTab(
                            title: "PETA, TOKO, & PROGRES DUNGEON",
                            subtitle: "Deckbuilding Roguelike yang Menantang",
                            icon: Icons.map_rounded,
                            description:
                                "Lalui petualangan bawah tanah Anda dengan taktis:\n\n"
                                "• Pilihlah node di Peta Petualangan secara cerdas. Kalahkan musuh untuk mengumpulkan koin emas dan draf hadiah kartu baru.\n"
                                "• Kunjungi Shop (Toko) untuk membeli ramuan kesehatan (Heal Potion), ramuan perisai (Shield Potion), adrenalin penarik kartu, batu pengasah kekuatan, atau labu racun.\n"
                                "• Gunakan ramuan dengan menyeretnya ke arena pertempuran tengah saat dibutuhkan.\n"
                                "• Susun dek terkuat dan bersiaplah menghadapi Boss di ujung dungeon!",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required String description,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFC5A059), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFC5A059),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0x33C5A059), height: 24, thickness: 1.5),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
