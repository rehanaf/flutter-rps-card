import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  Locale _locale = const Locale('id'); // Default ke Bahasa Indonesia sesuai dengan permintaan data bahasa id

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  Locale get locale => _locale;

  /// Memuat pengaturan dari SharedPreferences
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMusicEnabled = prefs.getBool('music_enabled') ?? true;
      _isSfxEnabled = prefs.getBool('sfx_enabled') ?? true;
      final langCode = prefs.getString('language_code') ?? 'id';
      _locale = Locale(langCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings from SharedPreferences: $e');
    }
  }

  /// Menyimpan pengaturan ke SharedPreferences secara asinkron (fire-and-forget)
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('music_enabled', _isMusicEnabled);
      await prefs.setBool('sfx_enabled', _isSfxEnabled);
      await prefs.setString('language_code', _locale.languageCode);
    } catch (e) {
      debugPrint('Error saving settings to SharedPreferences: $e');
    }
  }

  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    notifyListeners();
    _saveToPrefs();
  }

  void toggleSfx() {
    _isSfxEnabled = !_isSfxEnabled;
    notifyListeners();
    _saveToPrefs();
  }

  void setMusic(bool enabled) {
    if (_isMusicEnabled != enabled) {
      _isMusicEnabled = enabled;
      notifyListeners();
      _saveToPrefs();
    }
  }

  void setSfx(bool enabled) {
    if (_isSfxEnabled != enabled) {
      _isSfxEnabled = enabled;
      notifyListeners();
      _saveToPrefs();
    }
  }

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
      _saveToPrefs();
    }
  }
}
