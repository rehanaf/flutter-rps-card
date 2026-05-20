import 'package:flutter/material.dart';
import '../models/playing_card.dart';

class PlayerRun extends ChangeNotifier {
  // --- STATISTIK UTAMA PLAYER (PERMANEN SELAMA RUN) ---
  int _currentHp = 80;
  int _maxHp = 80;
  int _gold = 100; // Memulai petualangan dengan 100 Emas dasar

  // --- PROGRESS TRACKING PETUALANGAN ---
  int _currentFloor = 1;              // Lantai/Stage saat ini
  final List<String> _completedNodeIds = []; // Daftar ID Node Map yang sudah dilewati

  // --- MASTER DECK (KOLEKSI KARTU SEPANJANG PETUALANGAN) ---
  // Seluruh kartu yang dimiliki pemain (Dari hadiah musuh atau beli di Shop Area)
  final List<PlayingCard> _masterDeck = [];

  // --- GETTER & SETTER ---
  int get currentHp => _currentHp;
  int get maxHp => _maxHp;
  int get gold => _gold;
  int get currentFloor => _currentFloor;
  List<String> get completedNodeIds => _completedNodeIds;
  List<PlayingCard> get masterDeck => _masterDeck;

  /// 1. INISIALISASI PETUALANGAN BARU (RESET NEW RUN)
  /// Fungsi ini dipanggil saat pemain menekan "Play" di Main Menu
  void startNewRun(List<String> starterCardIds) {
    _currentHp = 80;
    _maxHp = 80;
    _gold = 100;
    _currentFloor = 1;
    _completedNodeIds.clear();
    
    // Isi Master Deck dengan starter pack kartu awal
    _masterDeck.clear();
    for (String id in starterCardIds) {
      _masterDeck.add(PlayingCard(id));
    }
    
    notifyListeners();
  }

  /// 2. MANAJEMEN STATISTIK (HP & GOLD)
  
  void updateHpAfterBattle(int remainingHp) {
    // Menyimpan sisa HP terakhir dari arena battle ke status permanen run
    _currentHp = remainingHp.clamp(0, _maxHp);
    notifyListeners();
  }

  void addGold(int amount) {
    if (amount <= 0) return;
    _gold += amount;
    notifyListeners();
  }

  /// Mengurangi gold untuk belanja di Shop. Mengembalikan [true] jika berhasil.
  bool spendGold(int amount) {
    if (_gold >= amount) {
      _gold -= amount;
      notifyListeners();
      return true;
    }
    return false; // Gold tidak cukup
  }

  /// 3. MANAJEMEN DECK UTAMA (TAMBAH / HAPUS KARTU PERMANEN)

  void addCardToMasterDeck(PlayingCard card) {
    _masterDeck.add(card);
    notifyListeners();
  }

  void removeCardFromMasterDeck(String cardId) {
    // Digunakan saat fitur "Hapus Kartu dari Deck" di Shop Area
    int index = _masterDeck.indexWhere((card) => card.id == cardId);
    if (index != -1) {
      _masterDeck.removeAt(index);
      notifyListeners();
    }
  }

  /// 4. MANAJEMEN PROGRES MAP PETUALANGAN

  void completeNode(String nodeId) {
    if (!_completedNodeIds.contains(nodeId)) {
      _completedNodeIds.add(nodeId);
      _currentFloor++; // Naik ke lantai berikutnya ala Slay the Spire
      notifyListeners();
    }
  }
}