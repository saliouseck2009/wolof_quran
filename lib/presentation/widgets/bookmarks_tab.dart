import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolof_quran/core/config/theme/app_color.dart';
import 'package:wolof_quran/core/navigation/surah_detail_arguments.dart';
import 'package:wolof_quran/presentation/widgets/search/search_results_list.dart';
import 'package:wolof_quran/presentation/widgets/snackbar.dart';

import '../../domain/entities/bookmark.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/bookmark_cubit.dart';
import '../widgets/ayah_card.dart';
import '../widgets/ayah_play_button.dart';

class BookmarksTab extends StatelessWidget {
  const BookmarksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final accentGreen = colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? AppColor.surfaceDark
          : colorScheme.surface,

      appBar: AppBar(
        title: Text(
          localizations.bookmarks,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? AppColor.surfaceDark
            : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocBuilder<BookmarkCubit, BookmarkState>(
        builder: (context, state) {
          if (state is BookmarkLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookmarkError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localizations.errorLoadingBookmarks,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is BookmarkLoaded) {
            if (state.bookmarks.isEmpty) {
              return _buildEmptyState(context, localizations);
            }

            final sections = _groupBookmarksBySurah(state.bookmarks);

            return Column(
              children: [
                // Header with clear all button
                if (state.bookmarks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 4,
                      top: 12,
                      bottom: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bookmark,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${state.bookmarks.length} ${localizations.bookmarks.toLowerCase()}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () =>
                              _showClearDialog(context, localizations),
                          child: Text(
                            localizations.clearAllBookmarks,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bookmarks list
                Expanded(
                  child: CustomScrollView(
                    key: const PageStorageKey<String>('bookmarks-list'),
                    slivers: [
                      for (final section in sections)
                        SliverMainAxisGroup(
                          slivers: [
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: SurahHeaderDelegate(
                                accentGreen: accentGreen,
                                colorScheme: colorScheme,
                                isDark: isDark,
                                surahName: section.surahName,
                                surahNumber: section.surahNumber,
                              ),
                              // delegate: _BookmarksSurahHeaderDelegate(
                              //   colorScheme: colorScheme,
                              //   surahName: section.surahName,
                              //   surahNumber: section.surahNumber,
                              // ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final bookmark = section.bookmarks[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: AyahCard(
                                    verseNumber: bookmark.verseNumber,
                                    arabicText: bookmark.arabicText,
                                    translationSource:
                                        bookmark.translationSource,
                                    translation: bookmark.translation,
                                    surahNumber: bookmark.surahNumber,
                                    surahName: bookmark.surahName,
                                    actions: [
                                      AyahPlayButton(
                                        surahNumber: bookmark.surahNumber,
                                        ayahNumber: bookmark.verseNumber,
                                        surahName: bookmark.surahName,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.bookmark,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          context
                                              .read<BookmarkCubit>()
                                              .removeBookmark(
                                                bookmark.surahNumber,
                                                bookmark.verseNumber,
                                              );
                                          CustomSnackbar.showSnackbar(
                                            context,
                                            localizations.bookmarkRemoved,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.open_in_new,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/surah-detail',
                                            arguments: SurahDetailArguments(
                                              surahNumber: bookmark.surahNumber,
                                              initialAyahNumber:
                                                  bookmark.verseNumber,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }, childCount: section.bookmarks.length),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.noBookmarks,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              localizations.noBookmarksDescription,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            localizations.confirmClearBookmarks,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Text(localizations.clearBookmarksMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                localizations.cancel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<BookmarkCubit>().clearAllBookmarks();
                CustomSnackbar.showSnackbar(
                  context,
                  localizations.allBookmarksCleared,
                );
              },
              child: Text(
                localizations.clear,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_BookmarkSurahSection> _groupBookmarksBySurah(
    List<BookmarkedAyah> bookmarks,
  ) {
    final sections = <_BookmarkSurahSection>[];
    _BookmarkSurahSection? currentSection;

    for (final bookmark in bookmarks) {
      if (currentSection == null ||
          currentSection.surahNumber != bookmark.surahNumber) {
        currentSection = _BookmarkSurahSection(
          surahNumber: bookmark.surahNumber,
          surahName: bookmark.surahName,
          bookmarks: [bookmark],
        );
        sections.add(currentSection);
      } else {
        currentSection.bookmarks.add(bookmark);
      }
    }

    return sections;
  }
}

class _BookmarksSurahHeader extends StatelessWidget {
  const _BookmarksSurahHeader({
    required this.colorScheme,
    required this.surahName,
    required this.surahNumber,
  });

  final ColorScheme colorScheme;
  final String surahName;
  final int surahNumber;

  static const double extent = 56;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.brightness == Brightness.dark
              ? colorScheme.surfaceContainer
              : colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.brightness == Brightness.dark
                ? colorScheme.outline.withValues(alpha: 0.1)
                : colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          '$surahNumber. $surahName',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _BookmarksSurahHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _BookmarksSurahHeaderDelegate({
    required this.colorScheme,
    required this.surahName,
    required this.surahNumber,
  });

  final ColorScheme colorScheme;
  final String surahName;
  final int surahNumber;

  @override
  double get minExtent => _BookmarksSurahHeader.extent;

  @override
  double get maxExtent => _BookmarksSurahHeader.extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _BookmarksSurahHeader(
        colorScheme: colorScheme,
        surahName: surahName,
        surahNumber: surahNumber,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _BookmarksSurahHeaderDelegate oldDelegate) {
    return surahName != oldDelegate.surahName ||
        surahNumber != oldDelegate.surahNumber ||
        colorScheme != oldDelegate.colorScheme;
  }
}

class _BookmarkSurahSection {
  _BookmarkSurahSection({
    required this.surahNumber,
    required this.surahName,
    required this.bookmarks,
  });

  final int surahNumber;
  final String surahName;
  final List<BookmarkedAyah> bookmarks;
}
