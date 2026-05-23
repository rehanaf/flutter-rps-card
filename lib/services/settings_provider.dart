import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  Locale _locale = const Locale('id'); // Default ke Bahasa Indonesia sesuai dengan permintaan data bahasa id

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  Locale get locale => _locale;

  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    notifyListeners();
  }

  void toggleSfx() {
    _isSfxEnabled = !_isSfxEnabled;
    notifyListeners();
  }

  void setMusic(bool enabled) {
    if (_isMusicEnabled != enabled) {
      _isMusicEnabled = enabled;
      notifyListeners();
    }
  }

  void setSfx(bool enabled) {
    if (_isSfxEnabled != enabled) {
      _isSfxEnabled = enabled;
      notifyListeners();
    }
  }

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
    }
  }
}
