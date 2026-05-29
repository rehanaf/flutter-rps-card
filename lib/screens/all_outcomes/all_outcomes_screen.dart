import 'package:flutter/material.dart';
import '../../services/app_localizations.dart';

class AllOutcomesScreen extends StatefulWidget {
  static const String routeName = '/all_outcomes';

  const AllOutcomesScreen({super.key});

  @override
  State<AllOutcomesScreen> createState() => _AllOutcomesScreenState();
}

class _AllOutcomesScreenState extends State<AllOutcomesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _focusCardId = "1"; // Default: Dynamite (ID "1")
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Menghitung daftar ID kartu yang dikalahkan (wins) dan yang mengalahkan (losses) kartu fokus
  Map<String, List<String>> _calculateMatchups(String focusId) {
    final List<String> wins = [];
    final List<String> losses = [];
    final int focusInt = int.parse(focusId);

    for (int i = 1; i <= 101; i++) {
      if (i == focusInt) continue;
      final String opponentId = i.toString();

      // Rumus RPS 101: 
      // Jika selisih melingkar (opponent - focus) % 101 bernilai antara 1 sampai 50, maka focus menang (opponent kalah).
      // Sebaliknya jika bernilai 51 sampai 100, focus kalah (opponent menang).
      int diff = (i - focusInt) % 101;
      if (diff < 0) diff += 101;

      if (diff > 0 && diff <= 50) {
        // focus menang, opponent kalah
        wins.add(opponentId);
      } else {
        // focus kalah, opponent menang
        losses.add(opponentId);
      }
    }

    return {"wins": wins, "losses": losses};
  }

  String _buildClashSentence(
    AppLocalizations localization,
    String winnerId,
    String loserId,
  ) {
    final String winnerName = localization.getCardName(winnerId);
    final String loserName = localization.getCardName(loserId);

    final List<dynamic>? rawVerbArray = localization.getClashVerbArray(winnerId, loserId);

    if (rawVerbArray != null && rawVerbArray.isNotEmpty) {
      final List<String> verbArray = rawVerbArray.map((e) {
        String s = e.toString();
        s = s.replaceAll(r"\'", "'").replaceAll(r"\\'", "'").replaceAll(r"\", "");
        return s;
      }).toList();

      final String part1 = verbArray[0];
      if (verbArray.length == 1) {
        return "$winnerName $part1 $loserName";
      } else if (verbArray.length >= 2) {
        final String part2 = verbArray[1];
        if (part1.isEmpty) {
          return "$winnerName $loserName$part2";
        }

        final String middle = part1.endsWith('(') ? "$part1$loserName" : "$part1 $loserName";

        if (part2.isEmpty) {
          return "$winnerName $middle";
        } else if (part2.startsWith("'s") || part2 == ")") {
          return "$winnerName $middle$part2";
        } else {
          return "$winnerName $middle $part2";
        }
      }
    }

    if (localization.locale.languageCode == 'id') {
      return "$winnerName menang melawan $loserName";
    } else {
      return "$winnerName wins against $loserName";
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final Map<String, List<String>> matchups = _calculateMatchups(_focusCardId);
    final List<String> wins = matchups["wins"]!;
    final List<String> losses = matchups["losses"]!;

    // Ambil daftar seluruh kartu untuk keperluan pencarian / pemilihan kartu fokus
    final List<MapEntry<String, String>> allCards = [];
    for (int i = 1; i <= 101; i++) {
      final id = i.toString();
      allCards.add(MapEntry(id, localization.getCardName(id)));
    }

    // Filter daftar kartu berdasarkan query pencarian pemain
    final List<MapEntry<String, String>> filteredCards = allCards.where((entry) {
      final nameLower = entry.value.toLowerCase();
      final idLower = entry.key;
      final queryLower = _searchQuery.toLowerCase();
      return nameLower.contains(queryLower) || idLower.contains(queryLower);
    }).toList();

    final focusCardName = localization.getCardName(_focusCardId);
    final locale = localization.locale.languageCode;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Wallpaper Background dengan overlay gelap
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/main_menu.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF0F0F0F));
              },
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color(0xF20B0B0B)),
          ),

          // 2. Konten Utama
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER BAR (Judul & Tombol Kembali)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.compare_arrows_rounded,
                            color: Color(0xFFC5A059),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            localization.getUiText('allOutcomesButton').toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFC5A059),
                              fontSize: 22,
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

                  // KONTEN SPLIT: PILIH KARTU DI KIRI, TAB HASIL CLASH DI KANAN
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BAGIAN KIRI: PANEL SELEKTOR KARTU DENGAN SEARCH BAR
                        Container(
                          width: 250,
                          decoration: BoxDecoration(
                            color: const Color(0x1FFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x26C5A059)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search Input
                              TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: locale == 'id' ? 'Cari Kartu...' : 'Search Card...',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFC5A059), size: 18),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = "";
                                            });
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  fillColor: Colors.black26,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0x33C5A059)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFC5A059)),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              
                              // List Kartu
                              Expanded(
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filteredCards.length,
                                  itemBuilder: (context, index) {
                                    final cardEntry = filteredCards[index];
                                    final bool isFocus = cardEntry.key == _focusCardId;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          setState(() {
                                            _focusCardId = cardEntry.key;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isFocus ? const Color(0xFFC5A059) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isFocus ? const Color(0xFFC5A059) : const Color(0x0DFFFFFF),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: isFocus ? Colors.black26 : const Color(0x1AFFFFFF),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  "#${cardEntry.key}",
                                                  style: TextStyle(
                                                    color: isFocus ? Colors.white : const Color(0xFFC5A059),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  cardEntry.value,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: isFocus ? Colors.black : Colors.white70,
                                                    fontSize: 13,
                                                    fontWeight: isFocus ? FontWeight.w900 : FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // BAGIAN KANAN: PREVIEW CLASH RULES KARTU FOKUS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CARD FOCUS GLOWING BAR
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0x26C5A059), Color(0x03C5A059)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0x33C5A059), width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFC5A059),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        "#$_focusCardId",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          focusCardName.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Text(
                                          locale == 'id'
                                              ? "Menang melawan 50 kartu, kalah dari 50 kartu."
                                              : "Beats 50 cards, defeated by 50 cards.",
                                          style: const TextStyle(color: Colors.white30, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // TAB BAR UNTUK PILIHAN WINS VS LOSSES
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0x12FFFFFF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0x1FBAA067)),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  indicatorColor: const Color(0xFFC5A059),
                                  labelColor: const Color(0xFFC5A059),
                                  unselectedLabelColor: Colors.white60,
                                  indicatorWeight: 3,
                                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
                                  tabs: [
                                    Tab(
                                      text: locale == 'id'
                                          ? "MENANG MELAWAN (${wins.length})"
                                          : "WINS AGAINST (${wins.length})",
                                    ),
                                    Tab(
                                      text: locale == 'id'
                                          ? "KALAH MELAWAN (${losses.length})"
                                          : "DEFEATED BY (${losses.length})",
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // TAB VIEW
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    // 1. DAFTAR KEMENANGAN (WINS)
                                    _buildOutcomesList(wins, isWinningRule: true, localization: localization),
                                    
                                    // 2. DAFTAR KEKALAHAN (LOSSES)
                                    _buildOutcomesList(losses, isWinningRule: false, localization: localization),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildOutcomesList(
    List<String> opponents,
    {required bool isWinningRule,
    required AppLocalizations localization}
  ) {
    final themeColor = isWinningRule ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: opponents.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0x12FFFFFF), height: 12),
        itemBuilder: (context, index) {
          final String opponentId = opponents[index];

          // Susun kalimat kustom berdasarkan peranan pemenang & pecundang
          final String sentence = isWinningRule
              ? _buildClashSentence(localization, _focusCardId, opponentId)
              : _buildClashSentence(localization, opponentId, _focusCardId);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Simbol Badge Status Menang/Kalah
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: themeColor, width: 1),
                  ),
                  child: Text(
                    isWinningRule ? "WIN" : "LOSE",
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Penanda ID Opponent
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "#$opponentId",
                    style: const TextStyle(
                      color: Color(0xFFC5A059),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Kalimat Clash Lokal Kustom
                Expanded(
                  child: Text(
                    sentence,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
