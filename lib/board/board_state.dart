import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/playing_card.dart';
import '../models/enemy_metadata.dart';
import '../models/status_effect.dart';
import 'player.dart';
import 'player_run.dart';

class BoardState extends ChangeNotifier {
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

  // ==========================================
  // STATE BARU: MANAJEMEN URUTAN MUNCUL/HILANG KARTU
  // ==========================================
  List<String> appearingCardIds = [];    // List ID kartu yang sedang dalam proses animasi muncul
  List<String> disappearingCardIds = []; // List ID kartu yang sedang dalam proses animasi hilang

  bool isPlayerTurn = true;
  bool isBattleCalculated = false;
  String battleLog = "Tarik kartu untuk memulai pertandingan!";
  Map<String, CardMetadata> _cardDataRepository = {};

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
    appearingCardIds.clear();
    disappearingCardIds.clear();
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
    
    final int val = int.tryParse(cardId) ?? 0;
    String sector = "";
    if (val <= 33) {
      sector = "Low (1-33)";
    } else if (val <= 67) {
      sector = "Mid (34-67)";
    } else {
      sector = "High (68-101)";
    }

    return "${meta.synergy} [Sector $sector]";
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
    final double cardWidth = screenSize.width * 0.13;
    player.hand.remove(card);
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 30), () {
        // FIXED: Dikurangi 45 piksel agar posisi kartu Player bergeser sedikit ke kiri
        cardX = screenSize.width * 0.40 - (cardWidth / 2);
        
        // Posisi vertikal tetap aman di bawah area tengah murni
        cardY = (screenSize.height / 2) - (cardWidth / 2);
        notifyListeners();
      });
    });
  }

  void onAnimationGlideComplete() {
    if (!isAnimating) return;
    isAnimating = false;
    _executeEnemyAIAction();
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

  void _executeEnemyAIAction() {
    if (nextEnemyCard == null) {
      prepareEnemyNextCard();
    }
    if (nextEnemyCard == null) return;

    enemyCardOnTable = nextEnemyCard;
    nextEnemyCard = null;
    battleLog = "Musuh mengeluarkan kartu tandingan! Mengalkulasi hasil...";
    isBattleCalculated = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      _calculateBattleResolution();
    });
  }

  // ====================================================================
  // SIKLUS HIDUP STATUS EFFECT (TURN-BASED TRIGGERS)
  // ====================================================================

  void applyStartTurnEffects(Player activePlayer) {
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
    } else if (result == BattleResult.lose) {
      battleLog = "Kamu KALAH! Kartu musuh menerobos pertahananmu.";
      _applyCombatDamage(enemy, player, eDamage);
    } else {
      battleLog = "Hasil SERI! Kedua kartu hancur di meja arena tanpa damage clash.";
    }

    // --- SUNTIKKAN CONDITIONAL ABILITY BERDASARKAN BATTLE RESULT ---
    _applyCardAbilities(playerCardOnTable!, enemyCardOnTable!, result);

    // Kartu meja masuk pembuangan
    player.discardPile.add(playerCardOnTable!);
    enemy.discardPile.add(enemyCardOnTable!);

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
      _executeAbility(pMeta.abilityId, player, enemy, result);
    }
    if (eMeta != null) {
      // Untuk musuh, hasilnya berlawanan
      BattleResult enemyResult = BattleResult.draw;
      if (result == BattleResult.win) enemyResult = BattleResult.lose;
      if (result == BattleResult.lose) enemyResult = BattleResult.win;
      _executeAbility(eMeta.abilityId, enemy, player, enemyResult);
    }
  }

  void _executeAbility(String abilityId, Player caster, Player target, BattleResult result) {
    switch (abilityId) {
      case "COUNTER_SHIELD":
        if (result == BattleResult.lose) {
          caster.addEffect(StatusEffect(type: EffectType.shield, value: 15));
          battleLog += "\n✨ [Ability] COUNTER_SHIELD: ${caster.name} kalah dan mendapatkan Status Shield (+15).";
        } else if (result == BattleResult.win) {
          caster.addEffect(StatusEffect(type: EffectType.strength, value: 4));
          battleLog += "\n✨ [Ability] COUNTER_SHIELD: ${caster.name} menang dan mendapatkan Strength (+4).";
        }
        break;
      case "EXPLODE":
        caster.addEffect(StatusEffect(type: EffectType.strength, value: 5));
        battleLog += "\n🔥 [Ability] EXPLODE: ${caster.name} memperoleh Strength (+5).";
        break;
      case "BLOCK":
      case "DEFEND":
      case "BARRIER":
        caster.addEffect(StatusEffect(type: EffectType.shield, value: 12));
        battleLog += "\n🛡️ [Ability] $abilityId: ${caster.name} bersiap bertahan dengan Status Shield (+12).";
        break;
      case "BURN":
      case "POISON":
        target.addEffect(StatusEffect(type: EffectType.dot, value: 6));
        battleLog += "\n🧪 [Ability] $abilityId: ${target.name} terinfeksi DoT (+6).";
        break;
      case "TRAP":
      case "BIND":
        target.addEffect(StatusEffect(type: EffectType.damageReduce, value: 2));
        battleLog += "\n🕸️ [Ability] $abilityId: Menurunkan damage output ${target.name} selama 2 turn.";
        break;
      case "GLOW":
      case "ORBIT":
        // Untuk sinergi Cosmic berbasis peluang 1/4 (25%) untuk memicu immunity
        if (Random().nextInt(4) == 0) {
          caster.addEffect(StatusEffect(type: EffectType.immunity, value: 1));
          battleLog += "\n🌌 [Ability] $abilityId: ${caster.name} memicu IMMUNITY (Kebal) selama 1 turn!";
        } else {
          battleLog += "\n🌌 [Ability] $abilityId: Gagal memicu Immunity (Peluang 25%).";
        }
        break;
      case "BLEED":
      case "STRIKE":
        target.addEffect(StatusEffect(type: EffectType.vulnerable, value: 2));
        battleLog += "\n🩸 [Ability] $abilityId: ${target.name} terkena status Vulnerable selama 2 turn.";
        break;
      case "CALCULATE":
      case "COMPUTE":
        caster.addEffect(StatusEffect(type: EffectType.counter, value: 8));
        battleLog += "\n⚡ [Ability] $abilityId: ${caster.name} bersiap membalas musuh dengan Status Counter (+8).";
        break;
    }
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