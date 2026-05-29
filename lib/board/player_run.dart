import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playing_card.dart';
import '../models/map_node_data.dart';

class PlayerRun extends ChangeNotifier {
  // --- STATE PERSISTENSI PETUALANGAN ---
  bool _hasActiveRun = false;
  bool _inBattle = false; // Flag apakah sedang dalam sesi pertempuran aktif

  // --- STATISTIK UTAMA PLAYER (PERMANEN SELAMA RUN) ---
  int _currentHp = 80;
  int _maxHp = 80;
  int _gold = 100; // Memulai petualangan dengan 100 Emas dasar

  // --- PROGRESS TRACKING PETUALANGAN ---
  int _currentFloor = 1;              // Lantai/Stage saat ini
  final List<String> _completedNodeIds = []; // Daftar ID Node Map yang sudah dilewati
  String? _lastCompletedNodeId;       // ID Node terakhir yang berhasil diselesaikan
  String? selectedNodeId;             // ID Node aktif yang sedang ditantang bertarung

  // --- PROCEDURAL GENERATED MAP NODES ---
  final List<MapNodeData> _mapNodes = [];

  // --- MASTER DECK (KOLEKSI KARTU SEPANJANG PETUALANGAN) ---
  // Seluruh kartu yang dimiliki pemain (Dari hadiah musuh atau beli di Shop Area)
  final List<PlayingCard> _masterDeck = [];

  // --- SLOT RAMUAN SEKALI PAKAI (CONSUMABLE SLOTS, MAKS 2) ---
  final List<String> _consumableSlots = [];

  // --- GETTER & SETTER ---
  bool get hasActiveRun => _hasActiveRun && _currentHp > 0 && _currentFloor <= 6;
  bool get inBattle => _inBattle && hasActiveRun; // Hanya true jika run sedang berjalan aktif
  int get currentHp => _currentHp;
  int get maxHp => _maxHp;
  int get gold => _gold;
  int get currentFloor => _currentFloor;
  List<String> get completedNodeIds => _completedNodeIds;
  String? get lastCompletedNodeId => _lastCompletedNodeId;
  List<PlayingCard> get masterDeck => _masterDeck;
  List<String> get consumableSlots => _consumableSlots;
  List<MapNodeData> get mapNodes => _mapNodes;

  set inBattle(bool value) {
    if (_inBattle != value) {
      _inBattle = value;
      notifyListeners();
      _saveToPrefs();
    }
  }

  // Starter deck bawaan: hanya 3 kartu untuk petualangan yang seimbang di awal
  static const List<String> defaultStarterCardIds = ['10', '18', '61'];

  // Pool Musuh Regular untuk Procedural Random Map
  static const List<String> regularEnemyPool = [
    'e_toxic_wizard',
    'e_robot_crow',
    'e_air_assasin',
    'e_fire_golem',
    'e_ancient_warrior',
    'e_cosmic_assasin',
    'e_dark_vampire',
    'e_energy_wizard',
    'e_liquid_wizard',
    'e_nature_wolf',
    'e_spirit_demon',
  ];

  /// --- 0. FUNGSI UNTUK PERSISTENSI DATA ---

  /// Memuat data petualangan yang tersimpan dari SharedPreferences
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasActiveRun = prefs.getBool('has_active_run') ?? false;
      _inBattle = prefs.getBool('in_battle') ?? false;
      
      if (_hasActiveRun) {
        _currentHp = prefs.getInt('current_hp') ?? 80;
        _maxHp = prefs.getInt('max_hp') ?? 80;
        _gold = prefs.getInt('gold') ?? 100;
        _currentFloor = prefs.getInt('current_floor') ?? 1;
        
        _completedNodeIds.clear();
        _completedNodeIds.addAll(prefs.getStringList('completed_node_ids') ?? []);
        
        _lastCompletedNodeId = prefs.getString('last_completed_node_id');
        selectedNodeId = prefs.getString('selected_node_id');
        
        final deckIds = prefs.getStringList('master_deck') ?? defaultStarterCardIds;
        _masterDeck.clear();
        for (String id in deckIds) {
          _masterDeck.add(PlayingCard(id));
        }
        
        _consumableSlots.clear();
        _consumableSlots.addAll(prefs.getStringList('consumable_slots') ?? []);

        // Muat peta prosedural yang tersimpan
        final mapJsonList = prefs.getStringList('map_nodes');
        _mapNodes.clear();
        if (mapJsonList != null && mapJsonList.isNotEmpty) {
          for (String nodeStr in mapJsonList) {
            _mapNodes.add(MapNodeData.fromJson(json.decode(nodeStr) as Map<String, dynamic>));
          }
        } else {
          _generateRandomMap();
        }
      } else {
        // Reset ke default jika tidak ada sesi permainan yang aktif
        _resetToDefaults();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading player run from SharedPreferences: $e');
    }
  }

  /// Reset semua properti ke nilai awal secara lokal
  void _resetToDefaults() {
    _hasActiveRun = false;
    _inBattle = false;
    _currentHp = 80;
    _maxHp = 80;
    _gold = 100;
    _currentFloor = 1;
    _completedNodeIds.clear();
    _lastCompletedNodeId = null;
    selectedNodeId = null;
    _consumableSlots.clear();
    _masterDeck.clear();
    for (String id in defaultStarterCardIds) {
      _masterDeck.add(PlayingCard(id));
    }
    _mapNodes.clear();
  }

  /// Membuat Bentuk & Koneksi Peta Petualangan Prosedural Secara Acak (3 Starting Paths)
  void _generateRandomMap() {
    final rand = Random();
    _mapNodes.clear();
    
    String getRandomEnemy() {
      return regularEnemyPool[rand.nextInt(regularEnemyPool.length)];
    }
    
    List<MapNodeData> prevFloorNodes = [];
    
    // Lantai 1 (Starter - SELALU 3 JALUR!)
    final List<MapNodeData> floor1 = [
      MapNodeData(
        id: 'node_1_1',
        type: 'BATTLE',
        enemyId: getRandomEnemy(),
        floor: 1,
        x: 60,
        y: 60,
        parentIds: [],
      ),
      MapNodeData(
        id: 'node_1_2',
        type: 'BATTLE',
        enemyId: getRandomEnemy(),
        floor: 1,
        x: 60,
        y: 150,
        parentIds: [],
      ),
      MapNodeData(
        id: 'node_1_3',
        type: 'BATTLE',
        enemyId: getRandomEnemy(),
        floor: 1,
        x: 60,
        y: 240,
        parentIds: [],
      ),
    ];
    _mapNodes.addAll(floor1);
    prevFloorNodes = floor1;
    
    // Lantai 2 sampai 5 (Acak Bentuk & Koneksi Bercabang)
    for (int f = 2; f <= 5; f++) {
      final double xPos = 60.0 + (f - 1) * 120.0;
      final List<MapNodeData> currentFloorNodes = [];
      
      // Tentukan acak jumlah node di lantai ini (2 atau 3 node)
      final int numNodes = rand.nextBool() ? 3 : 2;
      
      if (numNodes == 3) {
        final ys = [60.0, 150.0, 240.0];
        for (int i = 0; i < 3; i++) {
          final String nodeId = 'node_${f}_${i + 1}';
          
          // Lantai 5 adalah SHOP untuk persiapan akhir.
          // Lantai 3-4 berkesempatan 25% menjadi SHOP.
          String nodeType = 'BATTLE';
          if (f == 5) {
            nodeType = 'SHOP';
          } else if ((f == 3 || f == 4) && rand.nextDouble() < 0.25) {
            nodeType = 'SHOP';
          }
          
          final List<String> parents = [];
          if (prevFloorNodes.length == 3) {
            // Lantai sebelumnya memiliki 3 node: hubungkan dengan index yang sama
            parents.add(prevFloorNodes[i].id);
            // Kemungkinan 30% ditambahkan koneksi silang ke node tetangga
            if (i > 0 && rand.nextDouble() < 0.3) parents.add(prevFloorNodes[i - 1].id);
            if (i < 2 && rand.nextDouble() < 0.3) parents.add(prevFloorNodes[i + 1].id);
          } else {
            // Lantai sebelumnya memiliki 2 node (di y: 90, 210)
            if (i == 0) {
              parents.add(prevFloorNodes[0].id);
            } else if (i == 1) {
              parents.add(prevFloorNodes[0].id);
              if (rand.nextBool()) parents.add(prevFloorNodes[1].id);
            } else {
              parents.add(prevFloorNodes[1].id);
            }
          }
          
          currentFloorNodes.add(MapNodeData(
            id: nodeId,
            type: nodeType,
            enemyId: nodeType == 'BATTLE' ? getRandomEnemy() : '',
            floor: f,
            x: xPos,
            y: ys[i],
            parentIds: parents,
          ));
        }
      } else {
        // Membuat 2 node di y: 90, 210
        final ys = [90.0, 210.0];
        for (int i = 0; i < 2; i++) {
          final String nodeId = 'node_${f}_${i + 1}';
          
          String nodeType = 'BATTLE';
          if (f == 5) {
            nodeType = 'SHOP';
          } else if ((f == 3 || f == 4) && rand.nextDouble() < 0.25) {
            nodeType = 'SHOP';
          }
          
          final List<String> parents = [];
          if (prevFloorNodes.length == 3) {
            // Lantai sebelumnya memiliki 3 node (y: 60, 150, 240)
            if (i == 0) {
              parents.add(prevFloorNodes[0].id);
              parents.add(prevFloorNodes[1].id);
            } else {
              parents.add(prevFloorNodes[1].id);
              parents.add(prevFloorNodes[2].id);
            }
          } else {
            // Lantai sebelumnya memiliki 2 node: hubungkan dengan index yang sama
            parents.add(prevFloorNodes[i].id);
            // Kemungkinan 40% ditambahkan silang
            if (rand.nextDouble() < 0.4) {
              parents.add(prevFloorNodes[1 - i].id);
            }
          }
          
          currentFloorNodes.add(MapNodeData(
            id: nodeId,
            type: nodeType,
            enemyId: nodeType == 'BATTLE' ? getRandomEnemy() : '',
            floor: f,
            x: xPos,
            y: ys[i],
            parentIds: parents,
          ));
        }
      }
      
      _mapNodes.addAll(currentFloorNodes);
      prevFloorNodes = currentFloorNodes;
    }
    
    // Lantai 6 (BOSS - menggabungkan semua jalur Floor 5)
    final List<String> bossParents = prevFloorNodes.map((n) => n.id).toList();
    _mapNodes.add(MapNodeData(
      id: 'node_6',
      type: 'BOSS',
      enemyId: 'e_boss_skeleton',
      floor: 6,
      x: 660,
      y: 150,
      parentIds: bossParents,
    ));
  }

  /// Menyimpan status petualangan aktif secara asinkron (fire-and-forget)
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_active_run', _hasActiveRun);
      await prefs.setBool('in_battle', _inBattle);
      
      if (_hasActiveRun) {
        await prefs.setInt('current_hp', _currentHp);
        await prefs.setInt('max_hp', _maxHp);
        await prefs.setInt('gold', _gold);
        await prefs.setInt('current_floor', _currentFloor);
        await prefs.setStringList('completed_node_ids', _completedNodeIds);
        
        if (_lastCompletedNodeId != null) {
          await prefs.setString('last_completed_node_id', _lastCompletedNodeId!);
        } else {
          await prefs.remove('last_completed_node_id');
        }
        
        if (selectedNodeId != null) {
          await prefs.setString('selected_node_id', selectedNodeId!);
        } else {
          await prefs.remove('selected_node_id');
        }
        
        final deckIds = _masterDeck.map((card) => card.id).toList();
        await prefs.setStringList('master_deck', deckIds);
        await prefs.setStringList('consumable_slots', _consumableSlots);

        // Simpan peta prosedural
        final mapJsonList = _mapNodes.map((node) => json.encode(node.toJson())).toList();
        await prefs.setStringList('map_nodes', mapJsonList);
      }
    } catch (e) {
      debugPrint('Error saving player run to SharedPreferences: $e');
    }
  }

  /// Menghapus seluruh data progres permainan secara permanen
  Future<void> deleteSaveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_active_run');
      await prefs.remove('in_battle');
      await prefs.remove('current_hp');
      await prefs.remove('max_hp');
      await prefs.remove('gold');
      await prefs.remove('current_floor');
      await prefs.remove('completed_node_ids');
      await prefs.remove('last_completed_node_id');
      await prefs.remove('selected_node_id');
      await prefs.remove('master_deck');
      await prefs.remove('consumable_slots');
      await prefs.remove('map_nodes');
      
      _resetToDefaults();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting save data: $e');
    }
  }

  /// 1. INISIALISASI PETUALANGAN BARU (RESET NEW RUN)
  /// Fungsi ini dipanggil saat pemain menekan "Play" di Main Menu
  void startNewRun([List<String>? starterCardIds]) {
    _hasActiveRun = true;
    _inBattle = false;
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

    // Generate peta prosedural baru yang acak (3 Jalur)
    _generateRandomMap();
    
    notifyListeners();
    _saveToPrefs();
  }

  /// 2. MANAJEMEN STATISTIK (HP & GOLD)
  
  void updateHpAfterBattle(int remainingHp) {
    // Menyimpan sisa HP terakhir dari arena battle ke status permanen run
    _currentHp = remainingHp.clamp(0, _maxHp);
    
    // Jika HP mencapai 0, petualangan selesai (gugur)
    if (_currentHp <= 0) {
      _hasActiveRun = false;
      _inBattle = false; // Gugur, battle selesai
    }
    
    notifyListeners();
    _saveToPrefs();
  }

  void heal(int amount) {
    if (amount <= 0) return;
    _currentHp = (_currentHp + amount).clamp(0, _maxHp);
    notifyListeners();
    _saveToPrefs();
  }

  void addGold(int amount) {
    if (amount <= 0) return;
    _gold += amount;
    notifyListeners();
    _saveToPrefs();
  }

  /// Mengurangi gold untuk belanja di Shop. Mengmengembalikan [true] jika berhasil.
  bool spendGold(int amount) {
    if (_gold >= amount) {
      _gold -= amount;
      notifyListeners();
      _saveToPrefs();
      return true;
    }
    return false; // Gold tidak cukup
  }

  /// 3. MANAJEMEN DECK UTAMA (TAMBAH / HAPUS KARTU PERMANEN)

  void addCardToMasterDeck(PlayingCard card) {
    _masterDeck.add(card);
    notifyListeners();
    _saveToPrefs();
  }

  void removeCardFromMasterDeck(String cardId) {
    // Digunakan saat fitur "Hapus Kartu dari Deck" di Shop Area
    int index = _masterDeck.indexWhere((card) => card.id == cardId);
    if (index != -1) {
      _masterDeck.removeAt(index);
      notifyListeners();
      _saveToPrefs();
    }
  }

  /// 4. MANAJEMEN PROGRES MAP PETUALANGAN

  void completeNode(String nodeId) {
    if (!_completedNodeIds.contains(nodeId)) {
      _completedNodeIds.add(nodeId);
      _lastCompletedNodeId = nodeId;
      selectedNodeId = null;
      _inBattle = false; // Pertempuran/Shop di node ini selesai!
      _currentFloor++; // Naik ke lantai berikutnya ala Slay the Spire
      
      // Jika sudah melewati BOSS di lantai 6, petualangan dianggap tamat / selesai
      if (_currentFloor > 6) {
        _hasActiveRun = false;
      }

      notifyListeners();
      _saveToPrefs();
    }
  }

  /// 5. MANAJEMEN SLOT RAMUAN SEKALI PAKAI (CONSUMABLES)
  
  bool addConsumable(String id) {
    if (_consumableSlots.length >= 2) return false;
    _consumableSlots.add(id);
    notifyListeners();
    _saveToPrefs();
    return true;
  }

  void removeConsumableAt(int index) {
    if (index >= 0 && index < _consumableSlots.length) {
      _consumableSlots.removeAt(index);
      notifyListeners();
      _saveToPrefs();
    }
  }
}