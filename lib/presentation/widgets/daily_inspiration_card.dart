import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import '../../l10n/generated/app_localizations.dart';
import '../cubits/daily_inspiration_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/bookmark_cubit.dart';
import '../../domain/entities/bookmark.dart';
import '../../core/navigation/surah_detail_arguments.dart';
import '../utils/home_card_colors.dart';
import 'ayah_play_button.dart';
import 'daily_inspiration_share_modal.dart';

/// Home card of the verse of the day, in the same white card style as the
/// reading strip and the menu: Arabic first, then the translation, and a
/// footer with Listen plus bookmark, share, another-verse and open-surah
/// icons. The card itself is not tappable: the open icon leads to the verse.
class DailyInspirationCard extends StatelessWidget {
  const DailyInspirationCard({super.key});

  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuranSettingsCubit, QuranSettingsState>(
      listenWhen: (previous, current) =>
          previous.selectedTranslation != current.selectedTranslation,
      listener: (context, settingsState) {
        context.read<DailyInspirationCubit>().updateTranslation(
          settingsState.selectedTranslation,
        );
      },
      child: BlocBuilder<DailyInspirationCubit, DailyInspirationState>(
        builder: (context, state) {
          if (state is DailyInspirationLoading) {
            return const _LoadingCard();
          } else if (state is DailyInspirationLoaded) {
            return _VerseCard(state: state);
          } else if (state is DailyInspirationError) {
            return _MessageCard(message: state.message, isError: true);
          }
          return const _MessageCard();
        },
      ),
    );
  }
}

void _drawVerse(BuildContext context) {
  final translation = context
      .read<QuranSettingsCubit>()
      .state
      .selectedTranslation;
  context.read<DailyInspirationCubit>().generateRandomAyah(translation);
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const _CardShell({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Material(
      color: homeCardColor(Theme.of(context).colorScheme),
      borderRadius: BorderRadius.circular(DailyInspirationCard._radius),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Gold "Verse of the day" label, plus an optional trailing widget.
class _CardLabel extends StatelessWidget {
  final Widget? trailing;

  const _CardLabel({this.trailing});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final gold = homeGoldInk(Theme.of(context).colorScheme);

    return Row(
      children: [
        Expanded(
          child: Text(
            localizations.verseOfTheDay,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: gold,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _VerseCard extends StatelessWidget {
  final DailyInspirationLoaded state;

  const _VerseCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final accent = homeAccentColor(colorScheme);
    final accentInk = homeAccentInk(colorScheme);
    final iconColor = colorScheme.onSurface.withValues(alpha: 0.7);

    return _CardShell(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: _CardLabel(
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${state.surahName} · ${state.verseNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: accentInk,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Text(
              state.arabicText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Hafs',
                height: 1.8,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Text(
              state.translation,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: colorScheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.onSurface.withValues(alpha: 0.07),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Takes the room left by the icons and shrinks, never overflows.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AyahPlayButton(
                    surahNumber: state.surahNumber,
                    ayahNumber: state.verseNumber,
                    surahName: state.surahName,
                    size: 18,
                    color: accentInk,
                    label: localizations.listenAction,
                    backgroundColor: accent.withValues(alpha: 0.12),
                  ),
                ),
              ),
              BlocBuilder<BookmarkCubit, BookmarkState>(
                builder: (context, _) {
                  final bookmarkCubit = context.read<BookmarkCubit>();
                  final isBookmarked = bookmarkCubit.isBookmarked(
                    state.surahNumber,
                    state.verseNumber,
                  );
                  return IconButton(
                    tooltip: isBookmarked
                        ? localizations.bookmarked
                        : localizations.bookmark,
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      size: 21,
                      color: isBookmarked ? accent : iconColor,
                    ),
                    onPressed: () => bookmarkCubit.toggleBookmark(
                      BookmarkedAyah(
                        surahNumber: state.surahNumber,
                        verseNumber: state.verseNumber,
                        surahName: state.surahName,
                        arabicText: state.arabicText,
                        translation: state.translation,
                        translationSource: _translationSourceName(
                          state.currentTranslation,
                        ),
                        createdAt: DateTime.now(),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: localizations.shareAyah,
                icon: Icon(Icons.share_outlined, size: 20, color: iconColor),
                onPressed: () => showDailyInspirationShareModal(
                  context,
                  state.verseNumber,
                  state.arabicText,
                  state.translation,
                  _translationSourceName(state.currentTranslation),
                  state.surahName,
                  state.surahNumber,
                ),
              ),
              IconButton(
                tooltip: localizations.anotherVerse,
                icon: Icon(Icons.refresh_rounded, size: 21, color: iconColor),
                onPressed: () {
                  final translation = context
                      .read<QuranSettingsCubit>()
                      .state
                      .selectedTranslation;
                  context.read<DailyInspirationCubit>().refreshAyah(
                    translation,
                  );
                },
              ),
              IconButton(
                tooltip: localizations.openSurah,
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 20,
                  color: iconColor,
                ),
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/surah-detail',
                  arguments: SurahDetailArguments(
                    surahNumber: state.surahNumber,
                    initialAyahNumber: state.verseNumber,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return _CardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardLabel(),
          const SizedBox(height: 28),
          Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: homeAccentColor(colorScheme),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localizations.loadingDailyInspiration,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Initial state (tap to draw a verse) or error state (tap to retry).
class _MessageCard extends StatelessWidget {
  final String? message;
  final bool isError;

  const _MessageCard({this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final accent = isError ? colorScheme.error : homeAccentColor(colorScheme);

    return _CardShell(
      onTap: () => _drawVerse(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(),
          const SizedBox(height: 14),
          Text(
            message ?? localizations.tapForDailyVerse,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isError
                  ? colorScheme.error
                  : colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                isError ? Icons.refresh_rounded : Icons.touch_app_outlined,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isError
                      ? localizations.tryAgain
                      : localizations.tapAnywhereToStart,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _translationSourceName(quran.Translation translation) {
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
