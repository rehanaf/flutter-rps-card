import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/playing_card.dart';
import '../models/enemy_metadata.dart';
import '../models/status_effect.dart';
import 'player.dart';
import 'player_run.dart';

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
    cardX = releaseX;
    cardY = releaseY;
    isAnimating = true;
    final double cardWidth = screenSize.width * 0.1;
    player.hand.remove(card);
    
    // Apply Auto-Battler Synergy instantly
    _applySynergyBonus(card);
    
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 30), () {
        // FIXED: Dikurangi 45 piksel agar posisi kartu Player bergeser sedikit ke kiri
        cardX = screenSize.width * 0.40 - (cardWidth / 2);
        
        // Posisi vertikal tengah-tengah body Scaffold (dikurangi tinggi AppBar 56.0)
        final double bodyHeight = screenSize.height - 56.0;
        cardY = (bodyHeight / 2) - (cardWidth * 0.7);
        notifyListeners();
      });
    });
  }

  void _applySynergyBonus(PlayingCard card) {
    final meta = _cardDataRepository[card.id];
    if (meta == null) return;
    
    final synergy = meta.synergy.toLowerCase();
    final count = playerSynergies[synergy] ?? 0;
    String logMsg = "";

    switch (synergy) {
      case 'basic':
        if (count >= 12) {
          player.addEffect(StatusEffect(type: EffectType.counter, value: 8));
          player.addEffect(StatusEffect(type: EffectType.strength, value: 3));
          logMsg = "+8 Counter, +3 Strength";
        } else if (count >= 8) {
          player.addEffect(StatusEffect(type: EffectType.counter, value: 4));
          player.addEffect(StatusEffect(type: EffectType.strength, value: 1));
          logMsg = "+4 Counter, +1 Strength";
        } else if (count >= 4) {
          player.addEffect(StatusEffect(type: EffectType.counter, value: 2));
          logMsg = "+2 Counter";
        }
        break;
      case 'nature':
        if (count >= 9) {
          player.addEffect(StatusEffect(type: EffectType.heal, value: 10));
          logMsg = "+10 Heal";
        } else if (count >= 6) {
          player.addEffect(StatusEffect(type: EffectType.heal, value: 5));
          logMsg = "+5 Heal";
        } else if (count >= 3) {
          player.addEffect(StatusEffect(type: EffectType.heal, value: 2));
          logMsg = "+2 Heal";
        }
        break;
      case 'robot':
        if (count >= 9) { player.addEffect(StatusEffect(type: EffectType.shield, value: 15)); logMsg = "+15 Shield"; }
        else if (count >= 6) { player.addEffect(StatusEffect(type: EffectType.shield, value: 7)); logMsg = "+7 Shield"; }
        else if (count >= 3) { player.addEffect(StatusEffect(type: EffectType.shield, value: 3)); logMsg = "+3 Shield"; }
        break;
      case 'ancient':
        if (count >= 6) { player.addEffect(StatusEffect(type: EffectType.shield, value: 15)); logMsg = "+15 Shield"; }
        else if (count >= 4) { player.addEffect(StatusEffect(type: EffectType.shield, value: 8)); logMsg = "+8 Shield"; }
        else if (count >= 2) { player.addEffect(StatusEffect(type: EffectType.shield, value: 4)); logMsg = "+4 Shield"; }
        break;
      case 'spirit':
        if (count >= 9) {
          enemy.addEffect(StatusEffect(type: EffectType.damageReduce, value: 4));
          logMsg = "Weaken musuh (4 Turn)";
        } else if (count >= 6) {
          enemy.addEffect(StatusEffect(type: EffectType.damageReduce, value: 2));
          logMsg = "Weaken musuh (2 Turn)";
        } else if (count >= 3) {
          enemy.addEffect(StatusEffect(type: EffectType.damageReduce, value: 1));
          logMsg = "Weaken musuh (1 Turn)";
        }
        break;
      case 'fire':
        if (count >= 6) {
          enemy.addEffect(StatusEffect(type: EffectType.dot, value: 12));
          enemy.addEffect(StatusEffect(type: EffectType.vulnerable, value: 2));
          logMsg = "DoT 12, Vulnerable (2 Turn)";
        } else if (count >= 4) {
          enemy.addEffect(StatusEffect(type: EffectType.dot, value: 7));
          logMsg = "DoT 7";
        } else if (count >= 2) {
          enemy.addEffect(StatusEffect(type: EffectType.dot, value: 3));
          logMsg = "DoT 3";
        }
        break;
      case 'toxic':
        if (count >= 6) {
          enemy.addEffect(StatusEffect(type: EffectType.dot, value: 10));
          enemy.addEffect(StatusEffect(type: EffectType.damageReduce, value: 2));
          logMsg = "DoT 10, Weaken (2 Turn)";
        } else if (count >= 4) {
          enemy.addEffect(StatusEffect(type: EffectType.dot, value: 5));
          logMsg = "DoT 5";
        } else if (count >= 2) {
          enemy.addEffect(StatusEffect(type: EffectType.dot, value: 2));
          logMsg = "DoT 2";
        }
        break;
      case 'cosmic':
        if (count >= 5) {
          enemy.addEffect(StatusEffect(type: EffectType.vulnerable, value: 4));
          logMsg = "Vulnerable (4 Turn)";
        } else if (count >= 4) {
          enemy.addEffect(StatusEffect(type: EffectType.vulnerable, value: 2));
          logMsg = "Vulnerable (2 Turn)";
        } else if (count >= 2) {
          enemy.addEffect(StatusEffect(type: EffectType.vulnerable, value: 1));
          logMsg = "Vulnerable (1 Turn)";
        }
        break;
      case 'liquid':
        if (count >= 6) {
          player.addEffect(StatusEffect(type: EffectType.heal, value: 6));
          player.addEffect(StatusEffect(type: EffectType.shield, value: 6));
          logMsg = "+6 Heal, +6 Shield";
        } else if (count >= 4) {
          player.addEffect(StatusEffect(type: EffectType.heal, value: 3));
          player.addEffect(StatusEffect(type: EffectType.shield, value: 3));
          logMsg = "+3 Heal, +3 Shield";
        } else if (count >= 2) {
          player.addEffect(StatusEffect(type: EffectType.heal, value: 1));
          player.addEffect(StatusEffect(type: EffectType.shield, value: 1));
          logMsg = "+1 Heal, +1 Shield";
        }
        break;
      case 'energy':
        if (count >= 3) {
          player.addEffect(StatusEffect(type: EffectType.strength, value: 8));
          logMsg = "+8 Strength";
        } else if (count >= 2) {
          player.addEffect(StatusEffect(type: EffectType.strength, value: 3));
          logMsg = "+3 Strength";
        } else if (count >= 1) {
          player.addEffect(StatusEffect(type: EffectType.strength, value: 1));
          logMsg = "+1 Strength";
        }
        break;
      case 'air':
        double chance = 0.0;
        if (count >= 5) chance = 0.5;
        else if (count >= 4) chance = 0.3;
        else if (count >= 2) chance = 0.15;
        
        if (chance > 0 && Random().nextDouble() < chance) {
          player.addEffect(StatusEffect(type: EffectType.immunity, value: 1));
          logMsg = "Immunity (1 Turn)";
        }
        break;
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

      // Tunggu durasi transisi visual memudar selesai (250ms)
      await Future.delayed(const Duration(milliseconds: 250));

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
          
          // Posisi vertikal tengah-tengah body Scaffold (dikurangi tinggi AppBar 56.0)
          final double bodyHeight = screenSize.height - 56.0;
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

    // --- LANGKAH A: Hitung base damage kartu + bonus flat dari 'strength' ---
    int pDamage = _cardDataRepository[playerCardOnTable!.id]?.power ?? 20;
    if (player.hasEffect(EffectType.strength)) {
      pDamage += player.getEffect(EffectType.strength).value;
    }

    int eDamage = _cardDataRepository[enemyCardOnTable!.id]?.power ?? 20;
    if (enemy.hasEffect(EffectType.strength)) {
      eDamage += enemy.getEffect(EffectType.strength).value;
    }

    // --- LANGKAH B: Jika penyerang memiliki status 'damageReduce', potong total damage sebesar 25% ---
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

    // --- SUNTIKKAN CONDITIONAL ABILITY BERDASARKAN BATTLE RESULT ---
    _applyCardAbilities(playerCardOnTable!, enemyCardOnTable!, result);

    // Kartu meja masuk pembuangan
    player.discardPile.add(playerCardOnTable!);
    enemy.discardPile.add(enemyCardOnTable!);

    // Jeda 2 detik agar player bisa melihat hasil pertarungan dan kartu di meja sebelum berganti turn
    await Future.delayed(const Duration(milliseconds: 2000));

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

  void _applyCardAbilities(PlayingCard playerCard, PlayingCard enemyCard, BattleResult result) {
    final pMeta = _cardDataRepository[playerCard.id];
    final eMeta = _cardDataRepository[enemyCard.id];

    if (pMeta != null) {
      if (result == BattleResult.win) {
        _applyEffects(pMeta.win, player, enemy, isWin: true);
      } else if (result == BattleResult.lose) {
        _applyEffects(pMeta.lose, player, enemy, isWin: false);
      }
    }
    if (eMeta != null) {
      if (result == BattleResult.lose) {
        _applyEffects(eMeta.win, enemy, player, isWin: true);
      } else if (result == BattleResult.win) {
        _applyEffects(eMeta.lose, enemy, player, isWin: false);
      }
    }
  }

  void _applyEffects(Map<String, int> effects, Player caster, Player target, {required bool isWin}) {
    if (effects.isEmpty) return;

    effects.forEach((effectName, value) {
      if (value <= 0) return;

      String displayEffect = effectName;
      
      switch (effectName.toLowerCase()) {
        case 'strength':
          caster.addEffect(StatusEffect(type: EffectType.strength, value: value));
          displayEffect = "Strength (+$value)";
          break;
        case 'shield':
          caster.addEffect(StatusEffect(type: EffectType.shield, value: value));
          displayEffect = "Shield (+$value)";
          break;
        case 'counter':
          caster.addEffect(StatusEffect(type: EffectType.counter, value: value));
          displayEffect = "Counter (+$value)";
          break;
        case 'immunity':
          caster.addEffect(StatusEffect(type: EffectType.immunity, value: value));
          displayEffect = "Immunity (Kebal) selama $value turn";
          break;
        case 'heal':
          caster.hp = (caster.hp + value).clamp(0, caster.maxHp);
          displayEffect = "Heal (+$value HP)";
          break;
        case 'dot':
          target.addEffect(StatusEffect(type: EffectType.dot, value: value));
          displayEffect = "DoT (+$value) ke ${target.name}";
          break;
        case 'damagereduce':
        case 'weaken':
          target.addEffect(StatusEffect(type: EffectType.damageReduce, value: value));
          displayEffect = "Weaken selama $value turn ke ${target.name}";
          break;
        case 'vulnerable':
          target.addEffect(StatusEffect(type: EffectType.vulnerable, value: value));
          displayEffect = "Vulnerable selama $value turn ke ${target.name}";
          break;
        default:
          target.addEffect(StatusEffect(type: EffectType.vulnerable, value: value));
          displayEffect = "$effectName (+$value) ke ${target.name}";
          break;
      }

      final String actionStr = isWin ? "MENANG" : "KALAH";
      battleLog += "\n✨ [Ability] $actionStr: ${caster.name} memicu $displayEffect.";
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