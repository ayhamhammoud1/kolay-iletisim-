// ============================================================
// lib/services/translation_api_service.dart
// Production-Ready Hybrid Translation Engine
// 1. On-Device Google ML Kit (Offline, Free, High Speed)
// 2. MyMemory Translation API (Official Free Fallback)
// 3. Google Translate Web Engine (Safety Fallback)
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;

import '../models/language_model.dart';
import '../models/service_result.dart';
import '../utils/app_logger.dart';

class TranslationApiService {
  TranslationApiService._internal();
  static final TranslationApiService instance = TranslationApiService._internal();
  static const _tag = 'TranslationApiService';

  final Map<String, OnDeviceTranslator> _translatorCache = {};

  /// Main translation entry point with intelligent multi-tier fallback.
  Future<ServiceResult<TranslationResult>> translate({
    required String text,
    required AppLanguage source,
    required AppLanguage target,
  }) async {
    final query = text.trim();
    if (query.isEmpty) {
      return const ServiceFailure('Çevrilecek metin boş.');
    }

    if (source == target) {
      return ServiceSuccess(
        TranslationResult(
          originalText: query,
          translatedText: query,
          sourceLanguage: source,
          targetLanguage: target,
          isOffline: true,
        ),
      );
    }

    AppLogger.i(_tag, 'Translation request: ${source.code} → ${target.code}: "$query"');

    // ─── TIER 1: On-Device Google ML Kit (Android / iOS) ───
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final onDeviceResult = await _translateWithMlKit(query, source.code, target.code);
        if (onDeviceResult != null && onDeviceResult.trim().isNotEmpty) {
          AppLogger.i(_tag, '✅ ML Kit On-Device success: "$onDeviceResult"');
          return ServiceSuccess(
            TranslationResult(
              originalText: query,
              translatedText: onDeviceResult,
              sourceLanguage: source,
              targetLanguage: target,
              isOffline: true,
            ),
          );
        }
      } catch (e) {
        AppLogger.w(_tag, 'ML Kit On-Device skipped or failed: $e');
      }
    }

    // ─── TIER 2: MyMemory Translation API (Official Free Tier) ───
    try {
      final myMemoryResult = await _callMyMemoryApi(query, source.code, target.code);
      if (myMemoryResult != null && myMemoryResult.trim().isNotEmpty) {
        AppLogger.i(_tag, '✅ MyMemory API success: "$myMemoryResult"');
        return ServiceSuccess(
          TranslationResult(
            originalText: query,
            translatedText: myMemoryResult,
            sourceLanguage: source,
            targetLanguage: target,
            isOffline: false,
          ),
        );
      }
    } catch (e) {
      AppLogger.w(_tag, 'MyMemory API failed: $e');
    }

    // ─── TIER 3: Google Web Engine Fallback ───
    try {
      final googleResult = await _callGoogleWebTranslate(query, source.code, target.code);
      if (googleResult != null && googleResult.trim().isNotEmpty) {
        AppLogger.i(_tag, '✅ Google Web fallback success: "$googleResult"');
        return ServiceSuccess(
          TranslationResult(
            originalText: query,
            translatedText: googleResult,
            sourceLanguage: source,
            targetLanguage: target,
            isOffline: false,
          ),
        );
      }
    } catch (e) {
      AppLogger.w(_tag, 'Google Web fallback failed: $e');
    }

    return const ServiceFailure(
      'Çeviri şu anda yapılamadı. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
    );
  }

  // ────────────────────────────────────────────────────────────
  // Tier 1: Google ML Kit On-Device
  // ────────────────────────────────────────────────────────────
  Future<String?> _translateWithMlKit(String text, String fromCode, String toCode) async {
    final srcLang = _toMlKitLanguage(fromCode);
    final tgtLang = _toMlKitLanguage(toCode);
    if (srcLang == null || tgtLang == null) return null;

    final key = '${srcLang.name}_${tgtLang.name}';
    final translator = _translatorCache.putIfAbsent(
      key,
      () => OnDeviceTranslator(sourceLanguage: srcLang, targetLanguage: tgtLang),
    );

    final modelManager = OnDeviceTranslatorModelManager();
    final isSourceReady = await modelManager.isModelDownloaded(srcLang.bcpCode);
    final isTargetReady = await modelManager.isModelDownloaded(tgtLang.bcpCode);

    if (!isSourceReady || !isTargetReady) {
      AppLogger.i(_tag, 'Downloading offline translation models: ${srcLang.name}, ${tgtLang.name}');
      if (!isSourceReady) await modelManager.downloadModel(srcLang.bcpCode, isWifiRequired: false);
      if (!isTargetReady) await modelManager.downloadModel(tgtLang.bcpCode, isWifiRequired: false);
    }

    return await translator.translateText(text).timeout(const Duration(seconds: 8));
  }

  TranslateLanguage? _toMlKitLanguage(String code) {
    return switch (code.toLowerCase()) {
      'ar' => TranslateLanguage.arabic,
      'tr' => TranslateLanguage.turkish,
      'en' => TranslateLanguage.english,
      'de' => TranslateLanguage.german,
      'fr' => TranslateLanguage.french,
      'es' => TranslateLanguage.spanish,
      'ru' => TranslateLanguage.russian,
      'zh' => TranslateLanguage.chinese,
      'ja' => TranslateLanguage.japanese,
      _ => null,
    };
  }

  // ────────────────────────────────────────────────────────────
  // Tier 2: MyMemory Translation API
  // ────────────────────────────────────────────────────────────
  Future<String?> _callMyMemoryApi(String text, String fromCode, String toCode) async {
    final uri = Uri.parse(
      'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$fromCode|$toCode',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final responseData = data['responseData'];
      if (responseData != null && responseData['translatedText'] != null) {
        final result = responseData['translatedText'].toString().trim();
        if (result.isNotEmpty && !result.toLowerCase().contains('my memory error')) {
          return result;
        }
      }
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────
  // Tier 3: Google Web Engine (gtx fallback)
  // ────────────────────────────────────────────────────────────
  Future<String?> _callGoogleWebTranslate(String text, String fromCode, String toCode) async {
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$fromCode&tl=$toCode&dt=t&q=${Uri.encodeComponent(text)}',
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json is List && json.isNotEmpty && json[0] is List && json[0].isNotEmpty) {
        final segments = json[0] as List;
        final buffer = StringBuffer();
        for (final segment in segments) {
          if (segment is List && segment.isNotEmpty) {
            buffer.write(segment[0]);
          }
        }
        final result = buffer.toString().trim();
        if (result.isNotEmpty) return result;
      }
    }
    return null;
  }

  void dispose() {
    for (final translator in _translatorCache.values) {
      translator.close();
    }
    _translatorCache.clear();
  }
}
