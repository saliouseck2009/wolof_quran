import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/generated/app_localizations.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/surah_detail_cubit.dart';
import 'daily_inspiration_share_modal.dart';

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

  /// The font size for Arabic text
  final double? fontSize;

  /// Additional context for sharing
  final String? surahName;
  final int? surahNumber;

  const AyahCard({
    super.key,
    required this.verseNumber,
    required this.arabicText,
    required this.translationSource,
    required this.translation,
    this.actions = const [],
    this.displayMode = AyahDisplayMode.both,
    this.fontSize,
    this.surahName,
    this.surahNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.25 : 0.3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    verseNumber.toString(),
                    style: textTheme.labelLarge?.copyWith(
                      fontFamily: 'Hafs',
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                ...actions,
                IconButton(
                  icon: Icon(Icons.share, color: colorScheme.primary, size: 20),
                  onPressed: () => _showShareModal(context),
                  tooltip:
                      AppLocalizations.of(context)?.shareAyah ?? 'Share Ayah',
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (displayMode == AyahDisplayMode.both ||
                displayMode == AyahDisplayMode.arabicOnly)
              BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
                builder: (context, settingsState) {
                  double arabicFontSize = 28.0;
                  if (fontSize != null) {
                    arabicFontSize = fontSize!;
                  } else {
                    arabicFontSize = settingsState.ayahFontSize;
                  }
                  if (displayMode == AyahDisplayMode.arabicOnly) {
                    arabicFontSize += 4;
                  }
                  return Text(
                    arabicText,
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Hafs',
                      fontSize: arabicFontSize,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  );
                },
              ),
            if (displayMode == AyahDisplayMode.both) const SizedBox(height: 24),
            if (displayMode == AyahDisplayMode.both)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
            if (displayMode == AyahDisplayMode.translationOnly ||
                displayMode == AyahDisplayMode.both)
              const SizedBox(height: 24),
            if ((displayMode == AyahDisplayMode.both ||
                    displayMode == AyahDisplayMode.translationOnly) &&
                translation.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translationSource,
                      textAlign: TextAlign.justify,
                      style: textTheme.labelLarge?.copyWith(
                        fontFamily: 'Hafs',
                        letterSpacing: 0.5,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translation,
                      textAlign: TextAlign.justify,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: displayMode == AyahDisplayMode.translationOnly
                            ? 18
                            : 16,
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
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

  void _showShareModal(BuildContext context) {
    showDailyInspirationShareModal(
      context,
      verseNumber,
      arabicText,
      translation,
      translationSource,
      surahName ?? '',
      surahNumber ?? 0,
    );
  }
}
