import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolay_iletisim/main.dart';
import 'package:kolay_iletisim/providers/settings_provider.dart';
import 'package:kolay_iletisim/providers/history_provider.dart';
import 'package:kolay_iletisim/providers/translation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SpeakBridgeApp initializes and renders successfully', (WidgetTester tester) async {
    final settingsProvider = SettingsProvider();
    final historyProvider = HistoryProvider();
    final translationProvider = TranslationProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
          ChangeNotifierProvider<TranslationProvider>.value(value: translationProvider),
        ],
        child: const SpeakBridgeApp(),
      ),
    );

    // Initial frame
    await tester.pump();
    expect(find.byType(SpeakBridgeApp), findsOneWidget);

    // Pump forward for splash rendering
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('SpeakBridge'), findsWidgets);
  });
}
