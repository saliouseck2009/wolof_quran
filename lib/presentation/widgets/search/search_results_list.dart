import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/surah_detail_arguments.dart';
import '../../../domain/entities/bookmark.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/search_cubit.dart';
import '../../cubits/bookmark_cubit.dart' as bookmark_cubit;
import '../ayah_card.dart';
import '../ayah_play_button.dart';
import 'search_no_results_view.dart';

class SearchResultsList extends StatelessWidget {
  const SearchResultsList({super.key, required this.state});

  final SearchLoaded state;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final accentGreen = colorScheme.primary;
    final contentColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    if (state.results.isEmpty) {
      return const SearchNoResultsView();
    }

    final surahSections = _groupResultsBySurah(state.results);

    return Column(
      children: [
        _ResultsSummary(
          contentColor: contentColor,
          localizations: localizations,
          state: state,
        ),
        Expanded(
          child: CustomScrollView(
            key: const PageStorageKey<String>('search-results-list'),
            slivers: [
              for (final section in surahSections)
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
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final result = section.results[index];
                        return AyahCard(
                          verseNumber: result.verseNumber,
                          arabicText: result.arabicText,
                          translationSource: state.translationSource,
                          translation: result.translation,
                          surahNumber: result.surahNumber,
                          surahName: result.surahName,
                          actions: [
                            AyahPlayButton(
                              surahNumber: result.surahNumber,
                              ayahNumber: result.verseNumber,
                              surahName: result.surahName,
                            ),
                            IconButton(
                              icon:
                                  BlocBuilder<
                                    bookmark_cubit.BookmarkCubit,
                                    bookmark_cubit.BookmarkState
                                  >(
                                    builder: (context, bookmarkState) {
                                      final isBookmarked = context
                                          .read<bookmark_cubit.BookmarkCubit>()
                                          .isBookmarked(
                                            result.surahNumber,
                                            result.verseNumber,
                                          );

                                      return Icon(
                                        isBookmarked
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: isBookmarked
                                            ? colorScheme.primary
                                            : colorScheme.outline,
                                        size: 20,
                                      );
                                    },
                                  ),
                              onPressed: () {
                                final bookmarkCubit = context
                                    .read<bookmark_cubit.BookmarkCubit>();
                                final bookmark = BookmarkedAyah(
                                  surahNumber: result.surahNumber,
                                  verseNumber: result.verseNumber,
                                  surahName: result.surahName,
                                  arabicText: result.arabicText,
                                  translation: result.translation,
                                  translationSource: state.translationSource,
                                  createdAt: DateTime.now(),
                                );

                                bookmarkCubit.toggleBookmark(bookmark);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.open_in_new,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/surah-detail',
                                  arguments: SurahDetailArguments(
                                    surahNumber: result.surahNumber,
                                    initialAyahNumber: result.verseNumber,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }, childCount: section.results.length),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<_SurahSection> _groupResultsBySurah(List<SearchResult> results) {
    final sections = <_SurahSection>[];
    _SurahSection? currentSection;

    for (final result in results) {
      if (currentSection == null ||
          currentSection.surahNumber != result.surahNumber) {
        currentSection = _SurahSection(
          surahNumber: result.surahNumber,
          surahName: result.surahName,
          results: [result],
        );
        sections.add(currentSection);
      } else {
        currentSection.results.add(result);
      }
    }

    return sections;
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({
    required this.contentColor,
    required this.localizations,
    required this.state,
  });

  final Color contentColor;
  final AppLocalizations localizations;
  final SearchLoaded state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: contentColor),
          const SizedBox(width: 8),
          Text(
            localizations.foundOccurrences(
              state.totalOccurrences,
              state.results.length,
            ),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({
    required this.accentGreen,
    required this.colorScheme,
    required this.isDark,
    required this.surahName,
    required this.surahNumber,
  });

  final Color accentGreen;
  final ColorScheme colorScheme;
  final bool isDark;
  final String surahName;
  final int surahNumber;

  static const double extent = 76;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainer
              : accentGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$surahNumber',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? colorScheme.onPrimary : accentGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              surahName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SurahHeaderDelegate extends SliverPersistentHeaderDelegate {
  const SurahHeaderDelegate({
    required this.accentGreen,
    required this.colorScheme,
    required this.isDark,
    required this.surahName,
    required this.surahNumber,
  });

  final Color accentGreen;
  final ColorScheme colorScheme;
  final bool isDark;
  final String surahName;
  final int surahNumber;

  @override
  double get minExtent => _SurahHeader.extent;

  @override
  double get maxExtent => _SurahHeader.extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _SurahHeader(
        accentGreen: accentGreen,
        colorScheme: colorScheme,
        isDark: isDark,
        surahName: surahName,
        surahNumber: surahNumber,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SurahHeaderDelegate oldDelegate) {
    return surahName != oldDelegate.surahName ||
        surahNumber != oldDelegate.surahNumber ||
        accentGreen != oldDelegate.accentGreen ||
        colorScheme != oldDelegate.colorScheme ||
        isDark != oldDelegate.isDark;
  }
}

class _SurahSection {
  _SurahSection({
    required this.surahNumber,
    required this.surahName,
    required this.results,
  });

  final int surahNumber;
  final String surahName;
  final List<SearchResult> results;
}
