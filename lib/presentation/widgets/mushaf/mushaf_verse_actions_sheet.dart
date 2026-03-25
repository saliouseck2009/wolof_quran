import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../domain/entities/bookmark.dart';
import '../../../domain/repositories/bookmark_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../service_locator.dart';
import '../../cubits/bookmark_cubit.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../ayah_play_button.dart';
import '../daily_inspiration_share_modal.dart';

class MushafVerseActionsSheet extends StatelessWidget {
  final BuildContext pageContext;
  final int surahNumber;
  final int verseNumber;
  final BookmarkCubit bookmarkCubit;

  const MushafVerseActionsSheet({
    super.key,
    required this.pageContext,
    required this.surahNumber,
    required this.verseNumber,
    required this.bookmarkCubit,
  });

  static void show(
    BuildContext context, {
    required int surahNumber,
    required int verseNumber,
  }) {
    BookmarkCubit? resolvedBookmarkCubit;
    var shouldDisposeCubit = false;

    try {
      resolvedBookmarkCubit = context.read<BookmarkCubit>();
    } catch (_) {
      resolvedBookmarkCubit = BookmarkCubit(locator<BookmarkRepository>())
        ..loadBookmarks();
      shouldDisposeCubit = true;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MushafVerseActionsSheet(
          pageContext: context,
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          bookmarkCubit: resolvedBookmarkCubit!,
        );
      },
    ).whenComplete(() async {
      if (shouldDisposeCubit) {
        await resolvedBookmarkCubit?.close();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final translation = pageContext
        .read<QuranSettingsCubit>()
        .state
        .selectedTranslation;
    final translationSource =
        QuranSettingsCubit.getTranslationOption(translation)?.displayName ??
        localizations.translation;
    final surahNameEnglish = quran.getSurahName(surahNumber);
    final surahNameArabic = quran.getSurahNameArabic(surahNumber);
    final arabicText = quran.getVerse(
      surahNumber,
      verseNumber,
      verseEndSymbol: false,
    );
    final translatedText = quran.getVerseTranslation(
      surahNumber,
      verseNumber,
      translation: translation,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: BlocBuilder<BookmarkCubit, BookmarkState>(
            bloc: bookmarkCubit,
            builder: (context, bookmarkState) {
              final isBookmarked = bookmarkCubit.isBookmarked(
                surahNumber,
                verseNumber,
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$surahNameArabic • ${localizations.surah} $surahNumber:${verseNumber.toString()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          arabicText,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontFamily: 'Hafs',
                            height: 1.8,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (translatedText.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            translatedText,
                            textAlign: TextAlign.justify,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _ActionTile(
                          label: localizations.play,
                          child: AyahPlayButton(
                            surahNumber: surahNumber,
                            ayahNumber: verseNumber,
                            surahName: surahNameEnglish,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          label: isBookmarked
                              ? localizations.bookmarked
                              : localizations.bookmark,
                          icon: isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                          iconColor: isBookmarked ? colorScheme.primary : null,
                          onTap: () async {
                            final bookmark = BookmarkedAyah(
                              surahNumber: surahNumber,
                              verseNumber: verseNumber,
                              surahName: surahNameEnglish,
                              arabicText: arabicText,
                              translation: translatedText,
                              translationSource: translationSource,
                              createdAt: DateTime.now(),
                            );
                            await bookmarkCubit.toggleBookmark(bookmark);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          label: localizations.shareAyah,
                          icon: Icons.share_outlined,
                          onTap: () {
                            Navigator.of(context).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!pageContext.mounted) {
                                return;
                              }
                              showDailyInspirationShareModal(
                                pageContext,
                                verseNumber,
                                arabicText,
                                translatedText,
                                translationSource,
                                surahNameEnglish,
                                surahNumber,
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? child;

  const _ActionTile({
    required this.label,
    this.icon,
    this.iconColor,
    this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child:
                      child ??
                      Icon(
                        icon,
                        size: 28,
                        color: iconColor ?? colorScheme.primary,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
