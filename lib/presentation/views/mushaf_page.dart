import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/mushaf/mushaf_theme.dart';
import '../../data/repositories/mushaf_repository.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../service_locator.dart';
import '../blocs/mushaf/mushaf_bloc.dart';
import '../blocs/mushaf/mushaf_event.dart';
import '../blocs/mushaf/mushaf_state.dart';
import '../cubits/bookmark_cubit.dart';
import '../../core/navigation/create_reading_goal_arguments.dart';
import '../../core/navigation/route_observers.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/entities/reading_validation.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/reading_goals_cubit.dart';
import '../utils/mushaf_reading_tracker.dart';
import '../widgets/mushaf/goal_switcher_sheet.dart';
import '../widgets/mushaf/mushaf_reading_actions_sheet.dart';
import '../widgets/mushaf/mushaf_verse_actions_sheet.dart';
import '../../data/datasources/reading_preferences_data_source.dart';
import '../widgets/reading_goals/goal_completed_sheet.dart';
import '../widgets/reading_goals/reading_goal_actions.dart';
import '../widgets/snackbar.dart';
import 'create_reading_goal_page.dart';
import 'mushaf_surah_picker_page.dart';
import 'reading_goals_page.dart';

class MushafPage extends StatelessWidget {
  static const routeName = '/mushaf';

  /// Page to open instead of the last page read.
  final int? initialPage;

  const MushafPage({super.key, this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              MushafBloc(MushafRepository())
                ..add(MushafLoaded(initialPage: initialPage)),
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

class _MushafPageViewState extends State<_MushafPageView> with RouteAware {
  late final PageController _controller;
  final MushafRepository _mushafRepository = MushafRepository();
  bool _didCheckLongPressHint = false;

  late final ReadingGoalsCubit _goalsCubit;
  late final MushafReadingTracker _tracker;
  late final AppLifecycleListener _lifecycleListener;
  ModalRoute<dynamic>? _route;
  ReadingSession? _session;
  Timer? _pageViewedDebounce;

  /// The tracker only runs while both the app and this route are visible.
  bool _appVisible = true;
  bool _routeVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialPage - 1);
    WakelockPlus.enable();

    _goalsCubit = context.read<ReadingGoalsCubit>();
    final goalsCubit = _goalsCubit;
    final settings = context.read<QuranSettingsCubit>().state;
    _appVisible =
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.hidden;
    _tracker = MushafReadingTracker(
      threshold: settings.autoTrackingThreshold,
      enabled: settings.autoTrackingEnabled,
      goalId: goalsCubit.state.activeGoalId,
      isValidated: (page) =>
          goalsCubit.state.activeProgress?.isValidated(page) ?? false,
      onPageRead: _validatePageAutomatically,
      onPageTooShort: _showTooShortHint,
      visible: _appVisible,
    );
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) =>
          _setAppVisible(state == AppLifecycleState.resumed),
    );
    _openSession(goalsCubit.state.activeGoalId);
    _handlePageViewed(widget.initialPage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      if (_route != null) {
        modalRouteObserver.unsubscribe(this);
      }
      _route = route;
      if (route != null) {
        modalRouteObserver.subscribe(this, route);
      }
    }
    _maybeShowLongPressHint();
  }

  @override
  void dispose() {
    modalRouteObserver.unsubscribe(this);
    _lifecycleListener.dispose();
    _pageViewedDebounce?.cancel();
    _tracker.dispose();
    _closeSession();
    WakelockPlus.disable();
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Visibility: another route on top, or the app in the background
  // ---------------------------------------------------------------------------

  @override
  void didPushNext() => _setRouteVisible(false);

  @override
  void didPopNext() => _setRouteVisible(true);

  void _setRouteVisible(bool visible) {
    _routeVisible = visible;
    _tracker.onVisibilityChanged(_appVisible && _routeVisible);
  }

  void _setAppVisible(bool visible) {
    if (visible == _appVisible) {
      return;
    }
    _appVisible = visible;
    _tracker.onVisibilityChanged(_appVisible && _routeVisible);
    // Sessions map to foreground stretches, so a killed app leaves nothing
    // half written.
    if (visible) {
      _openSession(_tracker.goalId);
    } else {
      _closeSession();
    }
  }

  // ---------------------------------------------------------------------------
  // Pages, goals and sessions
  // ---------------------------------------------------------------------------

  void _handlePageViewed(int page) {
    _tracker.onPageChanged(page);
    _pageViewedDebounce?.cancel();
    _pageViewedDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _goalsCubit.recordPageViewed(page);
      }
    });
  }

  void _handleActiveGoalChanged(String? goalId) {
    _tracker.onGoalChanged(goalId);
    _closeSession();
    _openSession(goalId);
  }

  void _openSession(String? goalId) {
    if (goalId == null || _session != null) {
      return;
    }
    _goalsCubit.startSession(goalId).then((session) {
      if (!mounted || _tracker.goalId != goalId || _session != null) {
        return;
      }
      _session = session;
    });
  }

  void _closeSession() {
    final session = _session;
    _session = null;
    if (session == null) {
      return;
    }
    _goalsCubit.endSession(
      session,
      activeDuration: _tracker.activeTotal,
      pagesViewed: _tracker.pagesViewed,
    );
    _tracker.activeTotal = Duration.zero;
    _tracker.pagesViewed.clear();
  }

  void _validatePageAutomatically(int page) {
    final goalId = _tracker.goalId;
    if (goalId == null) {
      return;
    }
    _goalsCubit.validatePage(
      goalId,
      page,
      source: ReadingValidationSource.auto,
    );
  }

  void _showTooShortHint(int page) {
    if (!mounted) {
      return;
    }
    final localizations = AppLocalizations.of(context)!;
    CustomSnackbar.showSnackbarAction(
      context,
      localizations.pageNotCounted(page),
      () => _markPage(page),
      actionLabel: localizations.markReadShort,
    );
  }

  Future<void> _markPage(int page) async {
    final cubit = _goalsCubit;
    final goalId = cubit.state.activeGoalId;
    if (goalId == null) {
      return;
    }
    final validation = await cubit.validatePage(goalId, page);
    if (validation != null && mounted) {
      CustomSnackbar.showSuccessSnackbar(
        context,
        AppLocalizations.of(context)!.pageMarkedRead(page),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Reading actions
  // ---------------------------------------------------------------------------

  Future<void> _openReadingActions() async {
    final currentPage = context.read<MushafBloc>().state.currentPage;
    final action = await showMushafReadingActionsSheet(
      context,
      currentPage: currentPage,
    );
    if (action == null || !mounted) {
      return;
    }
    final cubit = _goalsCubit;
    final progress = cubit.state.activeProgress;
    final localizations = AppLocalizations.of(context)!;

    switch (action) {
      case MushafReadingAction.markPage:
        await _markPage(currentPage);
      case MushafReadingAction.unmarkPage:
        if (progress != null) {
          await cubit.unmarkPage(progress.goal.id, currentPage);
        }
      case MushafReadingAction.readUntilHere:
        if (progress != null) {
          await _readUntilHere(progress.goal.id, currentPage);
        }
      case MushafReadingAction.markSeveral:
        if (progress != null) {
          await ReadingGoalActions.markPages(
            context,
            progress,
            initialPage: currentPage,
          );
        }
      case MushafReadingAction.markSection:
        if (progress != null) {
          await ReadingGoalActions.markSection(
            context,
            progress,
            currentPage: currentPage,
          );
        }
      case MushafReadingAction.viewProgress:
        if (progress != null) {
          await ReadingGoalActions.openDetail(context, progress.goal.id);
        } else {
          await Navigator.pushNamed(context, ReadingGoalsPage.routeName);
        }
      case MushafReadingAction.switchGoal:
      case MushafReadingAction.followGoal:
        await _openGoalSwitcher();
      case MushafReadingAction.freeReading:
        await cubit.setActiveGoal(null);
        if (mounted) {
          CustomSnackbar.showSnackbar(context, localizations.freeReading);
        }
      case MushafReadingAction.createGoal:
        await Navigator.pushNamed(
          context,
          CreateReadingGoalPage.routeName,
          arguments: const CreateReadingGoalArguments(),
        );
    }
  }

  Future<void> _readUntilHere(String goalId, int page) async {
    final cubit = _goalsCubit;
    final localizations = AppLocalizations.of(context)!;
    final pages = cubit.pagesUntil(goalId, page);
    if (pages.isEmpty) {
      CustomSnackbar.showSnackbar(context, localizations.readUntilHereNothing);
      return;
    }
    final goalName = cubit.state.progressOf(goalId)?.goal.name ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localizations.readUntilHere,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          pages.length == 1
              ? localizations.readUntilHereConfirmSingle(page, goalName)
              : '${localizations.readUntilHereConfirm(pages.first, page, goalName)}\n'
                    '${localizations.pagesToMarkSummary(pages.length)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              localizations.confirm,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final validation = await cubit.readUntil(goalId, page);
    if (validation == null || !mounted) {
      return;
    }
    CustomSnackbar.showSnackbarAction(
      context,
      localizations.pagesMarked(validation.pages.length),
      () => cubit.undoValidation(validation.id),
      actionLabel: localizations.undo,
    );
  }

  Future<void> _openGoalSwitcher() async {
    final choice = await showGoalSwitcherSheet(context);
    if (choice == null || !mounted) {
      return;
    }
    final cubit = _goalsCubit;
    await cubit.setActiveGoal(choice.goalId);
    if (!mounted) {
      return;
    }
    final page = choice.page;
    if (page != null && page != context.read<MushafBloc>().state.currentPage) {
      context.read<MushafBloc>().add(MushafNavigateToPage(page));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MushafBloc, MushafState>(
          listenWhen: (previous, current) => current.navigateToPage != null,
          listener: (context, state) {
            final targetPage = state.navigateToPage;
            if (targetPage == null) {
              return;
            }
            _controller.jumpToPage(targetPage - 1);
          },
        ),
        BlocListener<MushafBloc, MushafState>(
          listenWhen: (previous, current) =>
              previous.currentPage != current.currentPage,
          listener: (context, state) => _handlePageViewed(state.currentPage),
        ),
        BlocListener<ReadingGoalsCubit, ReadingGoalsState>(
          listenWhen: (previous, current) =>
              previous.activeGoalId != current.activeGoalId,
          listener: (context, state) =>
              _handleActiveGoalChanged(state.activeGoalId),
        ),
        BlocListener<QuranSettingsCubit, QuranSettingsState>(
          listenWhen: (previous, current) =>
              previous.autoTrackingEnabled != current.autoTrackingEnabled ||
              previous.autoTrackingThresholdSeconds !=
                  current.autoTrackingThresholdSeconds,
          listener: (context, state) {
            _tracker.threshold = state.autoTrackingThreshold;
            _tracker.setEnabled(state.autoTrackingEnabled);
          },
        ),
      ],
      child: ReadingGoalCompletionListener(
        child: BlocBuilder<MushafBloc, MushafState>(
          buildWhen: (previous, current) =>
              previous.theme != current.theme ||
              previous.isTajweedEnabled != current.isTajweedEnabled,
          builder: (context, state) {
            final theme = state.theme;
            final mushafIsDark =
                ThemeData.estimateBrightnessForColor(
                  theme.pageBackgroundColor,
                ) ==
                Brightness.dark;
            final mushafAccentTextColor = _resolveReadableForeground(
              preferred: theme.verseTextColor,
              background: theme.pageBackgroundColor,
            );

            return Scaffold(
              backgroundColor: theme.pageBackgroundColor,
              appBar: _MushafAppBar(
                onSurahTap: _openSurahList,
                onReadingTap: _openReadingActions,
              ),
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
              bottomNavigationBar: _MushafBottomBar(
                onGoalTap: _openGoalSwitcher,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _maybeShowLongPressHint() async {
    if (_didCheckLongPressHint) {
      return;
    }
    _didCheckLongPressHint = true;

    final hasSeenHint = await _mushafRepository.getHasSeenLongPressHint();
    if (!mounted) {
      return;
    }
    if (hasSeenHint) {
      // One hint per visit: the goals hint waits for a later session.
      await _maybeShowGoalsHint();
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

  /// Once, in free reading with no goal yet, suggests creating one.
  Future<void> _maybeShowGoalsHint() async {
    final preferences = locator<ReadingPreferencesDataSource>();
    if (await preferences.getHasSeenGoalsHint() || !mounted) {
      return;
    }
    if (_goalsCubit.state.isLoading || _goalsCubit.state.hasGoals) {
      return;
    }
    await preferences.setHasSeenGoalsHint(true);
    if (!mounted) {
      return;
    }
    final localizations = AppLocalizations.of(context)!;
    final create = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.flag_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                localizations.readingGoalsHintTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.readingGoalsHintBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: Text(localizations.createReadingGoal),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(localizations.later),
              ),
            ],
          ),
        );
      },
    );
    if (create == true && mounted) {
      await Navigator.pushNamed(
        context,
        CreateReadingGoalPage.routeName,
        arguments: const CreateReadingGoalArguments(),
      );
    }
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
  final VoidCallback onReadingTap;

  const _MushafAppBar({required this.onSurahTap, required this.onReadingTap});

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
              icon: Icon(
                Icons.playlist_add_check_rounded,
                color: theme.appBarForeground,
              ),
              tooltip: localizations.readingActions,
              onPressed: onReadingTap,
            ),
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
  final VoidCallback onGoalTap;

  const _MushafBottomBar({required this.onGoalTap});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<MushafBloc, MushafState>(
      builder: (context, state) {
        final pageInfo = state.pageInfo;
        final theme = state.theme;
        final pageNumber = pageInfo?.pageNumber ?? 1;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          decoration: BoxDecoration(color: theme.bottomBarBackground),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    heightFactor: 1,
                    child: pageInfo?.hizbInfo != null
                        ? Text(
                            pageInfo!.hizbInfo!.localizedText(localizations),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.bottomBarSubtext,
                              fontSize: 12,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                _ReadingGoalIndicator(theme: theme, onTap: onGoalTap),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    heightFactor: 1,
                    child: _PageLabel(theme: theme, pageNumber: pageNumber),
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

/// Page number, with a check when the page is read in the followed goal.
class _PageLabel extends StatelessWidget {
  final MushafThemeData theme;
  final int pageNumber;

  const _PageLabel({required this.theme, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      buildWhen: (previous, current) =>
          previous.activeProgress?.isValidated(pageNumber) !=
          current.activeProgress?.isValidated(pageNumber),
      builder: (context, state) {
        final isValidated =
            state.activeProgress?.isValidated(pageNumber) ?? false;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isValidated) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: theme.bottomBarText,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              localizations.pageNumberLabel(pageNumber),
              style: TextStyle(
                color: theme.bottomBarText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Followed goal and today's quota, or "free reading"; tap to switch.
class _ReadingGoalIndicator extends StatelessWidget {
  final MushafThemeData theme;
  final VoidCallback onTap;

  const _ReadingGoalIndicator({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      builder: (context, state) {
        final progress = state.activeProgress;
        final metrics = progress?.metrics;
        final String title;
        final String? subtitle;
        if (progress == null || metrics == null) {
          title = localizations.freeReading;
          subtitle = null;
        } else {
          title =
              '${progress.goal.name} · '
              '${metrics.validatedCount}/${metrics.totalPages}';
          subtitle = metrics.isTodayTargetReached
              ? localizations.todayDoneShort
              : localizations.todayShort(
                  metrics.readToday,
                  metrics.todayTarget,
                );
        }

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.bottomBarText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: theme.bottomBarSubtext,
                    ),
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.bottomBarSubtext,
                      fontSize: 11,
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
