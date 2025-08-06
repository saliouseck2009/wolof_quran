import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

// Data Sources
import 'data/datasources/reciter_local_data_source.dart';
import 'data/datasources/audio_local_data_source.dart';
import 'data/datasources/database_helper.dart';

// Repositories
import 'data/repositories/reciter_repository_impl.dart';
import 'data/repositories/audio_repository_impl.dart';
import 'data/repositories/download_repository_impl.dart';
import 'domain/repositories/reciter_repository.dart';
import 'domain/repositories/audio_repository.dart';
import 'domain/repositories/download_repository.dart';

// Use Cases
import 'domain/usecases/get_reciters_usecase.dart';
import 'domain/usecases/download_surah_audio_usecase.dart';
import 'domain/usecases/get_surah_audio_status_usecase.dart';
import 'domain/usecases/get_ayah_audios_usecase.dart';
import 'domain/usecases/download_management_usecases.dart';
import 'domain/usecases/get_downloaded_surahs_usecase.dart';

// Services
import 'core/services/audio_player_service.dart';

final locator = GetIt.instance;

Future<void> setupDependencies() async {
  // External dependencies
  locator.registerLazySingleton<Dio>(() => Dio());

  // Services
  locator.registerLazySingleton<AudioPlayerService>(() {
    final service = AudioPlayerService();
    service.initialize();
    return service;
  });

  // Data Sources
  locator.registerLazySingleton<ReciterLocalDataSource>(
    () => ReciterLocalDataSource(),
  );
  locator.registerLazySingleton<AudioLocalDataSource>(
    () => AudioLocalDataSource(locator<Dio>()),
  );
  locator.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

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
}
