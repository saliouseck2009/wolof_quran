import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
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
        buildWhen: (previous, current) =>
            previous.theme != current.theme ||
            previous.isTajweedEnabled != current.isTajweedEnabled,
        builder: (context, state) {
          final theme = state.theme;
          final mushafIsDark =
              ThemeData.estimateBrightnessForColor(theme.pageBackgroundColor) ==
              Brightness.dark;
          final mushafAccentTextColor = _resolveReadableForeground(
            preferred: theme.verseTextColor,
            background: theme.pageBackgroundColor,
          );

          return Scaffold(
            backgroundColor: theme.pageBackgroundColor,
            appBar: _MushafAppBar(onSurahTap: _openSurahList),
            body: QuranPageView(
              pageController: _controller,
              highlights: const [],
              pageBackgroundColor: theme.pageBackgroundColor,
              isDarkMode: mushafIsDark,
              isTajweed: state.isTajweedEnabled,
              ayahStyle: TextStyle(color: theme.verseTextColor),
              surahHeaderBuilder: (context, surahNumber) {
                return _MushafSurahHeader(
                  surahNumber: surahNumber,
                  textColor: mushafAccentTextColor,
                );
              },
              basmallahBuilder: (context, surahNumber) {
                return _MushafBasmallah(
                  surahNumber: surahNumber,
                  textColor: mushafAccentTextColor,
                );
              },
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

      final hint = _mushafHintContent(context);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          final textTheme = Theme.of(sheetContext).textTheme;
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hint.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(hint.longPressMessage, style: textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(hint.tajweedMessage, style: textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(hint.actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      await _mushafRepository.setHasSeenLongPressHint(true);
    });
  }

  _MushafHintContent _mushafHintContent(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    switch (languageCode) {
      case 'ar':
        return const _MushafHintContent(
          title: 'معلومة سريعة',
          longPressMessage:
              'لعرض الترجمة/التفسير لأي آية، اضغط مطولاً على الآية.',
          tajweedMessage:
              'ميزة جديدة: يمكنك الآن تفعيل/تعطيل ألوان التجويد من قائمة مظهر المصحف.',
          actionLabel: 'حسنًا',
        );
      case 'en':
        return const _MushafHintContent(
          title: 'Quick tip',
          longPressMessage:
              'To view verse translation/tafsir, long-press on a verse.',
          tajweedMessage:
              'New: Tajweed coloring is now available and can be enabled/disabled from the Mushaf theme panel.',
          actionLabel: 'Got it',
        );
      case 'fr':
      default:
        return const _MushafHintContent(
          title: 'Astuce rapide',
          longPressMessage:
              'Pour voir la traduction/le tafsir d’un verset, faites un appui long sur le verset.',
          tajweedMessage:
              'Nouveau: l’affichage Tajweed est disponible et peut être activé/désactivé dans le panneau de thème du Mushaf.',
          actionLabel: 'Compris',
        );
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
        final isDarkStatusBar =
            ThemeData.estimateBrightnessForColor(theme.appBarBackground) ==
            Brightness.dark;
        final overlayStyle = isDarkStatusBar
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: theme.appBarBackground,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: theme.appBarBackground,
              );

        return AppBar(
          toolbarHeight: 40,
          backgroundColor: theme.appBarBackground,
          foregroundColor: theme.appBarForeground,
          systemOverlayStyle: overlayStyle,
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
        final localizations = AppLocalizations.of(context)!;
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
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: state.isTajweedEnabled,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white,
                      activeThumbColor: state.theme.appBarForeground,
                      inactiveThumbColor: state.theme.bottomBarSubtext,
                      onChanged: (enabled) {
                        context.read<MushafBloc>().add(
                          MushafTajweedToggled(enabled),
                        );
                      },
                      title: Text(
                        localizations.tajweedColoring,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(localizations.tajweedColoringDescription),
                    ),
                    const SizedBox(height: 12),
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

class _MushafHintContent {
  final String title;
  final String longPressMessage;
  final String tajweedMessage;
  final String actionLabel;

  const _MushafHintContent({
    required this.title,
    required this.longPressMessage,
    required this.tajweedMessage,
    required this.actionLabel,
  });
}

class _MushafSurahHeader extends StatelessWidget {
  const _MushafSurahHeader({
    required this.surahNumber,
    required this.textColor,
  });

  final int surahNumber;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    const imagePath = 'assets/surah_banner.png';

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final headerWidth = availableWidth * 0.9;
        final dynamicFontSize = headerWidth * 0.085;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image(
                image: const AssetImage(imagePath, package: 'qcf_quran_plus'),
                width: headerWidth,
                fit: BoxFit.contain,
              ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: '$surahNumber',
                  style: QuranTextStyles.surahHeaderStyle(
                    fontSize: dynamicFontSize,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MushafBasmallah extends StatelessWidget {
  const _MushafBasmallah({required this.surahNumber, required this.textColor});

  final int surahNumber;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final basmallahText = surahNumber == 97 || surahNumber == 95
        ? '齃𧻓𥳐龎'
        : '齃𧻓𥳐𥉉';

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          basmallahText,
          style: QuranTextStyles.basmallahStyle(fontSize: 20, color: textColor),
        ),
      ),
    );
  }
}

Color _resolveReadableForeground({
  required Color preferred,
  required Color background,
  double minContrast = 3.0,
}) {
  if (_contrastRatio(preferred, background) >= minContrast) {
    return preferred;
  }

  final darkCandidate = const Color(0xFF111111);
  final lightCandidate = const Color(0xFFF5F5F5);
  return _contrastRatio(darkCandidate, background) >=
          _contrastRatio(lightCandidate, background)
      ? darkCandidate
      : lightCandidate;
}

double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}
