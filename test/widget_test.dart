// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_rps_game/main.dart';
import 'package:my_rps_game/board/player_run.dart';
import 'package:my_rps_game/services/settings_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      playerRun: PlayerRun(),
      settingsProvider: SettingsProvider(),
    ));

    // Verify main app runs
    expect(find.byType(MyApp), findsOneWidget);
  });
}
