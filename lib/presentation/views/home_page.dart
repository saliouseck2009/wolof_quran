import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolof_quran/presentation/cubits/audio_management_cubit.dart';
import 'package:wolof_quran/presentation/cubits/daily_inspiration_cubit.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/bookmark_cubit.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../service_locator.dart';
import '../widgets/home_header.dart';
import '../widgets/daily_inspiration_card.dart';
import '../widgets/home_actions_grid.dart';
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
        ],
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  sliver: SliverToBoxAdapter(child: const HomeHeader()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  sliver: SliverToBoxAdapter(child: const DailyInspirationCard()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                  sliver: SliverToBoxAdapter(child: const HomeActionsGrid()),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
