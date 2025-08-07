import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/theme/app_color.dart';
import '../cubits/surah_detail_cubit.dart';

/// A card to show one Ayah (verse) of the Quran:
///  • Top row: a little pill with the verse number + action icons (play, bookmark…)
///  • Middle: big centered Arabic text
///  • Bottom: translation label + translation text
class AyahCard extends StatelessWidget {
  /// The verse/ayah number
  final int verseNumber;

  /// The Arabic text of the verse
  final String arabicText;

  /// The translation source, e.g. "Sahih International"
  final String translationSource;

  /// The translated text
  final String translation;

  /// A list of widgets to show in the top row (e.g. play button, bookmark, etc.)
  final List<Widget> actions;

  /// The display mode for showing Arabic, translation, or both
  final AyahDisplayMode displayMode;

  const AyahCard({
    super.key,
    required this.verseNumber,
    required this.arabicText,
    required this.translationSource,
    required this.translation,
    this.actions = const [],
    this.displayMode = AyahDisplayMode.both,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Top Row: verse pill + actions ──────────────────────────
            Row(
              children: [
                // the little "pill" with the verse number
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColor.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    verseNumber.toString(),
                    style: GoogleFonts.amiri(
                      color: AppColor.pureWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                const Spacer(),

                // action icons
                ...actions,
              ],
            ),

            const SizedBox(height: 24),

            // ─── Arabic Text ─────────────────────────────────────────────
            // Show Arabic text only if mode is both or arabicOnly
            if (displayMode == AyahDisplayMode.both ||
                displayMode == AyahDisplayMode.arabicOnly)
              Text(
                arabicText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiriQuran(
                  fontSize: displayMode == AyahDisplayMode.arabicOnly ? 32 : 28,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),

            // Add separator between Arabic and translation when both are shown
            if (displayMode == AyahDisplayMode.both) const SizedBox(height: 24),
            if (displayMode == AyahDisplayMode.both)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColor.primaryGreen.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

            // Add spacing for translation-only mode or after separator
            if (displayMode == AyahDisplayMode.translationOnly ||
                displayMode == AyahDisplayMode.both)
              const SizedBox(height: 24),

            // ─── Translation Section ─────────────────────────────────────
            // Show translation only if mode is both or translationOnly
            if ((displayMode == AyahDisplayMode.both ||
                    displayMode == AyahDisplayMode.translationOnly) &&
                translation.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.lightGray.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Translation Label
                    Text(
                      translationSource,
                      style: GoogleFonts.amiri(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Translation Text
                    Text(
                      translation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: displayMode == AyahDisplayMode.translationOnly
                            ? 18
                            : 16,
                        height: 1.5,
                        color: AppColor.translationText,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
