import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../domain/entities/bookmark.dart';
import '../../../domain/repositories/bookmark_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../service_locator.dart';
import '../../blocs/mushaf/mushaf_bloc.dart';
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
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
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mushafTheme = widget.pageContext.read<MushafBloc>().state.theme;
    final baseBackground = mushafTheme.qcfTheme.pageBackgroundColor;
    final baseText = mushafTheme.qcfTheme.verseTextColor;
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
    final settingsState = widget.pageContext.read<QuranSettingsCubit>().state;
    final selectedTranslation = settingsState.selectedTranslation;

    final surahNameEnglish = quran.getSurahName(widget.surahNumber);
    final surahNameArabic = quran.getSurahNameArabic(widget.surahNumber);
    final arabicText = quran.getVerse(
      widget.surahNumber,
      widget.verseNumber,
      verseEndSymbol: false,
    );
    final pages = _buildTranslationPages(
      localizations: localizations,
      selectedTranslation: selectedTranslation,
      surahNumber: widget.surahNumber,
      verseNumber: widget.verseNumber,
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
              widget.surahNumber,
              widget.verseNumber,
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
                Text(
                  '$surahNameArabic • ${localizations.surah} ${widget.surahNumber}:${widget.verseNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: baseText,
                  ),
                ),
                const SizedBox(height: 10),
                _StickyActionBar(
                  backgroundColor: barBackground,
                  iconColor: primaryAccent,
                  onPlay: () {},
                  playChild: AyahPlayButton(
                    surahNumber: widget.surahNumber,
                    ayahNumber: widget.verseNumber,
                    surahName: surahNameEnglish,
                    size: 24,
                  ),
                  onBookmark: () async {
                    final bookmark = BookmarkedAyah(
                      surahNumber: widget.surahNumber,
                      verseNumber: widget.verseNumber,
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
                        widget.verseNumber,
                        arabicText,
                        activePage.text,
                        activePage.title,
                        surahNameEnglish,
                        widget.surahNumber,
                      );
                    });
                  },
                  onCopy: () async {
                    final content =
                        '$surahNameArabic ($surahNameEnglish)\n'
                        '${localizations.surah} ${widget.surahNumber}:${widget.verseNumber}\n\n'
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
    final selectedText = quran.getVerseTranslation(
      surahNumber,
      verseNumber,
      translation: selectedTranslation,
    );
    pages.add(
      _TranslationPage(
        title: selectedOption?.displayName ?? localizations.translation,
        text: selectedText,
      ),
    );

    // Transliteration page is intentionally skipped when unsupported by package.
    for (final option in QuranSettingsCubit.availableTranslations) {
      if (option.translation == selectedTranslation) {
        continue;
      }
      final text = quran.getVerseTranslation(
        surahNumber,
        verseNumber,
        translation: option.translation,
      );
      if (text.trim().isEmpty) {
        continue;
      }
      pages.add(_TranslationPage(title: option.displayName, text: text));
    }

    return pages;
  }
}

class _TranslationPage {
  final String title;
  final String text;

  const _TranslationPage({required this.title, required this.text});
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child:
                child ??
                Icon(
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
