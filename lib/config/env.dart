// ============================================================
// lib/config/env.dart
// Konfigürasyon sabitleri.
// Ücretsiz API kullanıldığı için artık API key gerekmez.
// ============================================================

class Env {
  Env._();

  /// OCR.space API Key (تمريره اختياري وقت البناء: --dart-define=OCR_API_KEY=your_key)
  /// إذا كان فارغاً يتم استخدام Google ML Kit On-Device بدلاً منه.
  static const String ocrApiKey = String.fromEnvironment(
    'OCR_API_KEY',
    defaultValue: '',
  );

  static Future<void> init() async {
    // Başlatma gerekirse buraya eklenebilir.
  }
}