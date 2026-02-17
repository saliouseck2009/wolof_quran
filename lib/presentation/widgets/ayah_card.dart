import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolof_quran/presentation/widgets/reciter_chapters/chapter_number_widget.dart';

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
        color: isDark ? colorScheme.surfaceContainer : colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ChapterNumberWidget(
                  color: colorScheme.primary,
                  surahNumber: verseNumber,
                  textTheme: textTheme,
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
            const SizedBox(height: 8),
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

            if (displayMode == AyahDisplayMode.translationOnly ||
                displayMode == AyahDisplayMode.both)
              const SizedBox(height: 12),
            if ((displayMode == AyahDisplayMode.both ||
                    displayMode == AyahDisplayMode.translationOnly) &&
                translation.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: displayMode == AyahDisplayMode.translationOnly
                      ? Colors.transparent
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   translationSource,
                    //   textAlign: TextAlign.justify,
                    //   style: textTheme.labelMedium?.copyWith(
                    //     color: colorScheme.primary,
                    //   ),
                    // ),
                    // const SizedBox(height: 4),
                    Text(
                      translation,
                      textAlign: TextAlign.justify,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: displayMode == AyahDisplayMode.translationOnly
                            ? 16
                            : 14,
                        height: 1.4,
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
