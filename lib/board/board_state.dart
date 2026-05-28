import 'dart:async';
import 'package:flutter/material.dart';
import '../models/playing_card.dart';
import '../models/enemy_metadata.dart';
import '../models/status_effect.dart';
import 'player.dart';
import 'player_run.dart';
import '../behaviors/behavior_registry.dart';

class TurnOverlayData {
  final String title;
  final String description;
  final String eventType; // 'player_turn', 'enemy_turn', 'clash_win', 'clash_lose', 'clash_draw'
  final String? playerCardId;
  final String? enemyCardId;
  final int? turnNumber;

  TurnOverlayData({
    required this.title,
    required this.description,
    required this.eventType,
    this.playerCardId,
    this.enemyCardId,
    this.turnNumber,
  });
}

class BoardState extends ChangeNotifier {
  int currentTurn = 1;
  TurnOverlayData? activeOverlay;
  int? hoveredCardIndex;

  void setHoveredCardIndex(int? index) {
    if (hoveredCardIndex == index) return;
    hoveredCardIndex = index;
    notifyListeners();
  }

  void setDragOverTarget(bool isOver, PlayingCard? card, Size screenSize) {
    if (isDragOverTarget == isOver && previewPlayerCard == card) return;
    isDragOverTarget = isOver;
    if (isOver && card != null) {
      previewPlayerCard = card;
      final double cardWidth = screenSize.width * 0.1;
      cardX = screenSize.width * 0.40 - (cardWidth / 2);
      final double bodyHeight = screenSize.height;
      cardY = (bodyHeight / 2) - (cardWidth * 0.7);
    } else {
      previewPlayerCard = null;
    }
    notifyListeners();
  }

  List<String> gestureLogs = [];
  String activeGestureName = "IDLE";
  double? gestureX;
  double? gestureY;

  void updateActiveGesture(String name, {double? x, double? y}) {
    activeGestureName = name;
    gestureX = x;
    gestureY = y;
    notifyListeners();
  }

  void addGestureLog(String message) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${(now.millisecond ~/ 100)}";
    gestureLogs.insert(0, "[$timeStr] $message");
    if (gestureLogs.length > 8) {
      gestureLogs.removeLast();
    }
    notifyListeners();
  }

  void showOverlay({
    required String title,
    required String description,
    required String eventType,
    String? playerCardId,
    String? enemyCardId,
    int? turnNumber,
  }) {
    activeOverlay = TurnOverlayData(
      title: title,
      description: description,
      eventType: eventType,
      playerCardId: playerCardId,
      enemyCardId: enemyCardId,
      turnNumber: turnNumber,
    );
    notifyListeners();

    // Clear overlay after 1.8 seconds
    Future.delayed(const Duration(milliseconds: 1800), () {
      activeOverlay = null;
      notifyListeners();
    });
  }

  late Player player;
  late Player enemy;

  int initialDrawCount = 3;
  int turnDrawCount = 3;
  bool discardAllAfterTurn = true;

  PlayingCard? playerCardOnTable;
  PlayingCard? enemyCardOnTable;
  PlayingCard? nextEnemyCard;
  bool isEnemyCardRevealed = false;

  PlayingCard? previewPlayerCard;
  PlayingCard? draggingCard;
  bool isDragOverTarget = false;

  double cardX = 0;
  double cardY = 0;
  bool isAnimating = false;

  double enemyCardX = 0;
  double enemyCardY = 0;
  bool isEnemyAnimating = false;

  // ==========================================
  // STATE BARU: MANAJEMEN URUTAN MUNCUL/HILANG KARTU
  // ==========================================
  List<String> appearingCardIds = [];    // List ID kartu yang sedang dalam proses animasi muncul
  List<String> disappearingCardIds = []; // List ID kartu yang sedang dalam proses animasi hilang

  bool isPlayerTurn = true;
  bool isBattleCalculated = false;
  String battleLog = "Tarik kartu untuk memulai pertandingan!";
  Map<String, CardMetadata> _cardDataRepository = {};
  Map<String, int> playerSynergies = {};

  /// 1. INISIALISASI PERTEMPURAN
  void initializeBattle({
    required PlayerRun playerRun,
    required EnemyMetadata enemyMeta,
    required Map<String, CardMetadata> allCards,
  }) {
    _cardDataRepository = allCards;

    player = Player(name: "Player", isEnemy: false)
      ..hp = playerRun.currentHp
      ..maxHp = playerRun.maxHp;

    player.deck = List<PlayingCard>.from(playerRun.masterDeck);
    player.deck.shuffle();

    enemy = Player(name: enemyMeta.name, isEnemy: true)
      ..hp = enemyMeta.baseHp
      ..maxHp = enemyMeta.baseHp;

    _generateEnemyArchetypeDeck(enemyMeta, allCards);

    playerCardOnTable = null;
    enemyCardOnTable = null;
    nextEnemyCard = null;
    isEnemyCardRevealed = false;
    enemyCardX = 0;
    enemyCardY = 0;
    isEnemyAnimating = false;
    appearingCardIds.clear();
    disappearingCardIds.clear();
    previewPlayerCard = null;
    draggingCard = null;
    isDragOverTarget = false;
    gestureLogs.clear();
    playerSynergies.clear();
    for (var card in playerRun.masterDeck) {
      final meta = allCards[card.id];
      if (meta != null) {
        final syn = meta.synergy.toLowerCase();
        playerSynergies[syn] = (playerSynergies[syn] ?? 0) + 1;
      }
    }
    isAnimating = false;
    isPlayerTurn = true;
    isBattleCalculated = false;
    hoveredCardIndex = null;
    battleLog = "Lawan baru muncul: ${enemy.name}! Bersiaplah!";

    // Terapkan efek start turn di awal pertempuran
    applyStartTurnEffects(player);
    applyStartTurnEffects(enemy);

    // Picu draw bergiliran di awal pertandingan
    triggerDrawSequence(initialDrawCount);
    prepareEnemyNextCard();

    currentTurn = 1;
    showOverlay(
      title: "GILIRANMU",
      description: "Giliran 1",
      eventType: "player_turn",
      turnNumber: 1,
    );

    notifyListeners();
  }

  /// 1b. PERSIAPKAN AKSI BERIKUTNYA UNTUK MUSUH (INTENT SYSTEM)
  void prepareEnemyNextCard() {
    isEnemyCardRevealed = false;
    if (enemy.hand.isEmpty) {
      // Kocok ulang kuburan musuh jika dek utama kosong
      if (enemy.deck.isEmpty && enemy.discardPile.isNotEmpty) {
        enemy.deck.addAll(enemy.discardPile);
        enemy.discardPile.clear();
        enemy.deck.shuffle();
      }
      if (enemy.deck.isNotEmpty) {
        enemy.drawCards(1);
      }
    }
    if (enemy.hand.isNotEmpty) {
      nextEnemyCard = enemy.hand.removeLast();
    } else {
      nextEnemyCard = null;
    }
    notifyListeners();
  }

  /// Membelanjakan Emas untuk meneropong kartu musuh
  bool revealEnemyCard(PlayerRun playerRun) {
    if (isEnemyCardRevealed) return true;
    if (playerRun.spendGold(5)) {
      isEnemyCardRevealed = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Getters untuk petunjuk niat musuh
  String? get enemyIntentText {
    if (nextEnemyCard == null) return null;
    final cardId = nextEnemyCard!.id;
    final meta = _cardDataRepository[cardId];
    if (meta == null) return "Bersiap...";
    
    return meta.synergy;
  }

  IconData get enemyIntentSectorIcon {
    if (nextEnemyCard == null) return Icons.help_outline_rounded;
    final cardId = nextEnemyCard!.id;
    
    final int val = int.tryParse(cardId) ?? 0;
    if (val <= 33) {
      return Icons.arrow_downward_rounded;
    } else if (val <= 67) {
      return Icons.remove_rounded;
    } else {
      return Icons.arrow_upward_rounded;
    }
  }

  IconData get enemyIntentIcon {
    if (nextEnemyCard == null) return Icons.help_outline_rounded;
    final cardId = nextEnemyCard!.id;
    final meta = _cardDataRepository[cardId];
    if (meta == null) return Icons.help_outline_rounded;

    switch (meta.synergy.toLowerCase()) {
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

  Color get enemyIntentColor {
    if (nextEnemyCard == null) return const Color(0xFFC5A059);
    final cardId = nextEnemyCard!.id;
    final meta = _cardDataRepository[cardId];
    if (meta == null) return const Color(0xFFC5A059);

    switch (meta.synergy.toLowerCase()) {
      case 'fire': return const Color(0xFFFF4500);
      case 'liquid': return const Color(0xFF1E90FF);
      case 'nature': return const Color(0xFF8B4513);
      case 'air': return const Color(0xFF87CEEB);
      case 'robot': return const Color(0xFF9DA5A8);
      case 'cosmic': return const Color(0xFF9370DB);
      case 'energy': return const Color(0xFFFFD700);
      case 'spirit': return const Color(0xFF00CED1);
      case 'dark': return const Color(0xFF4B0082);
      case 'ancient': return const Color(0xFFFFD700);
      case 'toxic': return const Color(0xFFADFF2F);
      default: return const Color(0xFFC5A059);
    }
  }

  void _generateEnemyArchetypeDeck(EnemyMetadata meta, Map<String, CardMetadata> allCards) {
    List<PlayingCard> matchingPool = [];
    List<PlayingCard> randomPool = [];
    allCards.forEach((id, card) {
      if (card.synergy.toLowerCase() == meta.archetype.toLowerCase()) {
        matchingPool.add(PlayingCard(id));
      } else {
        randomPool.add(PlayingCard(id));
      }
    });
    matchingPool.shuffle();
    randomPool.shuffle();
    for (int i = 0; i < meta.synergyCount; i++) {
      if (matchingPool.isNotEmpty) enemy.deck.add(matchingPool.removeLast());
    }
    for (int i = 0; i < meta.randomCount; i++) {
      if (randomPool.isNotEmpty) enemy.deck.add(randomPool.removeLast());
    }
    enemy.deck.shuffle();
  }

  void playCardOnTable(PlayingCard card, double releaseX, double releaseY, Size screenSize) {
    if (!isPlayerTurn || playerCardOnTable != null) return;

    playerCardOnTable = card;
    final double cardWidth = screenSize.width * 0.1;
    
    // Set koordinat secara instan ke meja (karena sudah menempel rapi saat pratinjau)
    cardX = screenSize.width * 0.40 - (cardWidth / 2);
    final double bodyHeight = screenSize.height;
    cardY = (bodyHeight / 2) - (cardWidth * 0.7);
    isAnimating = false; // Tidak memerlukan animasi geser lagi

    player.hand.remove(card);
    
    // Apply Auto-Battler Synergy instantly
    _applySynergyBonus(card);
    
    notifyListeners();

    // Picu aksi giliran musuh secara instan karena kartu player tidak memerlukan animasi geser
    _executeEnemyAIAction(screenSize);
  }

  void _applySynergyBonus(PlayingCard card) {
    final meta = _cardDataRepository[card.id];
    if (meta == null) return;
    
    final synergy = meta.synergy.toLowerCase();
    final count = playerSynergies[synergy] ?? 0;
    String logMsg = "";

    final behavior = BehaviorRegistry.getSynergy(synergy);
    if (behavior != null) {
      logMsg = behavior.apply(player, enemy, count);
    }
    
    if (logMsg.isNotEmpty) {
      battleLog = "✨ [Sinergi ${meta.synergy}] $logMsg\n$battleLog";
    }
  }

  void onAnimationGlideComplete(Size screenSize) {
    if (!isAnimating) return;
    isAnimating = false;
    _executeEnemyAIAction(screenSize);
  }

  // ====================================================================
  // LOGIKA AMBIL & BUANG KARTU BERGILIRAN (SEQUENTIAL EFFECT)
  // ====================================================================

  /// Menarik kartu dari deck ke tangan secara bergiliran
  void triggerDrawSequence(int count) async {
    for (int i = 0; i < count; i++) {
      // FIXED 1: Cek dan kocok ulang kuburan kartu jika tumpukan dek utama kosong melompong
      if (player.deck.isEmpty) {
        checkAndReshuffleDeck();
      }

      if (player.deck.isNotEmpty) {
        final nextCard = player.deck.removeLast();
        
        // 1. Masukkan ke hand, tapi tandai ID-nya sedang "Appearing" (Opacity 0 di UI)
        appearingCardIds.add(nextCard.id);
        player.hand.add(nextCard);
        notifyListeners();

        // 2. Beri micro-delay lalu hapus dari list "Appearing" agar memicu efek transisi memudar muncul (Fade In)
        await Future.delayed(const Duration(milliseconds: 50));
        appearingCardIds.remove(nextCard.id);
        notifyListeners();

        // Jeda waktu jeda antar kartu sebelum kartu berikutnya muncul menyusul
        await Future.delayed(const Duration(milliseconds: 200));
      } else {
        // Jika setelah di-reshuffle deck tetap kosong (artinya semua kartu sudah di tangan/meja), 
        // hentikan paksa perulangan draw agar tidak membuang performa.
        break;
      }
    }
  }

  // FIXED 2: FUNGSI BARU UNTUK KONDISI RESHUFFLE DECK OTOMATIS ALA ROGUELIKE
  void checkAndReshuffleDeck() {
    if (player.discardPile.isNotEmpty) {
      // 1. Pindahkan seluruh isi kuburan kartu ke dek utama
      player.deck.addAll(player.discardPile);
      
      // 2. Bersihkan total penampung kuburan lamanya
      player.discardPile.clear();
      
      // 3. Kocok ulang tumpukan dek baru secara acak
      player.deck.shuffle();
      
      battleLog = "Dek kehabisan kartu! Mengocok ulang Discard Pile ke dalam Deck.";
      notifyListeners();
    }
  }

  /// Membuang seluruh sisa kartu di tangan ke Discard Pile secara bergiliran
  Future<void> triggerDiscardSequence() async {
    // Ambil duplikasi kartu tangan saat ini untuk dianimasikan keluar satu per satu
    final List<PlayingCard> cardsToDiscard = List<PlayingCard>.from(player.hand);

    for (final card in cardsToDiscard) {
      // 1. Tandai ID kartu masuk ke mode "Disappearing" (UI memicu transisi melorot ke bawah/hilang)
      disappearingCardIds.add(card.id);
      notifyListeners();

      // Tunggu durasi transisi visual meluncur selesai (240ms)
      await Future.delayed(const Duration(milliseconds: 240));

      // 2. Cabut permanen dari data hand asli dan pindahkan ke kuburan tumpukan discardPile
      player.hand.remove(card);
      disappearingCardIds.remove(card.id);
      player.discardPile.add(card);
      notifyListeners();

      // Jeda singkat sebelum kartu sisa di sebelahnya ikut menghilang
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _executeEnemyAIAction(Size screenSize) {
    if (nextEnemyCard == null) {
      prepareEnemyNextCard();
    }
    if (nextEnemyCard == null) return;

    // 1. Tampilkan overlay giliran musuh terlebih dahulu
    showOverlay(
      title: "GILIRAN MUSUH",
      description: "Musuh menyerang!",
      eventType: "enemy_turn",
    );

    // 2. Berikan jeda 1,2 detik agar overlay muncul terlebih dahulu baru kemudian kartu musuh muncul & meluncur
    Future.delayed(const Duration(milliseconds: 1200), () {
      final double cardWidth = screenSize.width * 0.1;
      enemyCardOnTable = nextEnemyCard;
      nextEnemyCard = null;
      battleLog = "Musuh mengeluarkan kartu tandingan! Mengalkulasi hasil...";
      isBattleCalculated = true;

      // Mulai animasi meluncur dari pojok kanan bawah (Y diatur ke 0.6 dari tinggi layar)
      enemyCardX = screenSize.width;
      enemyCardY = screenSize.height * 0.6;
      isEnemyAnimating = true;
      notifyListeners();

      // Luncurkan kartu ke meja tengah-kanan
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 30), () {
          enemyCardX = screenSize.width * 0.60 - (cardWidth / 2);
          
          // Posisi vertikal tengah-tengah body Scaffold
          final double bodyHeight = screenSize.height;
          enemyCardY = (bodyHeight / 2) - (cardWidth * 0.7);
          notifyListeners();
        });
      });

      // Tunggu durasi animasi meluncur selesai (1,2 detik) sebelum menghitung hasil pertempuran
      Future.delayed(const Duration(milliseconds: 1200), () {
        isEnemyAnimating = false;
        _calculateBattleResolution();
      });
    });
  }

  // ====================================================================
  // SIKLUS HIDUP STATUS EFFECT (TURN-BASED TRIGGERS)
  // ====================================================================

  void applyStartTurnEffects(Player activePlayer) {
    // Reset block riil dari turn sebelumnya terlebih dahulu (Block bertahan hanya 1 turn)
    activePlayer.shield = 0;

    // Cek 'shield': Jika ada, tambahkan block gratis sebesar nilai value.
    if (activePlayer.hasEffect(EffectType.shield)) {
      final shieldEffect = activePlayer.getEffect(EffectType.shield);
      activePlayer.shield += shieldEffect.value;
      activePlayer.removeEffect(EffectType.shield);
      battleLog += "\n🛡️ [Start Turn] ${activePlayer.name} mengubah Status Shield menjadi +${shieldEffect.value} Block riil.";
    }

    // Cek 'dot': Jika ada, kurangi HP langsung sebesar nilai value, lalu kurangi value sebesar 1. Jika value <= 0, hapus efek 'dot'.
    if (activePlayer.hasEffect(EffectType.dot)) {
      final dotEffect = activePlayer.getEffect(EffectType.dot);
      activePlayer.takeDamage(dotEffect.value);
      battleLog += "\n💧 [Start Turn] ${activePlayer.name} terkena DoT! Kehilangan ${dotEffect.value} HP.";
      dotEffect.value -= 1;
      if (dotEffect.value <= 0) {
        activePlayer.removeEffect(EffectType.dot);
        battleLog += " (Efek DoT telah habis)";
      }
    }
  }

  void applyEndTurnEffects(Player activePlayer) {
    // Kurangi value dari efek berdurasi seperti 'damageReduce' dan 'vulnerable' sebesar 1. Jika value <= 0, hapus efek tersebut dari list.
    if (activePlayer.hasEffect(EffectType.damageReduce)) {
      final weakenEffect = activePlayer.getEffect(EffectType.damageReduce);
      weakenEffect.value -= 1;
      if (weakenEffect.value <= 0) {
        activePlayer.removeEffect(EffectType.damageReduce);
        battleLog += "\n⏳ Efek Weaken pada ${activePlayer.name} telah berakhir.";
      }
    }

    if (activePlayer.hasEffect(EffectType.vulnerable)) {
      final vulnEffect = activePlayer.getEffect(EffectType.vulnerable);
      vulnEffect.value -= 1;
      if (vulnEffect.value <= 0) {
        activePlayer.removeEffect(EffectType.vulnerable);
        battleLog += "\n⏳ Efek Vulnerable pada ${activePlayer.name} telah berakhir.";
      }
    }
  }

  // ====================================================================
  // LOGIKA BATTLE RESOLUTION DENGAN VALUE SEBAGAI METRIC
  // ====================================================================

  /// 6. RESOLUSI PERTEMPURAN
  void _calculateBattleResolution() async {
    if (playerCardOnTable == null || enemyCardOnTable == null) return;

    final result = playerCardOnTable!.beats(enemyCardOnTable!);

    // --- PHASE 1: INSTANT ABILITY PHASE ---
    // Apply instant card abilities before damage calculations (efek aktif dulu)
    _applyCardAbilities(playerCardOnTable!, enemyCardOnTable!, result, isDelayed: false);
    
    // Pemicu Rebuild UI instan agar animasi transient efek instan langsung terlukis
    notifyListeners();
    
    // Jeda 1.5 detik agar animasi transient dari efek instan selesai dimunculkan
    await Future.delayed(const Duration(milliseconds: 1500));

    // --- PHASE 2: COMBAT DAMAGE CALCULATIONS ---
    // Hitung base damage kartu + bonus flat dari 'strength'
    int pDamage = _cardDataRepository[playerCardOnTable!.id]?.power ?? 20;
    if (player.hasEffect(EffectType.strength)) {
      pDamage += player.getEffect(EffectType.strength).value;
    }

    int eDamage = _cardDataRepository[enemyCardOnTable!.id]?.power ?? 20;
    if (enemy.hasEffect(EffectType.strength)) {
      eDamage += enemy.getEffect(EffectType.strength).value;
    }

    // Jika penyerang memiliki status 'damageReduce', potong total damage sebesar 25%
    if (player.hasEffect(EffectType.damageReduce)) {
      pDamage = (pDamage * 0.75).round();
    }
    if (enemy.hasEffect(EffectType.damageReduce)) {
      eDamage = (eDamage * 0.75).round();
    }

    // Jalankan pertempuran utama berdasarkan hasil RPS
    if (result == BattleResult.win) {
      battleLog = "Kamu MENANG! Kartu ID ${playerCardOnTable!.id} menyerang musuh.";
      _applyCombatDamage(player, enemy, pDamage);
      showOverlay(
        title: "KAMU MENANG!",
        description: "",
        eventType: "clash_win",
        playerCardId: playerCardOnTable!.id,
        enemyCardId: enemyCardOnTable!.id,
      );
    } else if (result == BattleResult.lose) {
      battleLog = "Kamu KALAH! Kartu musuh menerobos pertahananmu.";
      _applyCombatDamage(enemy, player, eDamage);
      showOverlay(
        title: "KAMU KALAH!",
        description: "",
        eventType: "clash_lose",
        playerCardId: playerCardOnTable!.id,
        enemyCardId: enemyCardOnTable!.id,
      );
    } else {
      battleLog = "Hasil SERI! Kedua kartu hancur di meja arena tanpa damage clash.";
      showOverlay(
        title: "HASIL SERI!",
        description: "",
        eventType: "clash_draw",
        playerCardId: playerCardOnTable!.id,
        enemyCardId: enemyCardOnTable!.id,
      );
    }

    // Jeda 1.5 detik agar animasi hit shake, get-hit flash, dan damage catch-up HP bar selesai terlukis
    await Future.delayed(const Duration(milliseconds: 1500));

    // --- PHASE 3: DELAYED ABILITY PHASE ---
    // Apply delayed card abilities after damage calculations (efek next turn)
    _applyCardAbilities(playerCardOnTable!, enemyCardOnTable!, result, isDelayed: true);

    // Pemicu Rebuild UI instan agar animasi transient efek delayed langsung terlukis
    notifyListeners();

    // Jeda 1.5 detik agar animasi transient dari efek delayed (next turn) selesai dimunculkan
    await Future.delayed(const Duration(milliseconds: 1500));

    // Kartu meja masuk pembuangan
    player.discardPile.add(playerCardOnTable!);
    enemy.discardPile.add(enemyCardOnTable!);

    // Jeda 1 detik singkat sebelum transisi giliran baru
    await Future.delayed(const Duration(milliseconds: 1000));

    // --- AKHIR GILIRAN: Jalankan End Turn Effects ---
    applyEndTurnEffects(player);
    applyEndTurnEffects(enemy);

    if (player.isDead || enemy.isDead) {
      _endMatchProgress();
    } else {
      // ==========================================
      // MANAJEMEN HAND BERGILIRAN
      // ==========================================
      if (discardAllAfterTurn) {
        await triggerDiscardSequence();
      }

      isBattleCalculated = false;
      playerCardOnTable = null;
      enemyCardOnTable = null;
      notifyListeners();

      // --- AWAL GILIRAN BARU: Jalankan Start Turn Effects ---
      applyStartTurnEffects(player);
      applyStartTurnEffects(enemy);

      // Increment turn and trigger overlay
      currentTurn++;
      showOverlay(
        title: "GILIRANMU",
        description: "Giliran $currentTurn",
        eventType: "player_turn",
        turnNumber: currentTurn,
      );

      // Isi kembali kartu untuk turn berikutnya
      triggerDrawSequence(turnDrawCount);
      prepareEnemyNextCard();
    }
  }

  void _applyCombatDamage(Player attacker, Player defender, int rawDamage) {
    int dmg = rawDamage;

    // --- LANGKAH C: Periksa 'immunity' pada target ---
    if (defender.hasEffect(EffectType.immunity)) {
      dmg = 0;
      final immEffect = defender.getEffect(EffectType.immunity);
      immEffect.value -= 1;
      if (immEffect.value <= 0) {
        defender.removeEffect(EffectType.immunity);
      }
      battleLog += "\n🛡️ ${defender.name} memiliki IMMUNITY! Kerusakan ditolak sepenuhnya (0 damage).";
      
      // Lompat langsung ke fase pemicuan counter
      _handleCounterStrike(attacker, defender, false);
      return;
    }

    // --- LANGKAH D: Periksa status 'vulnerable' pada target ---
    if (defender.hasEffect(EffectType.vulnerable)) {
      dmg = (dmg * 1.5).round();
      battleLog += "\n⚡ ${defender.name} terkena efek VULNERABLE! Menerima damage 50% lebih besar.";
    }

    // --- LANGKAH E: Aplikasikan final damage ke HP/Shield target ---
    int finalDamageToHp = dmg;
    int absorbed = 0;
    if (defender.shield > 0) {
      if (defender.shield >= finalDamageToHp) {
        defender.shield -= finalDamageToHp;
        absorbed = finalDamageToHp;
        finalDamageToHp = 0;
      } else {
        absorbed = defender.shield;
        finalDamageToHp -= defender.shield;
        defender.shield = 0;
      }
    }
    defender.takeDamage(finalDamageToHp);

    if (absorbed > 0) {
      battleLog += "\n🛡️ Block ${defender.name} menyerap $absorbed damage.";
    }
    if (finalDamageToHp > 0) {
      battleLog += "\n💥 ${defender.name} terkena $finalDamageToHp damage langsung.";
    } else if (dmg > 0 && finalDamageToHp == 0) {
      battleLog += "\n🛡️ Block menyerap seluruh serangan!";
    }

    // --- LANGKAH F (Counter Strike): Berikan damage balasan jika terpicu ---
    _handleCounterStrike(attacker, defender, dmg > 0);
  }

  void _handleCounterStrike(Player attacker, Player defender, bool damageEntered) {
    if (damageEntered && defender.hasEffect(EffectType.counter)) {
      final counterValue = defender.getEffect(EffectType.counter).value;
      int counterDmg = counterValue;

      int absorbed = 0;
      if (attacker.shield > 0) {
        if (attacker.shield >= counterDmg) {
          attacker.shield -= counterDmg;
          absorbed = counterDmg;
          counterDmg = 0;
        } else {
          absorbed = attacker.shield;
          counterDmg -= attacker.shield;
          attacker.shield = 0;
        }
      }
      attacker.takeDamage(counterDmg);

      battleLog += "\n⚡ ${defender.name} melakukan COUNTER STRIKE! Membalas $counterValue damage ke ${attacker.name}.";
      if (absorbed > 0) {
        battleLog += " (Block menyerap $absorbed)";
      }
      if (counterDmg > 0) {
        battleLog += " (${attacker.name} menerima $counterDmg damage langsung)";
      }
    }
  }

  // ====================================================================
  // PEMICUAN ABILITY KARTU BERDASARKAN BATTLE RESULT & PELUANG
  // ====================================================================

  void _applyCardAbilities(PlayingCard playerCard, PlayingCard enemyCard, BattleResult result, {required bool isDelayed}) {
    final pMeta = _cardDataRepository[playerCard.id];
    final eMeta = _cardDataRepository[enemyCard.id];

    if (pMeta != null) {
      if (result == BattleResult.win) {
        _applyEffects(pMeta.win, player, enemy, isWin: true, isDelayedPhase: isDelayed);
      } else if (result == BattleResult.lose) {
        _applyEffects(pMeta.lose, player, enemy, isWin: false, isDelayedPhase: isDelayed);
      }
    }
    if (eMeta != null) {
      if (result == BattleResult.lose) {
        _applyEffects(eMeta.win, enemy, player, isWin: true, isDelayedPhase: isDelayed);
      } else if (result == BattleResult.win) {
        _applyEffects(eMeta.lose, enemy, player, isWin: false, isDelayedPhase: isDelayed);
      }
    }
  }

  void _applyEffects(Map<String, int> effects, Player caster, Player target, {required bool isWin, required bool isDelayedPhase}) {
    if (effects.isEmpty) return;

    effects.forEach((effectKey, value) {
      if (value <= 0) return;

      String cleanEffectName = effectKey.toLowerCase();
      
      // Parse delay prefix at the beginning (e.g. delay_self_weaken)
      bool hasDelayPrefix = false;
      if (cleanEffectName.startsWith('delay_')) {
        hasDelayPrefix = true;
        cleanEffectName = cleanEffectName.substring(6);
      }
      
      Player effectiveCaster = caster;
      Player effectiveTarget = target;
      Player intendedRecipient = caster; // Default recipient for buffs
      bool hasTargetPrefix = false;

      // Handle self_ / enemy_ / target_ prefix
      if (cleanEffectName.startsWith('self_')) {
        hasTargetPrefix = true;
        cleanEffectName = cleanEffectName.substring(5);
        effectiveCaster = caster;
        effectiveTarget = caster;
        intendedRecipient = caster;
      } else if (cleanEffectName.startsWith('enemy_') || cleanEffectName.startsWith('target_')) {
        hasTargetPrefix = true;
        int prefixLen = cleanEffectName.startsWith('enemy_') ? 6 : 7;
        cleanEffectName = cleanEffectName.substring(prefixLen);
        effectiveCaster = target;
        effectiveTarget = target;
        intendedRecipient = target;
      }

      // Parse delay prefix again in case it was written as self_delay_weaken
      if (cleanEffectName.startsWith('delay_')) {
        hasDelayPrefix = true;
        cleanEffectName = cleanEffectName.substring(6);
        // Re-evaluate target prefix in case of delay_self_weaken
        if (cleanEffectName.startsWith('self_')) {
          hasTargetPrefix = true;
          cleanEffectName = cleanEffectName.substring(5);
          effectiveCaster = caster;
          effectiveTarget = caster;
          intendedRecipient = caster;
        } else if (cleanEffectName.startsWith('enemy_') || cleanEffectName.startsWith('target_')) {
          hasTargetPrefix = true;
          int prefixLen = cleanEffectName.startsWith('enemy_') ? 6 : 7;
          cleanEffectName = cleanEffectName.substring(prefixLen);
          effectiveCaster = target;
          effectiveTarget = target;
          intendedRecipient = target;
        }
      }

      if (!hasTargetPrefix) {
        // Default mapping based on effect type
        final isDebuff = cleanEffectName == 'dot' || 
                         cleanEffectName == 'weaken' || 
                         cleanEffectName == 'damagereduce' || 
                         cleanEffectName == 'vulnerable';
        intendedRecipient = isDebuff ? target : caster;
      }

      // Check if this effect timing matches the current phase
      if (hasDelayPrefix != isDelayedPhase) {
        return; // Skip this effect in the current phase
      }

      String displayEffect = cleanEffectName;
      final behavior = BehaviorRegistry.getEffect(cleanEffectName);

      if (behavior != null) {
        displayEffect = behavior.apply(effectiveCaster, effectiveTarget, value);
        // Append recipient name for buffs if prefix was used to override
        if (hasTargetPrefix) {
          final isBuff = cleanEffectName != 'dot' && 
                         cleanEffectName != 'weaken' && 
                         cleanEffectName != 'damagereduce' && 
                         cleanEffectName != 'vulnerable';
          if (isBuff) {
            displayEffect = "$displayEffect ke ${intendedRecipient.name}";
          }
        }
      } else {
        // Fallback for custom or unrecognized effects
        effectiveTarget.addEffect(StatusEffect(type: EffectType.vulnerable, value: value));
        displayEffect = "$cleanEffectName (+$value) ke ${effectiveTarget.name}";
      }

      final String actionStr = isWin ? "MENANG" : "KALAH";
      final String delayStr = isDelayedPhase ? " [Turn Depan]" : " [Instan]";
      battleLog += "\n✨ [Ability]$delayStr $actionStr: ${caster.name} memicu $displayEffect.";
    });
  }

  void _endMatchProgress() {
    if (enemy.isDead) {
      battleLog = "Selamat! Kamu berhasil mengalahkan ${enemy.name}!";
    } else if (player.isDead) {
      battleLog = "Kamu telah gugur di dalam dungeon...";
    }
    notifyListeners();
  }
}