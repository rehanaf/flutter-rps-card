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
  String? _lastCompletedNodeId;       // ID Node terakhir yang berhasil diselesaikan
  String? selectedNodeId;             // ID Node aktif yang sedang ditantang bertarung

  // --- MASTER DECK (KOLEKSI KARTU SEPANJANG PETUALANGAN) ---
  // Seluruh kartu yang dimiliki pemain (Dari hadiah musuh atau beli di Shop Area)
  final List<PlayingCard> _masterDeck = [];

  // --- SLOT RAMUAN SEKALI PAKAI (CONSUMABLE SLOTS, MAKS 2) ---
  final List<String> _consumableSlots = [];

  // --- GETTER & SETTER ---
  int get currentHp => _currentHp;
  int get maxHp => _maxHp;
  int get gold => _gold;
  int get currentFloor => _currentFloor;
  List<String> get completedNodeIds => _completedNodeIds;
  String? get lastCompletedNodeId => _lastCompletedNodeId;
  List<PlayingCard> get masterDeck => _masterDeck;
  List<String> get consumableSlots => _consumableSlots;

  // Starter deck bawaan: hanya 3 kartu untuk petualangan yang seimbang di awal
  static const List<String> defaultStarterCardIds = ['10', '18', '61'];

  /// 1. INISIALISASI PETUALANGAN BARU (RESET NEW RUN)
  /// Fungsi ini dipanggil saat pemain menekan "Play" di Main Menu
  void startNewRun([List<String>? starterCardIds]) {
    _currentHp = 80;
    _maxHp = 80;
    _gold = 100;
    _currentFloor = 1;
    _completedNodeIds.clear();
    _lastCompletedNodeId = null;
    selectedNodeId = null;
    _consumableSlots.clear();
    
    // Isi Master Deck dengan starter pack kartu awal (atau fallback ke default)
    final cardsToUse = starterCardIds ?? defaultStarterCardIds;
    _masterDeck.clear();
    for (String id in cardsToUse) {
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

  void heal(int amount) {
    if (amount <= 0) return;
    _currentHp = (_currentHp + amount).clamp(0, _maxHp);
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
      _lastCompletedNodeId = nodeId;
      selectedNodeId = null;
      _currentFloor++; // Naik ke lantai berikutnya ala Slay the Spire
      notifyListeners();
    }
  }

  /// 5. MANAJEMEN SLOT RAMUAN SEKALI PAKAI (CONSUMABLES)
  
  bool addConsumable(String id) {
    if (_consumableSlots.length >= 2) return false;
    _consumableSlots.add(id);
    notifyListeners();
    return true;
  }

  void removeConsumableAt(int index) {
    if (index >= 0 && index < _consumableSlots.length) {
      _consumableSlots.removeAt(index);
      notifyListeners();
    }
  }
}