import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wolof_quran/core/helpers/bloc_observer.dart';
import 'package:wolof_quran/core/services/audio_player_service.dart';
import 'package:wolof_quran/domain/repositories/reciter_repository.dart';
import 'package:wolof_quran/domain/usecases/download_surah_audio_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_ayah_audios_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_reciters_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_surah_audio_status_usecase.dart';
import 'package:wolof_quran/presentation/cubits/audio_management_cubit.dart';
import 'package:wolof_quran/presentation/cubits/quran_settings_cubit.dart';
import 'package:wolof_quran/presentation/cubits/reciter_cubit.dart';
import 'package:wolof_quran/presentation/cubits/ayah_playback_cubit.dart';
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
  runApp(MyApp());
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
          )..initialize(),
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
                  }
                },
              ),
            ],
            child: BlocBuilder<LanguageCubit, Locale>(
              builder: (context, locale) {
                return BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    return MaterialApp(
                      title: 'Wolof Quran',
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
