import 'package:flutter_test/flutter_test.dart';
import 'package:kolay_iletisim/models/language_model.dart';
import 'package:kolay_iletisim/models/service_result.dart';
import 'package:kolay_iletisim/services/translation_api_service.dart';
import 'package:kolay_iletisim/services/offline_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLanguage Tests', () {
    test('Correctly identifies supported languages from code', () {
      expect(AppLanguage.fromCode('ar'), AppLanguage.arabic);
      expect(AppLanguage.fromCode('tr'), AppLanguage.turkish);
      expect(AppLanguage.fromCode('en'), AppLanguage.english);
      expect(AppLanguage.fromCode('unknown'), AppLanguage.english); // Default fallback
    });

    test('All languages have valid bcp47 and flags', () {
      for (final lang in AppLanguage.values) {
        expect(lang.code.isNotEmpty, isTrue);
        expect(lang.bcp47.isNotEmpty, isTrue);
        expect(lang.flag.isNotEmpty, isTrue);
        expect(lang.displayName.contains(lang.flag), isTrue);
      }
    });
  });

  group('TranslationApiService Validation Tests', () {
    test('Returns ServiceFailure when input text is empty or whitespace', () async {
      final result = await TranslationApiService.instance.translate(
        text: '   ',
        source: AppLanguage.arabic,
        target: AppLanguage.turkish,
      );

      expect(result, isA<ServiceFailure>());
      result.when(
        success: (_) => fail('Should not succeed for empty text'),
        failure: (msg) => expect(msg.isNotEmpty, isTrue),
      );
    });

    test('Returns instant success without network call when source == target language', () async {
      const sampleText = 'مرحباً بكم';
      final result = await TranslationApiService.instance.translate(
        text: sampleText,
        source: AppLanguage.arabic,
        target: AppLanguage.arabic,
      );

      expect(result, isA<ServiceSuccess>());
      result.when(
        success: (res) {
          expect(res.translatedText, sampleText);
          expect(res.isOffline, isTrue);
        },
        failure: (msg) => fail('Should succeed immediately'),
      );
    });
  });

  group('OfflineService Phrasebook Tests', () {
    test('Loads category index and retrieves metadata', () async {
      final service = OfflineService.instance;
      await service.loadIndex();

      expect(service.categoryList.isNotEmpty, isTrue);
      final categoryIds = service.categoryList.map((c) => c['id']).toList();
      expect(categoryIds, containsAll(['emergency', 'health', 'hotel', 'restaurant']));
    });

    test('Loads category phrases and performs search', () async {
      final service = OfflineService.instance;
      await service.loadIndex();

      final category = await service.getCategory('emergency');
      expect(category, isNotNull);
      expect(category!.phrases.isNotEmpty, isTrue);

      final firstPhrase = category.phrases.first;
      expect(firstPhrase.getText('ar').isNotEmpty, isTrue);
      expect(firstPhrase.getText('tr').isNotEmpty, isTrue);

      // Search test
      final searchResults = await service.search('police', 'en');
      expect(searchResults.isNotEmpty, isTrue);
    });
  });
}
