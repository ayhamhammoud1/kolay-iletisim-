// ============================================================
// lib/screens/settings_screen.dart
// Ayarlar Ekranı (Modern Glassmorphic Dark UI)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.radialBackground),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                    const Text(
                      'Ayarlar',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              // Content List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Section 1: Ses & Çeviri
                    _buildSectionHeader('SES VE ÇEVİRİ', Icons.graphic_eq_rounded),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCardHover,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.volume_up_rounded, color: AppColors.accentCyan, size: 20),
                            ),
                            title: const Text(
                              'Otomatik Seslendir',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            subtitle: const Text(
                              'Çeviri tamamlandığında otomatik oku',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            value: settings.autoSpeak,
                            activeThumbColor: AppColors.accentCyan,
                            onChanged: (val) => settings.setAutoSpeak(val),
                          ),
                          const Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentRose.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.speed_rounded, color: AppColors.accentRose, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Konuşma Hızı',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${(settings.speechRate * 100).toInt()}%',
                                      style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Slider(
                                  value: settings.speechRate,
                                  min: 0.2,
                                  max: 1.0,
                                  activeColor: AppColors.accentCyan,
                                  inactiveColor: AppColors.border,
                                  onChanged: (val) => settings.setSpeechRate(val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section 2: Görünüm & Tema
                    _buildSectionHeader('GÖRÜNÜM', Icons.palette_outlined),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCardHover,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.dark_mode_rounded, color: AppColors.accentGold, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Karanlık Mod (Cyberpunk)',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                Text(
                                  'Göz yormayan yüksek kontrast',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'AKTİF',
                              style: TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section 3: Uygulama Hakkında
                    _buildSectionHeader('UYGULAMA BİLGİLERİ', Icons.info_outline_rounded),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCardHover,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildInfoTile('Uygulama', 'SpeakBridge (Kolay İletişim)'),
                          const Divider(color: AppColors.border, height: 1),
                          _buildInfoTile('Sürüm', 'v1.0.0 Pro Edition'),
                          const Divider(color: AppColors.border, height: 1),
                          _buildInfoTile('Çeviri Motoru', 'Google Cloud GTX + MyMemory Fallback'),
                          const Divider(color: AppColors.border, height: 1),
                          _buildInfoTile('Harita & Navigasyon', 'OpenStreetMap + OSRM Routing'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentCyan, size: 14),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.accentCyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
