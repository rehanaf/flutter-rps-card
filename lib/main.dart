import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'board/board_state.dart';
import 'board/player_run.dart';
import 'screens/collection/collection_screen.dart';
import 'screens/gameplay/gameplay_screen.dart';
import 'screens/main_menu/main_menu_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/how_to_play/how_to_play_screen.dart';
import 'screens/all_outcomes/all_outcomes_screen.dart';
import 'services/app_localizations.dart';
import 'services/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Sembunyikan status bar dan bar navigasi bawaan dengan immersiveSticky
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Muat data game & pengaturan secara asinkron sebelum memicu runApp
  final playerRun = PlayerRun();
  await playerRun.loadFromPrefs();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadFromPrefs();

  runApp(MyApp(
    playerRun: playerRun,
    settingsProvider: settingsProvider,
  ));
}

class MyApp extends StatelessWidget {
  final PlayerRun playerRun;
  final SettingsProvider settingsProvider;

  const MyApp({
    super.key,
    required this.playerRun,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: playerRun),
        ChangeNotifierProvider(create: (_) => BoardState()),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'RPS Deck',
            debugShowCheckedModeBanner: false,
            locale: settingsProvider.locale,
        
        // ==========================================
        // TEMA UTAMA & FONT GLOBAL
        // ==========================================
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Familjen Grotesk',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC5A059), // Warna emas khas roguelike
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF141414), // Latar belakang gelap pekat
        ),

        // Konfigurasi Sistem Pelokalan Bahasa
        supportedLocales: const [
          Locale('en', ''),
          Locale('id', ''),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        
        // Rute awal otomatis mengarah ke Main Menu
        initialRoute: MainMenuScreen.routeName,
        
        // ==========================================
        // SISTEM ROUTE (DENGAN ONGENERATEROUTE)
        // ==========================================
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
            case MainMenuScreen.routeName:
              return MaterialPageRoute(builder: (_) => const MainMenuScreen());
            case MapScreen.routeName:
              return MaterialPageRoute(builder: (_) => const MapScreen());
            case GameplayScreen.routeName:
              return MaterialPageRoute(builder: (_) => const GameplayScreen());
            case CollectionScreen.routeName:
              return MaterialPageRoute(builder: (_) => const CollectionScreen());
            case ShopScreen.routeName:
              return MaterialPageRoute(builder: (_) => const ShopScreen());
            case HowToPlayScreen.routeName:
              return MaterialPageRoute(builder: (_) => const HowToPlayScreen());
            case AllOutcomesScreen.routeName:
              return MaterialPageRoute(builder: (_) => const AllOutcomesScreen());
            default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Center(child: Text('Route ${settings.name} tidak ditemukan!')),
                ),
              );
          }
        },
      );
    },
  ),
);
  }
}