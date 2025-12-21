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
    final localizations = AppLocalizations.of(context)!;
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
                CustomSnackbar.showErrorSnackbar(
                  context,
                  message,
                  duration: 3,
                );
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: Container(
            height: double.infinity,
            decoration: colorScheme.brightness == Brightness.dark
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surfaceContainerLowest,
                        colorScheme.surfaceDim,
                      ],
                    ),
                  )
                : null, // No gradient for light theme
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      const HomeHeader(),
                      const SizedBox(height: 32),

                      // Daily Inspiration Card (merged greeting + random ayah)
                      const DailyInspirationCard(),
                      const SizedBox(height: 32),

                      // Quick Actions Title
                      Text(
                        localizations.features,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Actions Grid
                      const HomeActionsGrid(),
                    ],
                  ),
                ),
              ),
            ),
          ), // Scaffold
        ), // MultiBlocListener
      ),
    ); // MultiBlocProvider
  }
}
