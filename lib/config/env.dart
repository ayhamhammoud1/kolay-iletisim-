// ============================================================
// lib/config/env.dart
// Konfigürasyon sabitleri.
// Ücretsiz API kullanıldığı için artık API key gerekmez.
// ============================================================

class Env {
  Env._();

  /// OCR.space API Key (يمكن تمريره وقت البناء: --dart-define=OCR_API_KEY=your_key)
  static const String ocrApiKey = String.fromEnvironment(
    'OCR_API_KEY',
    defaultValue: 'K85674688188957',
  );

  static Future<void> init() async {
    // Başlatma gerekirse buraya eklenebilir.
  }
}