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
    appearingCardIds.clear();
    disappearingCardIds.clear();
    isAnimating = false;
    isPlayerTurn = true;
    isBattleCalculated = false;
    battleLog = "Lawan baru muncul: ${enemy.name}! Bersiaplah!";

    // Picu draw bergiliran di awal pertandingan
    triggerDrawSequence(initialDrawCount);
    notifyListeners();
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
    if (enemy.deck.isEmpty && enemy.discardPile.isEmpty) return;
    if (enemy.hand.isEmpty) enemy.drawCards(1);

    enemyCardOnTable = enemy.hand.removeLast();
    battleLog = "Musuh mengeluarkan kartu tandingan! Mengalkulasi hasil...";
    isBattleCalculated = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      _calculateBattleResolution();
    });
  }

  /// 6. RESOLUSI PERTEMPURAN
  void _calculateBattleResolution() async {
    if (playerCardOnTable == null || enemyCardOnTable == null) return;

    final result = playerCardOnTable!.beats(enemyCardOnTable!);
    int pDamage = _cardDataRepository[playerCardOnTable!.id]?.power ?? 20;
    int eDamage = _cardDataRepository[enemyCardOnTable!.id]?.power ?? 20;

    if (result == BattleResult.win) {
      if (player.hasDamageDebuff) {
        final debuff = player.activeEffects.firstWhere((e) => e.type == EffectType.damageReduce);
        pDamage = (pDamage * (1 - debuff.value)).round();
      }
      enemy.takeDamage(pDamage);
      battleLog = "Kamu MENANG! Kartu ID ${playerCardOnTable!.id} memberikan $pDamage damage.";
    } else if (result == BattleResult.lose) {
      if (enemy.hasDamageDebuff) {
        final debuff = enemy.activeEffects.firstWhere((e) => e.type == EffectType.damageReduce);
        eDamage = (eDamage * (1 - debuff.value)).round();
      }
      player.takeDamage(eDamage);
      battleLog = "Kamu KALAH! Menelan hantaman sebesar $eDamage damage.";
    } else {
      battleLog = "Hasil SERI! Kedua kartu hancur di meja arena.";
    }

    // Kartu meja langsung masuk pembuangan
    player.discardPile.add(playerCardOnTable!);
    enemy.discardPile.add(enemyCardOnTable!);

    player.updateEffectsTick();
    enemy.updateEffectsTick();

    if (player.isDead || enemy.isDead) {
      _endMatchProgress();
    } else {
      // ==========================================
      // MANAJEMEN HAND BERGILIRAN (FIXED NO BUG 6 CARD)
      // ==========================================
      if (discardAllAfterTurn) {
        // Panggil fungsi sekuens pembuangan bergiliran yang baru dan TUNGGU (await) sampai bersih total
        await triggerDiscardSequence();
      }

      isBattleCalculated = false;
      playerCardOnTable = null;
      enemyCardOnTable = null;
      notifyListeners();

      // Isi kembali kartu untuk turn berikutnya secara bergiliran
      triggerDrawSequence(turnDrawCount);
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