// ============================================================
// lib/screens/phrasebook_screen.dart
// Çevrimdışı Turist Cümle Rehberi (Offline Phrasebook)
// İnternetsiz anında arama, sesli telaffuz ve kategori filtreleme.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/offline_service.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';

class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({super.key});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  bool _isLoading = true;
  String _selectedCategoryId = 'emergency';
  PhraseCategory? _currentCategory;
  List<Phrase> _displayedPhrases = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await OfflineService.instance.loadIndex();
    await _selectCategory(_selectedCategoryId);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCategory(String categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _isSearching = false;
      _searchController.clear();
    });
    final category = await OfflineService.instance.getCategory(categoryId);
    if (mounted) {
      setState(() {
        _currentCategory = category;
        _displayedPhrases = category?.phrases ?? [];
      });
    }
  }

  void _onSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _displayedPhrases = _currentCategory?.phrases ?? [];
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await OfflineService.instance.search(q, 'ar');
    final trResults = await OfflineService.instance.search(q, 'tr');
    final enResults = await OfflineService.instance.search(q, 'en');

    final Map<String, Phrase> uniqueMap = {};
    for (final p in [...results, ...trResults, ...enResults]) {
      uniqueMap[p.id] = p;
    }

    if (mounted) {
      setState(() {
        _displayedPhrases = uniqueMap.values.toList();
      });
    }
  }

  Future<void> _speak(String text, String lang) async {
    final config = TtsConfig(
      languageCode: lang == 'ar' ? 'ar-SA' : (lang == 'en' ? 'en-US' : 'tr-TR'),
      speechRate: 0.9,
    );
    await AudioService.instance.speak(text, config);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 18),
            SizedBox(width: 8),
            Text('Metin panoya kopyalandı!'),
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
    final categories = OfflineService.instance.categoryList;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.radialBackground),
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Çevrimdışı Cümle Rehberi',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            'İnternet olmadan anında iletişim',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded, color: AppColors.accentEmerald, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'OFFLINE',
                            style: TextStyle(color: AppColors.accentEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cümle veya kelime ara... (Türkçe/عربي/English)',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentCyan, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              // Categories Selector
              if (!_isSearching && categories.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final id = cat['id'] as String;
                      final isSelected = id == _selectedCategoryId;
                      final label = (cat['label'] as Map)['tr'] ?? id;
                      final icon = cat['icon'] ?? '💬';

                      return ChoiceChip(
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.bgCardHover,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                          side: BorderSide(
                            color: isSelected ? AppColors.accentCyan : AppColors.border,
                          ),
                        ),
                        onSelected: (_) => _selectCategory(id),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),

              // Content List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
                    : _displayedPhrases.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  _isSearching ? 'Eşleşen cümle bulunamadı.' : 'Bu kategoride cümle yok.',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _displayedPhrases.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final phrase = _displayedPhrases[index];
                              final tr = phrase.getText('tr');
                              final ar = phrase.getText('ar');
                              final en = phrase.getText('en');

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
                                    // Turkish (Primary local)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentCyan.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Text('🇹🇷', style: TextStyle(fontSize: 14)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            tr,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.volume_up_rounded, color: AppColors.accentCyan),
                                          iconSize: 22,
                                          onPressed: () => _speak(tr, 'tr'),
                                          tooltip: 'Türkçe Dinle',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, color: AppColors.textMuted),
                                          iconSize: 18,
                                          onPressed: () => _copyToClipboard(tr),
                                          tooltip: 'Kopyala',
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),
                                    const Divider(color: AppColors.border, height: 1),
                                    const SizedBox(height: 10),

                                    // Arabic
                                    if (ar.isNotEmpty)
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            child: const Text('🇸🇦', style: TextStyle(fontSize: 12)),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              ar,
                                              style: const TextStyle(
                                                color: AppColors.accentGold,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textDirection: TextDirection.rtl,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.volume_up_outlined, color: AppColors.accentGold),
                                            iconSize: 18,
                                            onPressed: () => _speak(ar, 'ar'),
                                            tooltip: 'العربية استماع',
                                          ),
                                        ],
                                      ),

                                    // English
                                    if (en.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              child: const Text('🇺🇸', style: TextStyle(fontSize: 12)),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                en,
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
