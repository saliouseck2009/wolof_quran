import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import '../../l10n/generated/app_localizations.dart';
import '../cubits/daily_inspiration_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/bookmark_cubit.dart';
import '../../domain/entities/bookmark.dart';
import 'ayah_play_button.dart';
import 'home_header.dart'; // For AppIcon
import 'daily_inspiration_share_modal.dart';

class DailyInspirationCard extends StatelessWidget {
  const DailyInspirationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocBuilder<DailyInspirationCubit, DailyInspirationState>(
      builder: (context, state) {
        if (state is DailyInspirationLoading) {
          return _buildLoadingCard(context);
        } else if (state is DailyInspirationLoaded) {
          return _buildInspirationCard(context, localizations, state);
        } else if (state is DailyInspirationError) {
          return _buildErrorCard(context, localizations, state.message);
        }
        return _buildInitialCard(context, localizations);
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme
            .surfaceContainer, // darkSurfaceHigh in dark, light surface in light
        borderRadius: BorderRadius.circular(24),
        boxShadow: colorScheme.brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading daily inspiration...',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
              fontFamily: 'Hafs',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialCard(BuildContext context, AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentGreen = colorScheme.primary;
    return GestureDetector(
      onTap: () {
        final settingsCubit = context.read<QuranSettingsCubit>();
        final currentTranslation = settingsCubit.state.selectedTranslation;
        context.read<DailyInspirationCubit>().generateRandomAyah(
          currentTranslation,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          boxShadow: colorScheme.brightness == Brightness.dark
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(accentGreen: accentGreen, colorScheme: colorScheme),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Inspiration',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          fontFamily: 'Hafs',
                        ),
                      ),
                      Text(
                        'القرآن الكريم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: accentGreen,
                          fontFamily: 'Hafs',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Tap to get your daily verse from the Quran',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tap anywhere to start',
                  style: TextStyle(
                    fontSize: 12,
                    color: accentGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.play_disabled,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.touch_app, color: accentGreen, size: 20),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspirationCard(
    BuildContext context,
    AppLocalizations localizations,
    DailyInspirationLoaded state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentGreen = colorScheme.primary;
    return GestureDetector(
      onTap: () => context.read<DailyInspirationCubit>().toggleExpansion(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          boxShadow: colorScheme.brightness == Brightness.dark
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Islamic logo and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Flexible(
                    child: Text(
                      '${state.surahName} - Ayah ${state.verseNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AyahPlayButton(
                        surahNumber: state.surahNumber,
                        ayahNumber: state.verseNumber,
                        surahName: state.surahName,
                        size: 18.0,
                        color: accentGreen,
                      ),
                      IconButton(
                        onPressed: () {
                          showDailyInspirationShareModal(
                            context,
                            state.verseNumber,
                            state.arabicText,
                            state.translation,
                            _getTranslationSourceName(state.currentTranslation),
                            state.surahName,
                            state.surahNumber,
                          );
                        },
                        icon: Icon(Icons.share, color: accentGreen, size: 18),
                      ),
                      IconButton(
                        onPressed: () {
                          final settingsCubit = context
                              .read<QuranSettingsCubit>();
                          final currentTranslation =
                              settingsCubit.state.selectedTranslation;
                          context.read<DailyInspirationCubit>().refreshAyah(
                            currentTranslation,
                          );
                        },
                        icon: Icon(Icons.refresh, color: accentGreen, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 16),
            Text(
              state.isExpanded || state.translation.length <= 150
                  ? state.translation
                  : '${state.translation.substring(0, 150)}...',
              style: TextStyle(
                fontSize: state.isExpanded ? 14 : 12,
                color: colorScheme.onSurface,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Arabic text (shown when expanded)
            if (state.isExpanded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentGreen.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentGreen.withValues(alpha: 0.2)),
                ),
                child: Text(
                  state.arabicText,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Hafs',
                    color: colorScheme.onSurface,
                    height: 1.8,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/surah-detail',
                          arguments: state.surahNumber,
                        );
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text(
                        'Open Surah',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: accentGreen,
                        side: BorderSide(color: accentGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BlocBuilder<BookmarkCubit, BookmarkState>(
                      builder: (context, bookmarkState) {
                        final isBookmarked = context
                            .read<BookmarkCubit>()
                            .isBookmarked(state.surahNumber, state.verseNumber);

                        return OutlinedButton.icon(
                          onPressed: () {
                            final bookmarkCubit = context.read<BookmarkCubit>();
                            final bookmark = BookmarkedAyah(
                              surahNumber: state.surahNumber,
                              verseNumber: state.verseNumber,
                              surahName: state.surahName,
                              arabicText: state.arabicText,
                              translation: state.translation,
                              translationSource: _getTranslationSourceName(
                                state.currentTranslation,
                              ),
                              createdAt: DateTime.now(),
                            );

                            bookmarkCubit.toggleBookmark(bookmark);
                          },
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            size: 16,
                          ),
                          label: Text(
                            isBookmarked ? 'Bookmarked' : 'Bookmark',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: accentGreen),
                            backgroundColor: isBookmarked
                                ? accentGreen
                                : Colors.transparent,
                            foregroundColor: isBookmarked
                                ? colorScheme.onPrimary
                                : accentGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Tap to expand hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to read Arabic & more',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.expand_more, color: accentGreen, size: 20),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    AppLocalizations localizations,
    String errorMessage,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 24),
              const SizedBox(width: 12),
              Text(
                'Daily Inspiration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onErrorContainer,
                  fontFamily: 'Hafs',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onErrorContainer,
              fontFamily: 'Hafs',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final settingsCubit = context.read<QuranSettingsCubit>();
              final currentTranslation = settingsCubit.state.selectedTranslation;
              context.read<DailyInspirationCubit>().generateRandomAyah(
                currentTranslation,
              );
            },
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getTranslationSourceName(quran.Translation translation) {
    switch (translation) {
      case quran.Translation.enSaheeh:
        return 'Saheeh International';
      case quran.Translation.enClearQuran:
        return 'Clear Quran';
      case quran.Translation.frHamidullah:
        return 'Muhammad Hamidullah';
      case quran.Translation.trSaheeh:
        return 'Türkçe';
      case quran.Translation.mlAbdulHameed:
        return 'Malayalam';
      case quran.Translation.faHusseinDari:
        return 'Farsi';
      case quran.Translation.portuguese:
        return 'Português';
      case quran.Translation.itPiccardo:
        return 'Italiano';
      case quran.Translation.nlSiregar:
        return 'Nederlands';
      case quran.Translation.ruKuliev:
        return 'Русский';
      case quran.Translation.bengali:
        return 'Bengali';
      case quran.Translation.chinese:
        return 'Chinese';
      default:
        return 'Translation';
    }
  }
}
