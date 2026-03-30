import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import '../../l10n/generated/app_localizations.dart';
import '../cubits/daily_inspiration_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/bookmark_cubit.dart';
import '../../domain/entities/bookmark.dart';
import '../../core/navigation/surah_detail_arguments.dart';
import 'ayah_play_button.dart';
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
    final localizations = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.loadingDailyInspiration,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
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
          color: colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.dailyInspirationTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              localizations.tapForDailyVerse,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  localizations.tapAnywhereToStart,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
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
    return GestureDetector(
      onTap: () => context.read<DailyInspirationCubit>().toggleExpansion(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Surah tag + actions row
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${state.surahName} : ${state.verseNumber}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _ActionIcon(
                  child: AyahPlayButton(
                    surahNumber: state.surahNumber,
                    ayahNumber: state.verseNumber,
                    surahName: state.surahName,
                    size: 16.0,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                _ActionIcon(
                  onTap: () {
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
                  child: Icon(
                    Icons.share_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 4),
                _ActionIcon(
                  onTap: () {
                    final settingsCubit = context.read<QuranSettingsCubit>();
                    final currentTranslation =
                        settingsCubit.state.selectedTranslation;
                    context.read<DailyInspirationCubit>().refreshAyah(
                      currentTranslation,
                    );
                  },
                  child: Icon(
                    Icons.refresh_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Translation text
            Text(
              state.isExpanded || state.translation.length <= 150
                  ? state.translation
                  : '${state.translation.substring(0, 150)}...',
              style: TextStyle(
                fontSize: state.isExpanded ? 14 : 13,
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            ),

            // Expanded content
            if (state.isExpanded) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  state.arabicText,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Hafs',
                    color: colorScheme.onSurface,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _FlatActionButton(
                      icon: Icons.open_in_new_rounded,
                      label: localizations.openSurah,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/surah-detail',
                          arguments: SurahDetailArguments(
                            surahNumber: state.surahNumber,
                            initialAyahNumber: state.verseNumber,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BlocBuilder<BookmarkCubit, BookmarkState>(
                      builder: (context, bookmarkState) {
                        final isBookmarked = context
                            .read<BookmarkCubit>()
                            .isBookmarked(state.surahNumber, state.verseNumber);

                        return _FlatActionButton(
                          icon: isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          label: isBookmarked
                              ? localizations.bookmarked
                              : localizations.bookmark,
                          filled: isBookmarked,
                          onTap: () {
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    localizations.tapToReadArabicMore,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
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
        color: colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMessage,
                  style: TextStyle(fontSize: 13, color: colorScheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              final settingsCubit = context.read<QuranSettingsCubit>();
              final currentTranslation =
                  settingsCubit.state.selectedTranslation;
              context.read<DailyInspirationCubit>().generateRandomAyah(
                currentTranslation,
              );
            },
            child: Text(
              localizations.tryAgain,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
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

/// Small tappable icon wrapper used in the card header row.
class _ActionIcon extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ActionIcon({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final widget = SizedBox(width: 32, height: 32, child: Center(child: child));
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: widget);
    }
    return widget;
  }
}

/// Flat text button used in the expanded inspiration card.
class _FlatActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _FlatActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fg = filled ? colorScheme.onPrimary : colorScheme.onSurface;
    final bg = filled
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
