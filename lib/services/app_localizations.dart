import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../models/playing_card.dart';
import '../models/enemy_metadata.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Map<String, dynamic> _uiTexts = {};
  static Map<String, dynamic> _cardTexts = {};
  static final Map<String, CardMetadata> _cardsMetadata = {};
  static final Map<String, EnemyMetadata> _enemiesMetadata = {};

  Future<bool> load() async {
    try {
      String uiJsonString = await rootBundle.loadString('assets/localization/ui/${locale.languageCode}.json');
      _uiTexts = json.decode(uiJsonString) as Map<String, dynamic>;

      String cardJsonString = await rootBundle.loadString('assets/localization/cards/${locale.languageCode}.json');
      _cardTexts = json.decode(cardJsonString) as Map<String, dynamic>;

      String cardDataString = await rootBundle.loadString('assets/data/cards.json');
      final Map<String, dynamic> cardDataMap = json.decode(cardDataString) as Map<String, dynamic>;
      final List<dynamic> cardsList = cardDataMap['cards'] as List<dynamic>;

      _cardsMetadata.clear();
      for (var cardJson in cardsList) {
        final meta = CardMetadata.fromJson(cardJson as Map<String, dynamic>);
        _cardsMetadata[meta.id] = meta;
      }

      String enemyDataString = await rootBundle.loadString('assets/data/enemies.json');
      final List<dynamic> enemiesList = json.decode(enemyDataString) as List<dynamic>;

      _enemiesMetadata.clear();
      for (var enemyJson in enemiesList) {
        final enemyMeta = EnemyMetadata.fromJson(enemyJson as Map<String, dynamic>);
        _enemiesMetadata[enemyMeta.id] = enemyMeta;
      }

      return true;
    } catch (e) {
      debugPrint("Error loading localizations/JSON data: $e");
      return false;
    }
  }

  String getUiText(String key) => _uiTexts[key] ?? key;
  CardMetadata? getCardMetadata(String cardId) => _cardsMetadata[cardId];
  String getCardName(String cardId) => _cardTexts[cardId]?['name'] ?? 'Unknown Card';
  String getCardDescription(String cardId) => _cardTexts[cardId]?['description'] ?? '';
  Map<String, CardMetadata> get allCardsMetadata => _cardsMetadata;
  EnemyMetadata? getEnemyMetadata(String enemyId) => _enemiesMetadata[enemyId];
  Map<String, EnemyMetadata> get allEnemiesMetadata => _enemiesMetadata;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'id'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}