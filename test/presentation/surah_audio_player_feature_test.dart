import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wolof_quran/core/services/audio_player_service.dart';
import 'package:wolof_quran/data/models/downloaded_surah.dart';
import 'package:wolof_quran/domain/entities/audio_availability_snapshot.dart';
import 'package:wolof_quran/domain/entities/ayah_audio.dart';
import 'package:wolof_quran/domain/entities/reciter.dart';
import 'package:wolof_quran/domain/entities/surah_audio_status.dart';
import 'package:wolof_quran/domain/repositories/audio_availability_repository.dart';
import 'package:wolof_quran/domain/repositories/audio_repository.dart';
import 'package:wolof_quran/domain/repositories/download_repository.dart';
import 'package:wolof_quran/domain/usecases/download_surah_audio_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_ayah_audios_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_cached_audio_availability_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_downloaded_surahs_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_surah_audio_status_usecase.dart';
import 'package:wolof_quran/domain/usecases/mark_audio_updates_seen_usecase.dart';
import 'package:wolof_quran/domain/usecases/refresh_audio_availability_usecase.dart';
import 'package:wolof_quran/l10n/generated/app_localizations.dart';
import 'package:wolof_quran/presentation/cubits/audio_availability_cubit.dart';
import 'package:wolof_quran/presentation/cubits/audio_management_cubit.dart';
import 'package:wolof_quran/presentation/cubits/quran_settings_cubit.dart';
import 'package:wolof_quran/presentation/cubits/surah_mini_player_cubit.dart';
import 'package:wolof_quran/presentation/views/surah_audio_list_page.dart';
import 'package:wolof_quran/presentation/widgets/audio/surah_mini_player_overlay.dart';
import 'package:wolof_quran/presentation/widgets/home_actions_grid.dart';
import 'package:wolof_quran/service_locator.dart';

class _ConfigurableDownloadRepository implements DownloadRepository {
  final Map<String, List<DownloadedSurah>> downloadedByReciter;

  _ConfigurableDownloadRepository({Map<String, List<DownloadedSurah>>? seed})
    : downloadedByReciter = seed ?? {};

  @override
  Future<DownloadedSurah?> getDownloadedSurah(
    String reciterId,
    int surahNumber,
  ) async {
    final surahs = downloadedByReciter[reciterId] ?? const [];
    for (final surah in surahs) {
      if (surah.surahNumber == surahNumber) {
        return surah;
      }
    }
    return null;
  }

  @override
  Future<List<DownloadedSurah>> getDownloadedSurahs(String reciterId) async {
    return List<DownloadedSurah>.from(
      downloadedByReciter[reciterId] ?? const [],
    );
  }

  @override
  Future<Map<String, int>> getDownloadStats(String reciterId) async {
    final items = downloadedByReciter[reciterId] ?? const [];
    final completed = items.where((item) => item.isComplete).length;
    return {'total': items.length, 'completed': completed};
  }

  @override
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    final surah = await getDownloadedSurah(reciterId, surahNumber);
    return surah?.isComplete ?? false;
  }

  @override
  Future<void> markSurahAsDownloaded(
    String reciterId,
    int surahNumber,
    String filePath,
  ) async {
    final current = List<DownloadedSurah>.from(
      downloadedByReciter[reciterId] ?? const [],
    );
    current.removeWhere((item) => item.surahNumber == surahNumber);
    current.add(
      DownloadedSurah(
        reciterId: reciterId,
        surahNumber: surahNumber,
        filePath: filePath,
        isComplete: true,
      ),
    );
    downloadedByReciter[reciterId] = current;
  }

  @override
  Future<void> markSurahAsInProgress(
    String reciterId,
    int surahNumber,
    String filePath,
  ) async {
    final current = List<DownloadedSurah>.from(
      downloadedByReciter[reciterId] ?? const [],
    );
    current.removeWhere((item) => item.surahNumber == surahNumber);
    current.add(
      DownloadedSurah(
        reciterId: reciterId,
        surahNumber: surahNumber,
        filePath: filePath,
        isComplete: false,
      ),
    );
    downloadedByReciter[reciterId] = current;
  }

  @override
  Future<void> removeSurahDownload(String reciterId, int surahNumber) async {
    final current = List<DownloadedSurah>.from(
      downloadedByReciter[reciterId] ?? const [],
    );
    current.removeWhere((item) => item.surahNumber == surahNumber);
    downloadedByReciter[reciterId] = current;
  }
}

class _FakeAudioRepository implements AudioRepository {
  @override
  Future<void> deleteSurahAudio(String reciterId, int surahNumber) async {}

  @override
  Future<void> downloadSurahAudio(
    String reciterId,
    int surahNumber, {
    Function(double p1)? onProgress,
  }) async {}

  @override
  Future<List<AyahAudio>> getAyahAudios(
    String reciterId,
    int surahNumber,
  ) async {
    return List<AyahAudio>.generate(
      3,
      (index) => AyahAudio(
        surahNumber: surahNumber,
        ayahNumber: index + 1,
        reciterId: reciterId,
        localPath: '/tmp/$reciterId/$surahNumber-${index + 1}.mp3',
      ),
    );
  }

  @override
  Future<List<int>> getDownloadedSurahs(String reciterId) async {
    return const [];
  }

  @override
  Future<String> getSurahAudioPath(String reciterId, int surahNumber) async {
    return '/tmp/$reciterId/$surahNumber';
  }

  @override
  Future<void> warmUpAyahDurations(String reciterId, int surahNumber) async {}

  @override
  Future<SurahAudioStatus> getSurahAudioStatus(
    String reciterId,
    int surahNumber,
  ) async {
    return SurahAudioStatus(reciterId: reciterId, surahNumber: surahNumber);
  }

  @override
  Future<bool> isSurahAudioDownloaded(String reciterId, int surahNumber) async {
    return false;
  }
}

class _InMemoryAudioAvailabilityRepository
    implements AudioAvailabilityRepository {
  final Map<String, AudioAvailabilitySnapshot> _storage;

  _InMemoryAudioAvailabilityRepository(List<AudioAvailabilitySnapshot> values)
    : _storage = {for (final value in values) value.reciterId: value};

  @override
  Future<AudioAvailabilitySnapshot?> getCachedSnapshot(String reciterId) async {
    return _storage[reciterId];
  }

  @override
  Future<AudioAvailabilitySnapshot?> markUpdatesAsSeen(String reciterId) async {
    final snapshot = _storage[reciterId];
    if (snapshot == null) {
      return null;
    }
    final updated = snapshot.copyWith(unreadNewSurahs: const []);
    _storage[reciterId] = updated;
    return updated;
  }

  @override
  Future<AudioAvailabilitySnapshot> refreshSnapshot(
    String reciterId, {
    bool force = false,
    Duration ttl = const Duration(hours: 6),
  }) async {
    return _storage.putIfAbsent(
      reciterId,
      () => AudioAvailabilitySnapshot(
        reciterId: reciterId,
        catalogVersion: 1,
        availableSurahs: const [],
        unreadNewSurahs: const [],
        lastCheckedAt: DateTime.now(),
      ),
    );
  }
}

class _TestQuranSettingsCubit extends QuranSettingsCubit {
  void setSelectedReciter(Reciter reciter) {
    emit(state.copyWith(selectedReciter: reciter));
  }
}

class _SpyAudioManagementCubit extends AudioManagementCubit {
  int downloadCallCount = 0;
  int loadAyahAudiosCallCount = 0;
  int playSurahCallCount = 0;
  String? lastReciterId;
  int? lastSurahNumber;

  _SpyAudioManagementCubit({
    required AudioRepository audioRepository,
    required super.downloadRepository,
  }) : super(
         downloadSurahAudioUseCase: DownloadSurahAudioUseCase(audioRepository),
         getSurahAudioStatusUseCase: GetSurahAudioStatusUseCase(
           audioRepository,
         ),
         getAyahAudiosUseCase: GetAyahAudiosUseCase(audioRepository),
         audioPlayerService: AudioPlayerService(),
       ) {
    initialize();
  }

  @override
  Future<void> downloadSurahAudio(String reciterId, int surahNumber) async {
    downloadCallCount += 1;
    lastReciterId = reciterId;
    lastSurahNumber = surahNumber;
  }

  @override
  Future<void> loadAyahAudios(String reciterId, int surahNumber) async {
    loadAyahAudiosCallCount += 1;
    lastReciterId = reciterId;
    lastSurahNumber = surahNumber;
  }

  @override
  Future<void> playSurahPlaylist(
    String reciterId,
    int surahNumber, {
    String? surahName,
    int startAyahIndex = 0,
  }) async {
    playSurahCallCount += 1;
    lastReciterId = reciterId;
    lastSurahNumber = surahNumber;
  }

  void emitDownloading({
    required String reciterId,
    required int surahNumber,
    required double progress,
  }) {
    final loaded = state is AudioManagementLoaded
        ? state as AudioManagementLoaded
        : const AudioManagementLoaded(surahStatusMap: {}, ayahAudiosMap: {});
    emit(
      AudioDownloading(
        reciterId: reciterId,
        surahNumber: surahNumber,
        progress: progress,
        previousSurahStatusMap: loaded.surahStatusMap,
        previousAyahAudiosMap: loaded.ayahAudiosMap,
      ),
    );
  }
}

class _SpySurahMiniPlayerCubit extends SurahMiniPlayerCubit {
  int attachCallCount = 0;

  _SpySurahMiniPlayerCubit({
    required super.audioPlayerService,
    required super.downloadRepository,
    required super.audioRepository,
  }) : super();

  void showForTest({
    required int surahNumber,
    String surahName = 'Al-Fatihah',
    bool expanded = true,
    bool isSeekReady = true,
  }) {
    emit(
      SurahMiniPlayerState(
        uiState: expanded
            ? SurahMiniPlayerUiState.expanded
            : SurahMiniPlayerUiState.collapsed,
        reciterId: 'imamsarr',
        surahNumber: surahNumber,
        surahName: surahName,
        downloadedQueue: const [1, 2, 3],
        playerState: AudioPlayerState.playing,
        position: const Duration(seconds: 5),
        duration: const Duration(minutes: 2),
        isSeekReady: isSeekReady,
        repeatSurah: false,
      ),
    );
  }

  @override
  Future<void> attachToCurrentPlayback({bool expanded = true}) async {
    attachCallCount += 1;
    showForTest(surahNumber: 1, expanded: expanded);
  }
}

Widget _buildLocalizedApp({
  required Widget child,
  Map<String, WidgetBuilder> routes = const {},
}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routes: routes,
    home: child,
  );
}

void _registerLocatorDependencies({
  required AudioRepository audioRepository,
  required DownloadRepository downloadRepository,
}) {
  if (locator.isRegistered<AudioRepository>()) {
    locator.unregister<AudioRepository>();
  }
  locator.registerLazySingleton<AudioRepository>(() => audioRepository);

  if (locator.isRegistered<GetDownloadedSurahsUseCase>()) {
    locator.unregister<GetDownloadedSurahsUseCase>();
  }
  locator.registerLazySingleton<GetDownloadedSurahsUseCase>(
    () => GetDownloadedSurahsUseCase(downloadRepository),
  );
}

void _unregisterLocatorDependencies() {
  if (locator.isRegistered<GetDownloadedSurahsUseCase>()) {
    locator.unregister<GetDownloadedSurahsUseCase>();
  }
  if (locator.isRegistered<AudioRepository>()) {
    locator.unregister<AudioRepository>();
  }
}

Widget _buildSurahAudioListHarness({
  required QuranSettingsCubit quranSettingsCubit,
  required AudioAvailabilityCubit audioAvailabilityCubit,
  required AudioManagementCubit audioManagementCubit,
  required SurahMiniPlayerCubit surahMiniPlayerCubit,
  bool withOverlay = false,
}) {
  final page = withOverlay
      ? Stack(
          children: const [
            SurahAudioListPage(),
            Material(
              type: MaterialType.transparency,
              child: SurahMiniPlayerOverlay(),
            ),
          ],
        )
      : const SurahAudioListPage();

  return _buildLocalizedApp(
    routes: {
      '/reciter-list': (_) => const Scaffold(body: Text('reciter-route')),
    },
    child: MultiBlocProvider(
      providers: [
        BlocProvider<QuranSettingsCubit>.value(value: quranSettingsCubit),
        BlocProvider<AudioAvailabilityCubit>.value(
          value: audioAvailabilityCubit,
        ),
        BlocProvider<AudioManagementCubit>.value(value: audioManagementCubit),
        BlocProvider<SurahMiniPlayerCubit>.value(value: surahMiniPlayerCubit),
      ],
      child: page,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const reciter = Reciter(
    id: 'imamsarr',
    name: 'Imam Sarr',
    arabicName: 'Imam',
  );
  final allSurahs = List<int>.generate(114, (index) => index + 1);

  tearDown(() {
    _unregisterLocatorDependencies();
  });

  testWidgets('HomeActionsGrid shows recitation card and opens audio route', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildLocalizedApp(
        routes: {
          SurahAudioListPage.routeName: (context) =>
              const Scaffold(body: Center(child: Text('audio-screen'))),
        },
        child: const Scaffold(body: HomeActionsGrid()),
      ),
    );

    expect(find.text('Recitation'), findsOneWidget);
    expect(find.text('Listen Audio'), findsOneWidget);

    await tester.tap(find.text('Recitation'));
    await tester.pumpAndSettle();

    expect(find.text('audio-screen'), findsOneWidget);
  });

  test(
    'SurahMiniPlayerCubit loads downloaded queue and toggles repeat',
    () async {
      final downloadRepository = _ConfigurableDownloadRepository(
        seed: {
          'imamsarr': const [
            DownloadedSurah(
              reciterId: 'imamsarr',
              surahNumber: 9,
              filePath: '/tmp/9',
              isComplete: true,
            ),
            DownloadedSurah(
              reciterId: 'imamsarr',
              surahNumber: 1,
              filePath: '/tmp/1',
              isComplete: true,
            ),
            DownloadedSurah(
              reciterId: 'imamsarr',
              surahNumber: 2,
              filePath: '/tmp/2',
              isComplete: false,
            ),
          ],
        },
      );
      final audioRepository = _FakeAudioRepository();
      final audioService = AudioPlayerService();
      await audioService.setRepeatSurah(false);

      final cubit = SurahMiniPlayerCubit(
        audioPlayerService: audioService,
        downloadRepository: downloadRepository,
        audioRepository: audioRepository,
      );

      await cubit.refreshQueueForReciter('imamsarr');
      expect(cubit.state.downloadedQueue, [1, 9]);

      await cubit.toggleRepeat();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.repeatSurah, isTrue);

      await cubit.close();
    },
  );

  testWidgets('SurahAudioListPage shows empty state when no reciter selected', (
    tester,
  ) async {
    final downloadRepository = _ConfigurableDownloadRepository();
    final audioRepository = _FakeAudioRepository();
    _registerLocatorDependencies(
      audioRepository: audioRepository,
      downloadRepository: downloadRepository,
    );

    final quranSettingsCubit = _TestQuranSettingsCubit();
    final availabilityRepository = _InMemoryAudioAvailabilityRepository(
      const [],
    );
    final availabilityCubit = AudioAvailabilityCubit(
      refreshAudioAvailabilityUseCase: RefreshAudioAvailabilityUseCase(
        availabilityRepository,
      ),
      getCachedAudioAvailabilityUseCase: GetCachedAudioAvailabilityUseCase(
        availabilityRepository,
      ),
      markAudioUpdatesSeenUseCase: MarkAudioUpdatesSeenUseCase(
        availabilityRepository,
      ),
    );
    final audioManagementCubit = _SpyAudioManagementCubit(
      audioRepository: audioRepository,
      downloadRepository: downloadRepository,
    );
    final miniPlayerCubit = _SpySurahMiniPlayerCubit(
      audioPlayerService: AudioPlayerService(),
      downloadRepository: downloadRepository,
      audioRepository: audioRepository,
    );

    addTearDown(() async {
      await quranSettingsCubit.close();
      await availabilityCubit.close();
      await audioManagementCubit.close();
      await miniPlayerCubit.close();
    });

    await tester.pumpWidget(
      _buildSurahAudioListHarness(
        quranSettingsCubit: quranSettingsCubit,
        audioAvailabilityCubit: availabilityCubit,
        audioManagementCubit: audioManagementCubit,
        surahMiniPlayerCubit: miniPlayerCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tafsir author selected'), findsOneWidget);
    expect(find.text('Select Tafsir Author'), findsWidgets);
  });

  testWidgets(
    'SurahAudioListPage shows 114 surahs with play/download actions',
    (tester) async {
      final downloadRepository = _ConfigurableDownloadRepository(
        seed: {
          reciter.id: const [
            DownloadedSurah(
              reciterId: 'imamsarr',
              surahNumber: 1,
              filePath: '/tmp/1',
              isComplete: true,
            ),
          ],
        },
      );
      final audioRepository = _FakeAudioRepository();
      _registerLocatorDependencies(
        audioRepository: audioRepository,
        downloadRepository: downloadRepository,
      );

      final quranSettingsCubit = _TestQuranSettingsCubit()
        ..setSelectedReciter(reciter);
      final availabilityRepository = _InMemoryAudioAvailabilityRepository([
        AudioAvailabilitySnapshot(
          reciterId: reciter.id,
          catalogVersion: 1,
          availableSurahs: allSurahs,
          unreadNewSurahs: const [],
          lastCheckedAt: DateTime.now(),
        ),
      ]);
      final availabilityCubit = AudioAvailabilityCubit(
        refreshAudioAvailabilityUseCase: RefreshAudioAvailabilityUseCase(
          availabilityRepository,
        ),
        getCachedAudioAvailabilityUseCase: GetCachedAudioAvailabilityUseCase(
          availabilityRepository,
        ),
        markAudioUpdatesSeenUseCase: MarkAudioUpdatesSeenUseCase(
          availabilityRepository,
        ),
      );
      await availabilityCubit.refreshReciter(reciter.id, force: true);

      final audioManagementCubit = _SpyAudioManagementCubit(
        audioRepository: audioRepository,
        downloadRepository: downloadRepository,
      );
      final miniPlayerCubit = _SpySurahMiniPlayerCubit(
        audioPlayerService: AudioPlayerService(),
        downloadRepository: downloadRepository,
        audioRepository: audioRepository,
      );

      addTearDown(() async {
        await quranSettingsCubit.close();
        await availabilityCubit.close();
        await audioManagementCubit.close();
        await miniPlayerCubit.close();
      });

      await tester.pumpWidget(
        _buildSurahAudioListHarness(
          quranSettingsCubit: quranSettingsCubit,
          audioAvailabilityCubit: availabilityCubit,
          audioManagementCubit: audioManagementCubit,
          surahMiniPlayerCubit: miniPlayerCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_circle_fill), findsWidgets);
      expect(find.byIcon(Icons.download_rounded), findsWidgets);

      final lastSurahArabic = quran.getSurahNameArabic(114);
      await tester.scrollUntilVisible(
        find.textContaining(lastSurahArabic),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining(lastSurahArabic), findsOneWidget);
    },
  );

  testWidgets(
    'SurahAudioListPage blocks unavailable surah with disabled icon',
    (tester) async {
      final downloadRepository = _ConfigurableDownloadRepository();
      final audioRepository = _FakeAudioRepository();
      _registerLocatorDependencies(
        audioRepository: audioRepository,
        downloadRepository: downloadRepository,
      );

      final quranSettingsCubit = _TestQuranSettingsCubit()
        ..setSelectedReciter(reciter);
      final availabilityRepository = _InMemoryAudioAvailabilityRepository([
        AudioAvailabilitySnapshot(
          reciterId: reciter.id,
          catalogVersion: 1,
          availableSurahs: allSurahs.where((surah) => surah != 1).toList(),
          unreadNewSurahs: const [],
          lastCheckedAt: DateTime.now(),
        ),
      ]);
      final availabilityCubit = AudioAvailabilityCubit(
        refreshAudioAvailabilityUseCase: RefreshAudioAvailabilityUseCase(
          availabilityRepository,
        ),
        getCachedAudioAvailabilityUseCase: GetCachedAudioAvailabilityUseCase(
          availabilityRepository,
        ),
        markAudioUpdatesSeenUseCase: MarkAudioUpdatesSeenUseCase(
          availabilityRepository,
        ),
      );
      await availabilityCubit.refreshReciter(reciter.id, force: true);

      final audioManagementCubit = _SpyAudioManagementCubit(
        audioRepository: audioRepository,
        downloadRepository: downloadRepository,
      );
      final miniPlayerCubit = _SpySurahMiniPlayerCubit(
        audioPlayerService: AudioPlayerService(),
        downloadRepository: downloadRepository,
        audioRepository: audioRepository,
      );

      addTearDown(() async {
        await quranSettingsCubit.close();
        await availabilityCubit.close();
        await audioManagementCubit.close();
        await miniPlayerCubit.close();
      });

      await tester.pumpWidget(
        _buildSurahAudioListHarness(
          quranSettingsCubit: quranSettingsCubit,
          audioAvailabilityCubit: availabilityCubit,
          audioManagementCubit: audioManagementCubit,
          surahMiniPlayerCubit: miniPlayerCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_for_offline_outlined), findsWidgets);
    },
  );

  testWidgets('SurahAudioListPage shows real-time download progress', (
    tester,
  ) async {
    final downloadRepository = _ConfigurableDownloadRepository();
    final audioRepository = _FakeAudioRepository();
    _registerLocatorDependencies(
      audioRepository: audioRepository,
      downloadRepository: downloadRepository,
    );

    final quranSettingsCubit = _TestQuranSettingsCubit()
      ..setSelectedReciter(reciter);
    final availabilityRepository = _InMemoryAudioAvailabilityRepository([
      AudioAvailabilitySnapshot(
        reciterId: reciter.id,
        catalogVersion: 1,
        availableSurahs: allSurahs,
        unreadNewSurahs: const [],
        lastCheckedAt: DateTime.now(),
      ),
    ]);
    final availabilityCubit = AudioAvailabilityCubit(
      refreshAudioAvailabilityUseCase: RefreshAudioAvailabilityUseCase(
        availabilityRepository,
      ),
      getCachedAudioAvailabilityUseCase: GetCachedAudioAvailabilityUseCase(
        availabilityRepository,
      ),
      markAudioUpdatesSeenUseCase: MarkAudioUpdatesSeenUseCase(
        availabilityRepository,
      ),
    );
    await availabilityCubit.refreshReciter(reciter.id, force: true);

    final audioManagementCubit = _SpyAudioManagementCubit(
      audioRepository: audioRepository,
      downloadRepository: downloadRepository,
    );
    final miniPlayerCubit = _SpySurahMiniPlayerCubit(
      audioPlayerService: AudioPlayerService(),
      downloadRepository: downloadRepository,
      audioRepository: audioRepository,
    );

    addTearDown(() async {
      await quranSettingsCubit.close();
      await availabilityCubit.close();
      await audioManagementCubit.close();
      await miniPlayerCubit.close();
    });

    await tester.pumpWidget(
      _buildSurahAudioListHarness(
        quranSettingsCubit: quranSettingsCubit,
        audioAvailabilityCubit: availabilityCubit,
        audioManagementCubit: audioManagementCubit,
        surahMiniPlayerCubit: miniPlayerCubit,
      ),
    );
    await tester.pumpAndSettle();

    audioManagementCubit.emitDownloading(
      reciterId: reciter.id,
      surahNumber: 1,
      progress: 0.4,
    );
    await tester.pumpAndSettle();

    expect(find.text('40%'), findsOneWidget);
  });

  testWidgets('Play action opens mini-player and updates playback context', (
    tester,
  ) async {
    final downloadRepository = _ConfigurableDownloadRepository(
      seed: {
        reciter.id: const [
          DownloadedSurah(
            reciterId: 'imamsarr',
            surahNumber: 1,
            filePath: '/tmp/1',
            isComplete: true,
          ),
        ],
      },
    );
    final audioRepository = _FakeAudioRepository();
    _registerLocatorDependencies(
      audioRepository: audioRepository,
      downloadRepository: downloadRepository,
    );

    final quranSettingsCubit = _TestQuranSettingsCubit()
      ..setSelectedReciter(reciter);
    final availabilityRepository = _InMemoryAudioAvailabilityRepository([
      AudioAvailabilitySnapshot(
        reciterId: reciter.id,
        catalogVersion: 1,
        availableSurahs: allSurahs,
        unreadNewSurahs: const [],
        lastCheckedAt: DateTime.now(),
      ),
    ]);
    final availabilityCubit = AudioAvailabilityCubit(
      refreshAudioAvailabilityUseCase: RefreshAudioAvailabilityUseCase(
        availabilityRepository,
      ),
      getCachedAudioAvailabilityUseCase: GetCachedAudioAvailabilityUseCase(
        availabilityRepository,
      ),
      markAudioUpdatesSeenUseCase: MarkAudioUpdatesSeenUseCase(
        availabilityRepository,
      ),
    );
    await availabilityCubit.refreshReciter(reciter.id, force: true);

    final audioManagementCubit = _SpyAudioManagementCubit(
      audioRepository: audioRepository,
      downloadRepository: downloadRepository,
    );
    final miniPlayerCubit = _SpySurahMiniPlayerCubit(
      audioPlayerService: AudioPlayerService(),
      downloadRepository: downloadRepository,
      audioRepository: audioRepository,
    );

    addTearDown(() async {
      await quranSettingsCubit.close();
      await availabilityCubit.close();
      await audioManagementCubit.close();
      await miniPlayerCubit.close();
    });

    await tester.pumpWidget(
      _buildSurahAudioListHarness(
        quranSettingsCubit: quranSettingsCubit,
        audioAvailabilityCubit: availabilityCubit,
        audioManagementCubit: audioManagementCubit,
        surahMiniPlayerCubit: miniPlayerCubit,
        withOverlay: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_circle_fill).first);
    await tester.pumpAndSettle();

    expect(audioManagementCubit.loadAyahAudiosCallCount, 1);
    expect(audioManagementCubit.playSurahCallCount, 1);
    expect(miniPlayerCubit.attachCallCount, 1);
    expect(find.text('1 - Al-Fatihah'), findsOneWidget);
  });

  testWidgets('Mini-player close button hides the overlay', (tester) async {
    final downloadRepository = _ConfigurableDownloadRepository();
    final audioRepository = _FakeAudioRepository();
    _registerLocatorDependencies(
      audioRepository: audioRepository,
      downloadRepository: downloadRepository,
    );

    final miniPlayerCubit = _SpySurahMiniPlayerCubit(
      audioPlayerService: AudioPlayerService(),
      downloadRepository: downloadRepository,
      audioRepository: audioRepository,
    );
    addTearDown(() async {
      await miniPlayerCubit.close();
    });

    await tester.pumpWidget(
      _buildLocalizedApp(
        child: BlocProvider<SurahMiniPlayerCubit>.value(
          value: miniPlayerCubit,
          child: const Scaffold(body: SurahMiniPlayerOverlay()),
        ),
      ),
    );

    miniPlayerCubit.showForTest(surahNumber: 1, expanded: true);
    await tester.pumpAndSettle();

    expect(find.text('1 - Al-Fatihah'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    expect(miniPlayerCubit.state.uiState, SurahMiniPlayerUiState.hidden);
    expect(find.text('1 - Al-Fatihah'), findsNothing);
  });

  testWidgets('Mini-player keeps seek disabled while duration is not ready', (
    tester,
  ) async {
    final downloadRepository = _ConfigurableDownloadRepository();
    final audioRepository = _FakeAudioRepository();
    _registerLocatorDependencies(
      audioRepository: audioRepository,
      downloadRepository: downloadRepository,
    );

    final miniPlayerCubit = _SpySurahMiniPlayerCubit(
      audioPlayerService: AudioPlayerService(),
      downloadRepository: downloadRepository,
      audioRepository: audioRepository,
    );
    addTearDown(() async {
      await miniPlayerCubit.close();
    });

    await tester.pumpWidget(
      _buildLocalizedApp(
        child: BlocProvider<SurahMiniPlayerCubit>.value(
          value: miniPlayerCubit,
          child: const Scaffold(body: SurahMiniPlayerOverlay()),
        ),
      ),
    );

    miniPlayerCubit.showForTest(
      surahNumber: 1,
      expanded: true,
      isSeekReady: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('--:--'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });
}
