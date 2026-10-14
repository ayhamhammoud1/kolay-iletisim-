// ============================================================
// lib/screens/history_screen.dart
// Çeviri Geçmişi ve Favoriler (Modern Glassmorphic Dark UI)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.radialBackground),
          child: SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.bgCardHover,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Çeviri Geçmişi',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.accentRose, size: 22),
                        tooltip: 'Geçmişi Temizle',
                        onPressed: () => _showClearDialog(context),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.accentRose.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      gradient: AppColors.cyanRoseGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Tümü'),
                      Tab(text: '⭐ Favoriler'),
                    ],
                  ),
                ),

                // Tab View
                const Expanded(
                  child: TabBarView(
                    children: [
                      _HistoryList(isFavoritesOnly: false),
                      _HistoryList(isFavoritesOnly: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgLighter,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.accentRose, size: 24),
            SizedBox(width: 8),
            Text('Geçmişi Temizle', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Tüm çeviri geçmişini ve favorileri silmek istediğinize emin misiniz?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HistoryProvider>().clearHistory();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRose,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tümünü Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final bool isFavoritesOnly;

  const _HistoryList({required this.isFavoritesOnly});

  Future<void> _speak(String text, String langCode) async {
    final bcp47 = switch (langCode) {
      'ar' => 'ar-SA',
      'en' => 'en-US',
      'tr' => 'tr-TR',
      'de' => 'de-DE',
      'fr' => 'fr-FR',
      'es' => 'es-ES',
      'ru' => 'ru-RU',
      _ => 'en-US',
    };
    await AudioService.instance.speak(text, TtsConfig(languageCode: bcp47));
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 18),
            SizedBox(width: 8),
            Text('Panoya kopyalandı!'),
          ],
        ),
        backgroundColor: AppColors.bgDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final records = isFavoritesOnly ? history.favorites : history.records;

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCardHover,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                isFavoritesOnly ? Icons.star_border_rounded : Icons.history_rounded,
                size: 48,
                color: AppColors.accentCyan,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFavoritesOnly ? 'Henüz favori çeviriniz yok.' : 'Henüz çeviri geçmişiniz yok.',
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              isFavoritesOnly
                  ? 'Beğendiğiniz çevirileri yıldızlayarak buraya ekleyebilirsiniz.'
                  : 'Yaptığınız tüm sesli ve metin çevirileri burada listelenir.',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = records[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCardHover,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header line with languages & favorite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(record.sourceLanguageLabel, style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted, size: 14),
                      ),
                      Text(record.targetLanguageLabel, style: const TextStyle(color: AppColors.accentRose, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          record.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: record.isFavorite ? AppColors.accentGold : AppColors.textMuted,
                          size: 22,
                        ),
                        onPressed: () => history.toggleFavorite(record.id),
                        tooltip: 'Favori',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
                        onPressed: () => history.deleteRecord(record.id),
                        tooltip: 'Sil',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Original text
              Text(
                record.originalText,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),

              const SizedBox(height: 8),

              // Translated text
              Text(
                record.translatedText,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 8),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.accentCyan),
                    label: const Text('Dinle', style: TextStyle(color: AppColors.accentCyan, fontSize: 12)),
                    onPressed: () => _speak(record.translatedText, record.targetLanguageCode),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
                    label: const Text('Kopyala', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    onPressed: () => _copy(context, record.translatedText),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
