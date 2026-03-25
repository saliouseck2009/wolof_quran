import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/mushaf/mushaf_theme.dart';
import '../../data/repositories/mushaf_repository.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../service_locator.dart';
import '../blocs/mushaf/mushaf_bloc.dart';
import '../blocs/mushaf/mushaf_event.dart';
import '../blocs/mushaf/mushaf_state.dart';
import '../cubits/bookmark_cubit.dart';
import '../widgets/mushaf/mushaf_page_content.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialPage - 1);
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

          return Scaffold(
            backgroundColor: theme.qcfTheme.pageBackgroundColor,
            appBar: _MushafAppBar(onSurahTap: _openSurahList),
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _controller,
                itemCount: 604,
                onPageChanged: (index) {
                  context.read<MushafBloc>().add(MushafPageChanged(index + 1));
                },
                itemBuilder: (context, index) {
                  return MushafPageContent(pageNumber: index + 1);
                },
              ),
            ),
            bottomNavigationBar: const _MushafBottomBar(),
          );
        },
      ),
    );
  }

  Future<void> _openSurahList() async {
    final surahNumber = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const MushafSurahPickerPage()),
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<MushafBloc, MushafState>(
      builder: (context, state) {
        final pageInfo = state.pageInfo;
        final theme = state.theme;

        return AppBar(
          backgroundColor: theme.appBarBackground,
          foregroundColor: theme.appBarForeground,
          centerTitle: true,
          leadingWidth: 72,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: Text(
                pageInfo != null ? 'Juz ${pageInfo.juzNumber}' : '',
                style: TextStyle(fontSize: 13, color: theme.bottomBarSubtext),
              ),
            ),
          ),
          title: GestureDetector(
            onTap: onSurahTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    pageInfo?.surahNameArabic ?? localizations.mushaf,
                    style: TextStyle(
                      fontSize: 20,
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
                  size: 20,
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final theme = themes[index];
                  final isSelected = index == selectedIndex;
                  final pageBackground = theme.qcfTheme.pageBackgroundColor;
                  final textColor = theme.qcfTheme.verseTextColor;

                  return GestureDetector(
                    onTap: () {
                      context.read<MushafBloc>().add(MushafThemeChanged(index));
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
                            ? Icon(Icons.check, color: textColor, size: 24)
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(color: theme.bottomBarBackground),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (pageInfo?.hizbInfo != null)
                  Text(
                    pageInfo!.hizbInfo!.displayText,
                    style: TextStyle(
                      color: theme.bottomBarSubtext,
                      fontSize: 13,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  localizations.pageNumberLabel(pageInfo?.pageNumber ?? 1),
                  style: TextStyle(
                    color: theme.bottomBarText,
                    fontSize: 14,
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
