import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolof_quran/presentation/cubits/audio_management_cubit.dart';
import 'package:wolof_quran/presentation/cubits/daily_inspiration_cubit.dart';
import '../../core/layout/breakpoints.dart';
import '../../core/layout/content_constraint.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/bookmark_cubit.dart';
import '../cubits/reading_goals_cubit.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../service_locator.dart';
import '../widgets/home_header.dart';
import '../widgets/daily_inspiration_card.dart';
import '../widgets/home_actions_grid.dart';
import '../widgets/reading_goals/home_reading_card.dart';
import '../utils/audio_error_formatter.dart';
import '../widgets/snackbar.dart';

class HomePage extends StatelessWidget {
  static const String routeName = "/";

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsCubit = context.read<QuranSettingsCubit>();
    final currentTranslation = settingsCubit.state.selectedTranslation;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              BookmarkCubit(locator<BookmarkRepository>())..loadBookmarks(),
        ),
        BlocProvider(
          create: (context) =>
              DailyInspirationCubit()..generateRandomAyah(currentTranslation),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AudioManagementCubit, AudioManagementState>(
            listenWhen: (previous, current) =>
                current is AudioManagementError &&
                previous is! AudioManagementError,
            listener: (context, audioState) {
              final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
              if (!isCurrentRoute) return;
              if (audioState is AudioManagementError) {
                final message = formatAudioError(
                  audioState.message,
                  AppLocalizations.of(context)!,
                );
                CustomSnackbar.showErrorSnackbar(context, message, duration: 3);
              }
            },
          ),
          BlocListener<AudioManagementCubit, AudioManagementState>(
            listenWhen: (_, current) =>
                current is AudioDownloadAlreadyInProgress,
            listener: (context, audioState) {
              final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
              if (!isCurrentRoute) return;
              CustomSnackbar.showSnackbar(
                context,
                AppLocalizations.of(context)!.surahDownloadAlreadyInProgress,
                duration: 2,
              );
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: const SafeArea(child: _HomeBody()),
        ),
      ),
    );
  }
}

/// The home content, laid out for the width of the window.
///
/// Compact and medium windows stack everything in one column; an
/// expanded one (a tablet in landscape) puts the verse and the reading
/// card beside the menu, so the whole home fits without scrolling.
class _HomeBody extends StatelessWidget {
  const _HomeBody();

  static const double _margin = 24;

  @override
  Widget build(BuildContext context) {
    final sizeClass = WindowSizeClass.of(context);
    final menu = BlocSelector<ReadingGoalsCubit, ReadingGoalsState, int?>(
      selector: (state) => state.isLoading ? null : state.ongoing.length,
      builder: (context, ongoingGoals) =>
          HomeActionsGrid(ongoingGoals: ongoingGoals),
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _section(top: 16, child: const HomeHeader()),
        if (sizeClass == WindowSizeClass.expanded)
          _section(
            top: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DailyInspirationCard(),
                      SizedBox(height: 16),
                      HomeReadingCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(child: menu),
              ],
            ),
          )
        else ...[
          _section(top: 24, child: const DailyInspirationCard()),
          _section(top: 16, child: const HomeReadingCard()),
          _section(top: 24, child: menu),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _section({required double top, required Widget child}) {
    return SliverContentConstraint(
      margin: _margin,
      sliver: SliverPadding(
        padding: EdgeInsets.only(top: top),
        sliver: SliverToBoxAdapter(child: child),
      ),
    );
  }
}
