import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';

// Data Sources
import 'data/datasources/reciter_local_data_source.dart';
import 'data/datasources/audio_local_data_source.dart';
import 'data/datasources/database_helper.dart';
import 'data/datasources/audio_availability_local_data_source.dart';
import 'data/datasources/audio_availability_remote_data_source.dart';

// Repositories
import 'data/repositories/reciter_repository_impl.dart';
import 'data/repositories/audio_repository_impl.dart';
import 'data/repositories/download_repository_impl.dart';
import 'data/repositories/download_queue_repository_impl.dart';
import 'data/repositories/bookmark_repository_impl.dart';
import 'data/repositories/audio_availability_repository_impl.dart';
import 'domain/repositories/reciter_repository.dart';
import 'domain/repositories/audio_repository.dart';
import 'domain/repositories/download_repository.dart';
import 'domain/repositories/download_queue_repository.dart';
import 'domain/repositories/bookmark_repository.dart';
import 'domain/repositories/audio_availability_repository.dart';

// Use Cases
import 'domain/usecases/get_reciters_usecase.dart';
import 'domain/usecases/download_surah_audio_usecase.dart';
import 'domain/usecases/get_surah_audio_status_usecase.dart';
import 'domain/usecases/get_ayah_audios_usecase.dart';
import 'domain/usecases/download_management_usecases.dart';
import 'domain/usecases/get_downloaded_surahs_usecase.dart';
import 'domain/usecases/refresh_audio_availability_usecase.dart';
import 'domain/usecases/get_cached_audio_availability_usecase.dart';
import 'domain/usecases/mark_audio_updates_seen_usecase.dart';

// Services
import 'core/services/audio_player_service.dart';
import 'core/services/audio_download_queue_service.dart';
import 'core/services/quran_audio_handler.dart';
import 'data/datasources/remote_config_service.dart';

final locator = GetIt.instance;

Future<void> setupDependencies() async {
  // External dependencies
  locator.registerLazySingleton<Dio>(() => Dio());

  // Services
  final audioPlayerService = AudioPlayerService();
  await audioPlayerService.initialize();
  locator.registerSingleton<AudioPlayerService>(audioPlayerService);
  final audioHandler = await AudioService.init(
    builder: () => QuranAudioHandler(audioPlayerService),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.saliouseck.wolofquran.audio',
      androidNotificationChannelName: 'Wolof Quran Audio',
      androidNotificationIcon: 'mipmap/launcher_icon',
      androidNotificationOngoing: true,
      preloadArtwork: true,
    ),
  );
  locator.registerSingleton<AudioHandler>(audioHandler);

  // Data Sources
  locator.registerLazySingleton<ReciterLocalDataSource>(
    () => ReciterLocalDataSource(),
  );
  locator.registerLazySingleton<AudioLocalDataSource>(
    () => AudioLocalDataSource(locator<Dio>()),
  );
  locator.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  locator.registerLazySingleton<AudioAvailabilityLocalDataSource>(
    () => AudioAvailabilityLocalDataSource(),
  );
  locator.registerLazySingleton<AudioAvailabilityRemoteDataSource>(
    () => AudioAvailabilityRemoteDataSource(locator<Dio>()),
  );

  // Repositories
  locator.registerLazySingleton<ReciterRepository>(
    () => ReciterRepositoryImpl(locator<ReciterLocalDataSource>()),
  );
  locator.registerLazySingleton<AudioRepository>(
    () => AudioRepositoryImpl(locator<AudioLocalDataSource>()),
  );
  locator.registerLazySingleton<DownloadRepository>(
    () => DownloadRepositoryImpl(locator<DatabaseHelper>()),
  );
  locator.registerLazySingleton<DownloadQueueRepository>(
    () => DownloadQueueRepositoryImpl(locator<DatabaseHelper>()),
  );
  locator.registerLazySingleton<BookmarkRepository>(
    () => BookmarkRepositoryImpl(locator<DatabaseHelper>()),
  );
  locator.registerLazySingleton<AudioAvailabilityRepository>(
    () => AudioAvailabilityRepositoryImpl(
      remoteDataSource: locator<AudioAvailabilityRemoteDataSource>(),
      localDataSource: locator<AudioAvailabilityLocalDataSource>(),
    ),
  );

  // Use Cases
  locator.registerLazySingleton<GetRecitersUseCase>(
    () => GetRecitersUseCase(locator<ReciterRepository>()),
  );
  locator.registerLazySingleton<DownloadSurahAudioUseCase>(
    () => DownloadSurahAudioUseCase(locator<AudioRepository>()),
  );
  locator.registerLazySingleton<GetSurahAudioStatusUseCase>(
    () => GetSurahAudioStatusUseCase(locator<AudioRepository>()),
  );
  locator.registerLazySingleton<GetAyahAudiosUseCase>(
    () => GetAyahAudiosUseCase(locator<AudioRepository>()),
  );
  locator.registerLazySingleton<CheckSurahDownloadStatusUseCase>(
    () => CheckSurahDownloadStatusUseCase(locator<DownloadRepository>()),
  );
  locator.registerLazySingleton<MarkSurahDownloadedUseCase>(
    () => MarkSurahDownloadedUseCase(locator<DownloadRepository>()),
  );
  locator.registerLazySingleton<RemoveSurahDownloadUseCase>(
    () => RemoveSurahDownloadUseCase(locator<DownloadRepository>()),
  );
  locator.registerLazySingleton<GetDownloadedSurahsUseCase>(
    () => GetDownloadedSurahsUseCase(locator<DownloadRepository>()),
  );
  locator.registerLazySingleton<RefreshAudioAvailabilityUseCase>(
    () =>
        RefreshAudioAvailabilityUseCase(locator<AudioAvailabilityRepository>()),
  );
  locator.registerLazySingleton<GetCachedAudioAvailabilityUseCase>(
    () => GetCachedAudioAvailabilityUseCase(
      locator<AudioAvailabilityRepository>(),
    ),
  );
  locator.registerLazySingleton<MarkAudioUpdatesSeenUseCase>(
    () => MarkAudioUpdatesSeenUseCase(locator<AudioAvailabilityRepository>()),
  );

  locator.registerLazySingleton<AudioDownloadQueueService>(
    () => AudioDownloadQueueService(
      queueRepository: locator<DownloadQueueRepository>(),
      audioRepository: locator<AudioRepository>(),
      downloadRepository: locator<DownloadRepository>(),
    ),
  );

  // Remote Config
  final prefs = await SharedPreferences.getInstance();
  final remoteConfigService = RemoteConfigService(
    dio: locator<Dio>(),
    prefs: prefs,
  );
  // Non-blocking init — fetches config in background.
  remoteConfigService.init();
  locator.registerSingleton<RemoteConfigService>(remoteConfigService);
}
