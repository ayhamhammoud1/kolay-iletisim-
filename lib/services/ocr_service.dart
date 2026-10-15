// ============================================================
// lib/services/ocr_service.dart
// Production-Ready Hybrid OCR Service
// 1. Google ML Kit On-Device Text Recognition (Mobile native, 0 API key, 0 internet)
// 2. OCR.space Web API fallback (optional when API key is provided)
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/service_result.dart';
import '../models/ocr_text_line.dart';
import '../utils/app_logger.dart';

class OcrService {
  OcrService._internal();
  static final OcrService instance = OcrService._internal();
  static const _tag = 'OcrService';

  // OCR.space API endpoint (optional fallback)
  static String get _apiKey => Env.ocrApiKey;
  static const _endpoint = 'https://api.ocr.space/parse/image';

  /// Extracts text and line coordinates from image bytes or file path.
  Future<ServiceResult<List<OcrTextLine>>> extractTextFromImage(
    Uint8List imageBytes, {
    String? filePath,
  }) async {
    // ─── TIER 1: On-Device Google ML Kit (Android / iOS) ───
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        String? targetPath = filePath;
        File? tempFile;

        if (targetPath == null || targetPath.isEmpty) {
          final tempDir = Directory.systemTemp;
          tempFile = File('${tempDir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(imageBytes);
          targetPath = tempFile.path;
        }

        final inputImage = InputImage.fromFilePath(targetPath);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        if (tempFile != null && await tempFile.exists()) {
          try {
            await tempFile.delete();
          } catch (_) {}
        }

        final List<OcrTextLine> parsedLines = [];
        for (final block in recognizedText.blocks) {
          for (final line in block.lines) {
            final t = line.text.trim();
            if (t.isNotEmpty) {
              final rect = line.boundingBox;
              parsedLines.add(
                OcrTextLine(
                  text: t,
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  height: rect.height,
                ),
              );
            }
          }
        }

        if (parsedLines.isNotEmpty) {
          AppLogger.i(_tag, '✅ ML Kit On-Device OCR: ${parsedLines.length} lines detected');
          return ServiceSuccess(parsedLines);
        }
      } catch (e) {
        AppLogger.w(_tag, 'ML Kit On-Device OCR error, checking fallback: $e');
      }
    }

    // ─── TIER 2: OCR.space Web API Fallback (Only if key configured) ───
    if (_apiKey.isNotEmpty) {
      try {
        AppLogger.i(_tag, 'OCR.space web fallback running (${imageBytes.length} bytes)...');
        final base64Image = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

        final response = await http.post(
          Uri.parse(_endpoint),
          body: {
            'apikey': _apiKey,
            'base64Image': base64Image,
            'language': 'tur',
            'isOverlayRequired': 'true',
            'detectOrientation': 'true',
            'scale': 'true',
            'OCREngine': '2',
          },
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json['IsErroredOnProcessing'] == true) {
            final errorMsg = json['ErrorMessage']?.toString() ?? 'OCR hatası';
            return ServiceFailure(errorMsg);
          }

          final results = json['ParsedResults'] as List?;
          if (results == null || results.isEmpty) {
            return const ServiceFailure('Fotoğrafta metin bulunamadı.');
          }

          final firstResult = results.first;
          final textOverlay = firstResult['TextOverlay'];
          final List<OcrTextLine> parsedLines = [];

          if (textOverlay != null && textOverlay['Lines'] != null) {
            final lines = textOverlay['Lines'] as List;
            for (var line in lines) {
              final lineText = line['LineText']?.toString().trim() ?? '';
              if (lineText.isNotEmpty) {
                final maxHeight = (line['MaxHeight'] as num?)?.toDouble() ?? 0.0;
                final minTop = (line['MinTop'] as num?)?.toDouble() ?? 0.0;
                double left = 0.0;
                double width = 0.0;
                final words = line['Words'] as List?;
                if (words != null && words.isNotEmpty) {
                  left = (words.first['Left'] as num?)?.toDouble() ?? 0.0;
                  final lastWord = words.last;
                  final lastLeft = (lastWord['Left'] as num?)?.toDouble() ?? 0.0;
                  final lastWidth = (lastWord['Width'] as num?)?.toDouble() ?? 0.0;
                  width = (lastLeft + lastWidth) - left;
                }

                parsedLines.add(OcrTextLine(
                  text: lineText,
                  left: left,
                  top: minTop,
                  width: width,
                  height: maxHeight,
                ));
              }
            }
          }

          if (parsedLines.isNotEmpty) {
            return ServiceSuccess(parsedLines);
          }
        }
      } catch (e) {
        AppLogger.w(_tag, 'OCR.space fallback error: $e');
      }
    }

    return const ServiceFailure('Fotoğrafta okunabilir metin bulunamadı.');
  }
}
