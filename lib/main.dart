import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'board/board_state.dart';
import 'board/player_run.dart';
import 'screens/collection/collection_screen.dart';
import 'screens/gameplay/gameplay_screen.dart';
import 'screens/main_menu/main_menu_screen.dart';
import 'screens/map/map_screen.dart';
import 'services/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerRun()),
        ChangeNotifierProvider(create: (_) => BoardState()),
      ],
      child: MaterialApp(
        title: 'RPS Card Game',
        debugShowCheckedModeBanner: false,
        
        // ==========================================
        // TEMA UTAMA & FONT OUTFIT GLOBAL
        // ==========================================
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Outfit',
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
            default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Center(child: Text('Route ${settings.name} tidak ditemukan!')),
                ),
              );
          }
        },
      ),
    );
  }
}