import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:wolof_quran/core/helpers/bloc_observer.dart';
import 'package:wolof_quran/core/services/audio_player_service.dart';
import 'package:wolof_quran/core/services/audio_download_queue_service.dart';
import 'package:wolof_quran/domain/repositories/reciter_repository.dart';
import 'package:wolof_quran/domain/repositories/download_repository.dart';
import 'package:wolof_quran/domain/repositories/audio_repository.dart';
import 'package:wolof_quran/domain/usecases/download_surah_audio_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_ayah_audios_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_reciters_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_surah_audio_status_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_cached_audio_availability_usecase.dart';
import 'package:wolof_quran/domain/usecases/mark_audio_updates_seen_usecase.dart';
import 'package:wolof_quran/domain/usecases/refresh_audio_availability_usecase.dart';
import 'package:wolof_quran/presentation/cubits/audio_management_cubit.dart';
import 'package:wolof_quran/presentation/cubits/audio_availability_cubit.dart';
import 'package:wolof_quran/presentation/cubits/quran_settings_cubit.dart';
import 'package:wolof_quran/presentation/cubits/reciter_cubit.dart';
import 'package:wolof_quran/presentation/cubits/ayah_playback_cubit.dart';
import 'package:wolof_quran/presentation/cubits/audio_download_queue_cubit.dart';
import 'package:wolof_quran/presentation/cubits/surah_mini_player_cubit.dart';
import 'package:wolof_quran/service_locator.dart';

import 'core/navigation/app_routes.dart';
import 'core/config/theme/theme.dart';
import 'core/config/localization/localization_service.dart';
import 'presentation/cubits/language_cubit.dart';
import 'presentation/cubits/theme_cubit.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("fr_FR");
  await setupDependencies();
  Bloc.observer = SimpleBlocObserver();
  runApp(const MyApp());
  _preloadMushafFontsInBackground();
}

void _preloadMushafFontsInBackground() {
  Future<void>(() async {
    try {
      await QcfFontLoader.setupFontsAtStartup(onProgress: (_) {});
    } catch (_) {
      // Preload is optional; ignore failures to avoid impacting app startup.
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LanguageCubit()),
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(
          create: (context) => ReciterCubit(
            getRecitersUseCase: locator<GetRecitersUseCase>(),
            reciterRepository: locator<ReciterRepository>(),
          )..loadReciters(),
        ),
        BlocProvider(
          create: (context) => AudioManagementCubit(
            downloadSurahAudioUseCase: locator<DownloadSurahAudioUseCase>(),
            getSurahAudioStatusUseCase: locator<GetSurahAudioStatusUseCase>(),
            getAyahAudiosUseCase: locator<GetAyahAudiosUseCase>(),
            audioPlayerService: locator<AudioPlayerService>(),
            downloadRepository: locator<DownloadRepository>(),
          )..initialize(),
        ),
        BlocProvider(
          lazy: false,
          create: (context) => AudioAvailabilityCubit(
            refreshAudioAvailabilityUseCase:
                locator<RefreshAudioAvailabilityUseCase>(),
            getCachedAudioAvailabilityUseCase:
                locator<GetCachedAudioAvailabilityUseCase>(),
            markAudioUpdatesSeenUseCase: locator<MarkAudioUpdatesSeenUseCase>(),
          )..refreshReciter('imamsarr'),
        ),
        BlocProvider(
          lazy: false,
          create: (context) => QuranSettingsCubit()..loadSettings(),
        ),
        // provide ayat playback
        BlocProvider(
          create: (context) => AyahPlaybackCubit(
            audioPlayerService: locator<AudioPlayerService>(),
            audioManagementCubit: context.read<AudioManagementCubit>(),
          ),
        ),
        BlocProvider(
          lazy: false,
          create: (context) => AudioDownloadQueueCubit(
            queueService: locator<AudioDownloadQueueService>(),
          ),
        ),
        BlocProvider(
          lazy: false,
          create: (context) => SurahMiniPlayerCubit(
            audioPlayerService: locator<AudioPlayerService>(),
            downloadRepository: locator<DownloadRepository>(),
            audioRepository: locator<AudioRepository>(),
          ),
        ),
      ],
      child: Builder(
        builder: (ctx) {
          return MultiBlocListener(
            listeners: [
              BlocListener<ReciterCubit, ReciterState>(
                listener: (context, reciterState) {
                  // When reciters are loaded, update the settings cubit
                  if (reciterState is ReciterLoaded) {
                    context.read<QuranSettingsCubit>().loadReciterFromPrefs(
                      reciterState.reciters,
                    );
                    context.read<AudioAvailabilityCubit>().refreshReciters(
                      reciterState.reciters
                          .map((reciter) => reciter.id)
                          .toList(),
                    );
                  }
                },
              ),
            ],
            child: BlocBuilder<LanguageCubit, Locale>(
              builder: (context, locale) {
                return BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    return MaterialApp(
                      onGenerateTitle: (context) {
                        return AppLocalizations.of(context)?.appTitle ??
                            'Wolof Quran';
                      },
                      debugShowCheckedModeBanner: false,

                      // Localization setup
                      locale: locale,
                      supportedLocales: LocalizationService.supportedLocales,
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],

                      // Theme setup
                      theme: MaterialTheme().light(),
                      darkTheme: MaterialTheme().dark(),
                      themeMode: themeMode,
                      builder: (context, child) {
                        final theme = Theme.of(context);
                        final isDark = theme.brightness == Brightness.dark;
                        final overlayStyle = isDark
                            ? SystemUiOverlayStyle.light.copyWith(
                                statusBarColor: Colors.transparent,
                                systemNavigationBarColor:
                                    theme.colorScheme.surface,
                                systemNavigationBarIconBrightness:
                                    Brightness.light,
                                statusBarIconBrightness: Brightness.light,
                                statusBarBrightness: Brightness.dark,
                              )
                            : SystemUiOverlayStyle.dark.copyWith(
                                statusBarColor: Colors.transparent,
                                systemNavigationBarColor:
                                    theme.colorScheme.surface,
                                systemNavigationBarIconBrightness:
                                    Brightness.dark,
                                statusBarIconBrightness: Brightness.dark,
                                statusBarBrightness: Brightness.light,
                              );

                        return AnnotatedRegion<SystemUiOverlayStyle>(
                          value: overlayStyle,
                          child: child ?? const SizedBox.shrink(),
                        );
                      },
                      onGenerateRoute: AppRoutes.onGenerateRoutes,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
