import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import '../../core/mushaf/mushaf_theme.dart';
import '../../data/repositories/mushaf_repository.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../service_locator.dart';
import '../blocs/mushaf/mushaf_bloc.dart';
import '../blocs/mushaf/mushaf_event.dart';
import '../blocs/mushaf/mushaf_state.dart';
import '../cubits/bookmark_cubit.dart';
import '../widgets/mushaf/mushaf_verse_actions_sheet.dart';
import 'mushaf_surah_picker_page.dart';

class MushafPage extends StatelessWidget {
  static const routeName = '/mushaf';

  const MushafPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              MushafBloc(MushafRepository())..add(const MushafLoaded()),
        ),
        BlocProvider(
          create: (_) =>
              BookmarkCubit(locator<BookmarkRepository>())..loadBookmarks(),
        ),
      ],
      child: const _MushafView(),
    );
  }
}

class _MushafView extends StatelessWidget {
  const _MushafView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MushafBloc, MushafState>(
      buildWhen: (previous, current) => previous.isLoading != current.isLoading,
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _MushafPageView(initialPage: state.currentPage);
      },
    );
  }
}

class _MushafPageView extends StatefulWidget {
  final int initialPage;

  const _MushafPageView({required this.initialPage});

  @override
  State<_MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<_MushafPageView> {
  late final PageController _controller;
  final MushafRepository _mushafRepository = MushafRepository();
  bool _didCheckLongPressHint = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowLongPressHint();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MushafBloc, MushafState>(
      listenWhen: (previous, current) => current.navigateToPage != null,
      listener: (context, state) {
        final targetPage = state.navigateToPage;
        if (targetPage == null) {
          return;
        }
        _controller.jumpToPage(targetPage - 1);
      },
      child: BlocBuilder<MushafBloc, MushafState>(
        buildWhen: (previous, current) => previous.theme != current.theme,
        builder: (context, state) {
          final theme = state.theme;
          final mushafIsDark =
              ThemeData.estimateBrightnessForColor(theme.pageBackgroundColor) ==
              Brightness.dark;

          return Scaffold(
            backgroundColor: theme.pageBackgroundColor,
            appBar: _MushafAppBar(onSurahTap: _openSurahList),
            body: QuranPageView(
              pageController: _controller,
              highlights: const [],
              pageBackgroundColor: theme.pageBackgroundColor,
              isDarkMode: mushafIsDark,
              ayahStyle: TextStyle(color: theme.verseTextColor),
              onPageChanged: (pageNumber) {
                context.read<MushafBloc>().add(MushafPageChanged(pageNumber));
              },
              onLongPress: (surahNumber, verseNumber, details) {
                if (!mounted) {
                  return;
                }
                MushafVerseActionsSheet.show(
                  context,
                  surahNumber: surahNumber,
                  verseNumber: verseNumber,
                );
              },
            ),
            bottomNavigationBar: const _MushafBottomBar(),
          );
        },
      ),
    );
  }

  Future<void> _maybeShowLongPressHint() async {
    if (_didCheckLongPressHint) {
      return;
    }
    _didCheckLongPressHint = true;

    final hasSeenHint = await _mushafRepository.getHasSeenLongPressHint();
    if (hasSeenHint || !mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final message = _longPressHintText(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _mushafRepository.setHasSeenLongPressHint(true);
    });
  }

  String _longPressHintText(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    switch (languageCode) {
      case 'ar':
        return 'لرؤية الترجمة/التفسير للآية، اضغط مطولاً على الآية.';
      case 'en':
        return 'To view verse translation/tafsir, long-press on a verse.';
      case 'fr':
      default:
        return 'Pour voir la traduction/le tafsir d’un verset, faites un appui long sur le verset.';
    }
  }

  Future<void> _openSurahList() async {
    final currentSurahNumber = context
        .read<MushafBloc>()
        .state
        .pageInfo
        ?.primarySurahNumber;

    final surahNumber = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) =>
            MushafSurahPickerPage(currentSurahNumber: currentSurahNumber),
      ),
    );
    if (surahNumber != null && mounted) {
      context.read<MushafBloc>().add(MushafNavigateToSurah(surahNumber));
    }
  }
}

class _MushafAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSurahTap;

  const _MushafAppBar({required this.onSurahTap});

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<MushafBloc, MushafState>(
      builder: (context, state) {
        final pageInfo = state.pageInfo;
        final theme = state.theme;

        return AppBar(
          toolbarHeight: 40,
          backgroundColor: theme.appBarBackground,
          foregroundColor: theme.appBarForeground,
          centerTitle: true,
          leadingWidth: 106,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                if (Navigator.of(context).canPop())
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        CupertinoIcons.back,
                        size: 17,
                        color: theme.appBarForeground,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    pageInfo != null
                        ? localizations.juzLabel(pageInfo.juzNumber)
                        : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.bottomBarSubtext,
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: GestureDetector(
            onTap: onSurahTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${pageInfo?.primarySurahNumber} - ${pageInfo?.surahNameArabic ?? localizations.mushaf}',

                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Hafs',
                      color: theme.appBarForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: theme.appBarForeground,
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.palette_outlined, color: theme.appBarForeground),
              tooltip: localizations.theme,
              onPressed: () => _showThemePicker(context),
            ),
          ],
        );
      },
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<MushafBloc>(),
        child: const _ThemePickerSheet(),
      ),
    );
  }
}

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MushafBloc, MushafState>(
      builder: (context, state) {
        final themes = MushafThemeData.allThemes;
        final selectedIndex = state.theme.index;

        final maxHeight = MediaQuery.of(context).size.height * 0.7;

        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemCount: themes.length,
                      itemBuilder: (context, index) {
                        final theme = themes[index];
                        final isSelected = index == selectedIndex;
                        final pageBackground = theme.pageBackgroundColor;
                        final textColor = theme.verseTextColor;

                        return GestureDetector(
                          onTap: () {
                            context.read<MushafBloc>().add(
                              MushafThemeChanged(index),
                            );
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: pageBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.withAlpha(60),
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: textColor,
                                      size: 24,
                                    )
                                  : Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: textColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MushafBottomBar extends StatelessWidget {
  const _MushafBottomBar();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<MushafBloc, MushafState>(
      builder: (context, state) {
        final pageInfo = state.pageInfo;
        final theme = state.theme;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          decoration: BoxDecoration(color: theme.bottomBarBackground),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (pageInfo?.hizbInfo != null)
                  Text(
                    pageInfo!.hizbInfo!.localizedText(localizations),
                    style: TextStyle(
                      color: theme.bottomBarSubtext,
                      fontSize: 12,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  localizations.pageNumberLabel(pageInfo?.pageNumber ?? 1),
                  style: TextStyle(
                    color: theme.bottomBarText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
