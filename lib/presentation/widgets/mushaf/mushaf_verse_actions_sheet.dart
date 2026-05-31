import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:quran/quran.dart' as quran;

import '../../../domain/entities/bookmark.dart';
import '../../../domain/repositories/bookmark_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../service_locator.dart';
import '../../blocs/mushaf/mushaf_bloc.dart';
import '../../blocs/mushaf/mushaf_event.dart';
import '../../cubits/bookmark_cubit.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../ayah_play_button.dart';
import '../daily_inspiration_share_modal.dart';

class MushafVerseActionsSheet extends StatefulWidget {
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

    Color? modalBackgroundColor;
    try {
      final mushafTheme = context.read<MushafBloc>().state.theme;
      final pageBackground = mushafTheme.pageBackgroundColor;
      final isDark =
          ThemeData.estimateBrightnessForColor(pageBackground) ==
          Brightness.dark;
      modalBackgroundColor = isDark
          ? Color.alphaBlend(Colors.white.withAlpha(22), pageBackground)
          : Color.alphaBlend(Colors.black.withAlpha(10), pageBackground);
    } catch (_) {
      modalBackgroundColor = null;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: modalBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: MushafVerseActionsSheet(
            pageContext: context,
            surahNumber: surahNumber,
            verseNumber: verseNumber,
            bookmarkCubit: resolvedBookmarkCubit!,
          ),
        );
      },
    ).whenComplete(() async {
      if (shouldDisposeCubit) {
        await resolvedBookmarkCubit?.close();
      }
    });
  }

  @override
  State<MushafVerseActionsSheet> createState() =>
      _MushafVerseActionsSheetState();
}

class _MushafVerseActionsSheetState extends State<MushafVerseActionsSheet> {
  late final PageController _pageController;
  late final MushafBloc _mushafBloc;
  late final QuranSettingsCubit _quranSettingsCubit;
  int _currentPage = 0;
  late int _currentSurahNumber;
  late int _currentVerseNumber;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _mushafBloc = widget.pageContext.read<MushafBloc>();
    _quranSettingsCubit = widget.pageContext.read<QuranSettingsCubit>();
    final initialReference = _normalizeVerseReference(
      widget.surahNumber,
      widget.verseNumber,
    );
    _currentSurahNumber = initialReference.surahNumber;
    _currentVerseNumber = initialReference.verseNumber;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _hasPreviousVerse {
    return !(_currentSurahNumber == 1 && _currentVerseNumber == 1);
  }

  bool get _hasNextVerse {
    final currentSurahVerseCount = quran.getVerseCount(_currentSurahNumber);
    return !(_currentSurahNumber == 114 &&
        _currentVerseNumber >= currentSurahVerseCount);
  }

  _VerseReference? _adjacentVerse({required bool next}) {
    if (next) {
      final verseCount = quran.getVerseCount(_currentSurahNumber);
      if (_currentVerseNumber < verseCount) {
        return _VerseReference(_currentSurahNumber, _currentVerseNumber + 1);
      }
      if (_currentSurahNumber < 114) {
        return _VerseReference(_currentSurahNumber + 1, 1);
      }
      return null;
    }

    if (_currentVerseNumber > 1) {
      return _VerseReference(_currentSurahNumber, _currentVerseNumber - 1);
    }
    if (_currentSurahNumber > 1) {
      final previousSurah = _currentSurahNumber - 1;
      return _VerseReference(previousSurah, quran.getVerseCount(previousSurah));
    }
    return null;
  }

  void _navigateToAdjacentVerse({required bool next}) {
    final target = _adjacentVerse(next: next);
    if (target == null) {
      return;
    }

    final previousPage = qcf.getPageNumber(
      _currentSurahNumber,
      _currentVerseNumber,
    );
    final targetPage = qcf.getPageNumber(
      target.surahNumber,
      target.verseNumber,
    );

    setState(() {
      _currentSurahNumber = target.surahNumber;
      _currentVerseNumber = target.verseNumber;
      _currentPage = 0;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    if (targetPage != previousPage) {
      _mushafBloc.add(MushafNavigateToPage(targetPage));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mushafTheme = _mushafBloc.state.theme;
    final baseBackground = mushafTheme.pageBackgroundColor;
    final baseText = mushafTheme.verseTextColor;
    final isDark =
        ThemeData.estimateBrightnessForColor(baseBackground) == Brightness.dark;
    final sheetBackground = isDark
        ? Color.alphaBlend(Colors.white.withAlpha(20), baseBackground)
        : Color.alphaBlend(Colors.black.withAlpha(12), baseBackground);
    final barBackground = isDark
        ? Color.alphaBlend(Colors.white.withAlpha(24), baseBackground)
        : Color.alphaBlend(Colors.black.withAlpha(18), baseBackground);
    final panelBackground = isDark
        ? Color.alphaBlend(Colors.white.withAlpha(28), baseBackground)
        : Color.alphaBlend(Colors.black.withAlpha(20), baseBackground);
    final outlineColor = baseText.withAlpha(100);
    final secondaryText = baseText.withAlpha(190);
    final primaryAccent = mushafTheme.appBarForeground;
    final settingsState = _quranSettingsCubit.state;
    final selectedTranslation = settingsState.selectedTranslation;

    final surahNameEnglish = quran.getSurahName(_currentSurahNumber);
    final surahNameArabic = quran.getSurahNameArabic(_currentSurahNumber);
    final arabicText = quran.getVerse(
      _currentSurahNumber,
      _currentVerseNumber,
      verseEndSymbol: false,
    );
    final pages = _buildTranslationPages(
      localizations: localizations,
      selectedTranslation: selectedTranslation,
      surahNumber: _currentSurahNumber,
      verseNumber: _currentVerseNumber,
    );
    final currentPageIndex = _currentPage.clamp(0, pages.length - 1);
    final activePage = pages[currentPageIndex];

    return Container(
      color: sheetBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: BlocBuilder<BookmarkCubit, BookmarkState>(
          bloc: widget.bookmarkCubit,
          builder: (context, bookmarkState) {
            final isBookmarked = widget.bookmarkCubit.isBookmarked(
              _currentSurahNumber,
              _currentVerseNumber,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: outlineColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: baseText),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: _hasPreviousVerse
                          ? () => _navigateToAdjacentVerse(next: false)
                          : null,
                      tooltip: localizations.previousVerse,
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: baseText,
                      disabledColor: secondaryText,
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Text(
                        '$surahNameArabic • ${localizations.surah} $_currentSurahNumber:$_currentVerseNumber',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: baseText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: _hasNextVerse
                          ? () => _navigateToAdjacentVerse(next: true)
                          : null,
                      tooltip: localizations.nextVerse,
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: baseText,
                      disabledColor: secondaryText,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _StickyActionBar(
                  backgroundColor: barBackground,
                  iconColor: primaryAccent,
                  onPlay: () {},
                  playChild: AyahPlayButton(
                    surahNumber: _currentSurahNumber,
                    ayahNumber: _currentVerseNumber,
                    surahName: surahNameEnglish,
                    size: 24,
                  ),
                  onBookmark: () async {
                    final bookmark = BookmarkedAyah(
                      surahNumber: _currentSurahNumber,
                      verseNumber: _currentVerseNumber,
                      surahName: surahNameEnglish,
                      arabicText: arabicText,
                      translation: activePage.text,
                      translationSource: activePage.title,
                      createdAt: DateTime.now(),
                    );
                    await widget.bookmarkCubit.toggleBookmark(bookmark);
                  },
                  onShare: () {
                    Navigator.of(context).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!widget.pageContext.mounted) {
                        return;
                      }
                      showDailyInspirationShareModal(
                        widget.pageContext,
                        _currentVerseNumber,
                        arabicText,
                        activePage.text,
                        activePage.title,
                        surahNameEnglish,
                        _currentSurahNumber,
                      );
                    });
                  },
                  onCopy: () async {
                    final content =
                        '$surahNameArabic ($surahNameEnglish)\n'
                        '${localizations.surah} $_currentSurahNumber:$_currentVerseNumber\n\n'
                        '${activePage.title}\n'
                        '${activePage.text}';
                    await Clipboard.setData(
                      ClipboardData(text: content.trim()),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.copyLabel)),
                    );
                  },
                  isBookmarked: isBookmarked,
                  tooltipPlay: localizations.play,
                  tooltipBookmark: isBookmarked
                      ? localizations.bookmarked
                      : localizations.bookmark,
                  tooltipShare: localizations.shareAyah,
                  tooltipCopy: localizations.copyLabel,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: panelBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activePage.title,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: primaryAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${currentPageIndex + 1}/${pages.length}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (pages.length > 1)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(pages.length, (index) {
                                final isActive = index == currentPageIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: isActive ? 18 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? primaryAccent
                                        : outlineColor,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                );
                              }),
                            ),
                          ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              if (!mounted) {
                                return;
                              }
                              setState(() => _currentPage = index);
                            },
                            itemCount: pages.length,
                            itemBuilder: (context, index) {
                              final page = pages[index];
                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  0,
                                  14,
                                  14,
                                ),
                                child: SelectableText(
                                  page.text,
                                  textAlign: TextAlign.justify,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: secondaryText,
                                    height: 1.5,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_TranslationPage> _buildTranslationPages({
    required AppLocalizations localizations,
    required quran.Translation selectedTranslation,
    required int surahNumber,
    required int verseNumber,
  }) {
    final pages = <_TranslationPage>[];

    final selectedOption = QuranSettingsCubit.getTranslationOption(
      selectedTranslation,
    );
    final selectedText = _tryGetVerseTranslation(
      surahNumber,
      verseNumber,
      translation: selectedTranslation,
    );
    if (selectedText != null && selectedText.trim().isNotEmpty) {
      pages.add(
        _TranslationPage(
          title: selectedOption?.displayName ?? localizations.translation,
          text: selectedText,
        ),
      );
    }

    // Transliteration page is intentionally skipped when unsupported by package.
    for (final option in QuranSettingsCubit.availableTranslations) {
      if (option.translation == selectedTranslation) {
        continue;
      }
      final text = _tryGetVerseTranslation(
        surahNumber,
        verseNumber,
        translation: option.translation,
      );
      if (text == null || text.trim().isEmpty) {
        continue;
      }
      pages.add(_TranslationPage(title: option.displayName, text: text));
    }

    if (pages.isEmpty) {
      pages.add(
        _TranslationPage(
          title: localizations.translation,
          text: quran.getVerse(surahNumber, verseNumber, verseEndSymbol: false),
        ),
      );
    }

    return pages;
  }

  String? _tryGetVerseTranslation(
    int surahNumber,
    int verseNumber, {
    required quran.Translation translation,
  }) {
    if (!_isValidVerseReference(surahNumber, verseNumber)) {
      return null;
    }
    try {
      return quran.getVerseTranslation(
        surahNumber,
        verseNumber,
        translation: translation,
      );
    } catch (_) {
      return null;
    }
  }

  _VerseReference _normalizeVerseReference(int surahNumber, int verseNumber) {
    final normalizedSurah = surahNumber.clamp(1, 114);
    final verseCount = quran.getVerseCount(normalizedSurah);
    final normalizedVerse = verseNumber.clamp(1, verseCount);
    return _VerseReference(normalizedSurah, normalizedVerse);
  }

  bool _isValidVerseReference(int surahNumber, int verseNumber) {
    if (surahNumber < 1 || surahNumber > 114) {
      return false;
    }
    final verseCount = quran.getVerseCount(surahNumber);
    return verseNumber >= 1 && verseNumber <= verseCount;
  }
}

class _TranslationPage {
  final String title;
  final String text;

  const _TranslationPage({required this.title, required this.text});
}

class _VerseReference {
  final int surahNumber;
  final int verseNumber;

  const _VerseReference(this.surahNumber, this.verseNumber);
}

class _StickyActionBar extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPlay;
  final Widget playChild;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final bool isBookmarked;
  final String tooltipPlay;
  final String tooltipBookmark;
  final String tooltipShare;
  final String tooltipCopy;

  const _StickyActionBar({
    required this.backgroundColor,
    required this.iconColor,
    required this.onPlay,
    required this.playChild,
    required this.onBookmark,
    required this.onShare,
    required this.onCopy,
    required this.isBookmarked,
    required this.tooltipPlay,
    required this.tooltipBookmark,
    required this.tooltipShare,
    required this.tooltipCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Tooltip(
            message: tooltipPlay,
            child: _IconActionButton(onTap: onPlay, child: playChild),
          ),
          Tooltip(
            message: tooltipBookmark,
            child: _IconActionButton(
              onTap: onBookmark,
              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              iconColor: isBookmarked ? iconColor : iconColor.withAlpha(210),
            ),
          ),
          Tooltip(
            message: tooltipShare,
            child: _IconActionButton(
              onTap: onShare,
              icon: Icons.share_outlined,
              iconColor: iconColor,
            ),
          ),
          Tooltip(
            message: tooltipCopy,
            child: _IconActionButton(
              onTap: onCopy,
              icon: Icons.copy_outlined,
              iconColor: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;
  final Widget? child;

  const _IconActionButton({
    required this.onTap,
    this.icon,
    this.iconColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackColorScheme = Theme.of(context).colorScheme;

    // When a custom child is provided (e.g. AyahPlayButton), render it
    // directly without an outer InkWell so the child's own tap handler works.
    if (child != null) {
      return SizedBox(width: 44, height: 44, child: Center(child: child));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: iconColor ?? fallbackColorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
