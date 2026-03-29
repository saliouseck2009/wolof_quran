import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolof_quran/core/services/audio_download_queue_service.dart';
import 'package:wolof_quran/core/services/audio_player_service.dart';
import 'package:wolof_quran/data/models/downloaded_surah.dart';
import 'package:wolof_quran/domain/entities/audio_availability_snapshot.dart';
import 'package:wolof_quran/domain/entities/ayah_audio.dart';
import 'package:wolof_quran/domain/entities/queued_audio_download_task.dart';
import 'package:wolof_quran/domain/entities/reciter.dart';
import 'package:wolof_quran/domain/entities/surah_audio_status.dart';
import 'package:wolof_quran/domain/repositories/audio_availability_repository.dart';
import 'package:wolof_quran/domain/repositories/audio_repository.dart';
import 'package:wolof_quran/domain/repositories/download_queue_repository.dart';
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
import 'package:wolof_quran/presentation/cubits/audio_download_queue_cubit.dart';
import 'package:wolof_quran/presentation/cubits/audio_management_cubit.dart';
import 'package:wolof_quran/presentation/cubits/quran_settings_cubit.dart';
import 'package:wolof_quran/presentation/cubits/surah_mini_player_cubit.dart';
import 'package:wolof_quran/presentation/views/surah_audio_list_page.dart';
import 'package:wolof_quran/presentation/widgets/audio/surah_fullscreen_player.dart';
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

class _InMemoryDownloadQueueRepository implements DownloadQueueRepository {
  final Map<String, QueuedAudioDownloadTask> _storage =
      <String, QueuedAudioDownloadTask>{};

  String _key(String reciterId, int surahNumber) => '${reciterId}_$surahNumber';

  @override
  Future<void> clearFailed({String? reciterId}) async {
    final keysToDelete = _storage.entries
        .where(
          (entry) =>
              entry.value.status == QueuedAudioDownloadStatus.failed &&
              (reciterId == null || entry.value.reciterId == reciterId),
        )
        .map((entry) => entry.key)
        .toList();
    for (final key in keysToDelete) {
      _storage.remove(key);
    }
  }

  @override
  Future<void> enqueue(String reciterId, int surahNumber) async {
    final key = _key(reciterId, surahNumber);
    final existing = _storage[key];
    if (existing != null &&
        (existing.status == QueuedAudioDownloadStatus.queued ||
            existing.status == QueuedAudioDownloadStatus.downloading)) {
      return;
    }
    final now = DateTime.now();
    _storage[key] = QueuedAudioDownloadTask(
      reciterId: reciterId,
      surahNumber: surahNumber,
      status: QueuedAudioDownloadStatus.queued,
      progress: 0,
      attemptCount: 0,
      error: null,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  @override
  Future<void> enqueueMany(String reciterId, List<int> surahNumbers) async {
    for (final surahNumber in surahNumbers) {
      await enqueue(reciterId, surahNumber);
    }
  }

  @override
  Future<List<QueuedAudioDownloadTask>> getAllTasks() async {
    final tasks = _storage.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  @override
  Future<QueuedAudioDownloadTask?> getNextQueuedTask() async {
    final queued =
        _storage.values
            .where((task) => task.status == QueuedAudioDownloadStatus.queued)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return queued.isEmpty ? null : queued.first;
  }

  @override
  Future<QueuedAudioDownloadTask?> getTask(
    String reciterId,
    int surahNumber,
  ) async {
    return _storage[_key(reciterId, surahNumber)];
  }

  @override
  Future<List<QueuedAudioDownloadTask>> getTasksForReciter(
    String reciterId,
  ) async {
    final tasks =
        _storage.values.where((task) => task.reciterId == reciterId).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  @override
  Future<void> markAsDownloading(
    String reciterId,
    int surahNumber, {
    double progress = 0,
  }) async {
    final existing = _storage[_key(reciterId, surahNumber)];
    if (existing == null) return;
    _storage[_key(reciterId, surahNumber)] = existing.copyWith(
      status: QueuedAudioDownloadStatus.downloading,
      progress: progress,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> markAsFailed(
    String reciterId,
    int surahNumber, {
    required int attemptCount,
    required String? error,
  }) async {
    final existing = _storage[_key(reciterId, surahNumber)];
    if (existing == null) return;
    _storage[_key(reciterId, surahNumber)] = existing.copyWith(
      status: QueuedAudioDownloadStatus.failed,
      progress: 0,
      attemptCount: attemptCount,
      error: error,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> markAsQueued(
    String reciterId,
    int surahNumber, {
    double progress = 0,
    int? attemptCount,
    String? error,
    bool clearError = true,
  }) async {
    final existing = _storage[_key(reciterId, surahNumber)];
    if (existing == null) return;
    _storage[_key(reciterId, surahNumber)] = existing.copyWith(
      status: QueuedAudioDownloadStatus.queued,
      progress: progress,
      attemptCount: attemptCount ?? existing.attemptCount,
      error: error,
      clearError: clearError,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> removeTask(String reciterId, int surahNumber) async {
    _storage.remove(_key(reciterId, surahNumber));
  }

  @override
  Future<void> requeueInterruptedDownloads() async {
    for (final entry in _storage.entries.toList()) {
      final task = entry.value;
      if (task.status == QueuedAudioDownloadStatus.downloading) {
        _storage[entry.key] = task.copyWith(
          status: QueuedAudioDownloadStatus.queued,
          progress: 0,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<void> updateProgress(
    String reciterId,
    int surahNumber,
    double progress,
  ) async {
    final existing = _storage[_key(reciterId, surahNumber)];
    if (existing == null) return;
    _storage[_key(reciterId, surahNumber)] = existing.copyWith(
      progress: progress,
      updatedAt: DateTime.now(),
    );
  }
}

class _NoopAudioDownloadQueueService extends AudioDownloadQueueService {
  final BehaviorSubject<List<QueuedAudioDownloadTask>> _tasksSubject =
      BehaviorSubject<List<QueuedAudioDownloadTask>>.seeded(const []);
  final PublishSubject<QueuedAudioDownloadTask> _completedSubject =
      PublishSubject<QueuedAudioDownloadTask>();
  final PublishSubject<QueuedAudioDownloadTask> _failedSubject =
      PublishSubject<QueuedAudioDownloadTask>();

  final Map<String, QueuedAudioDownloadTask> _tasks =
      <String, QueuedAudioDownloadTask>{};

  _NoopAudioDownloadQueueService()
    : super(
        queueRepository: _InMemoryDownloadQueueRepository(),
        audioRepository: _FakeAudioRepository(),
        downloadRepository: _ConfigurableDownloadRepository(),
      );

  String _key(String reciterId, int surahNumber) => '${reciterId}_$surahNumber';

  @override
  Stream<List<QueuedAudioDownloadTask>> get tasks => _tasksSubject.stream;

  @override
  Stream<QueuedAudioDownloadTask> get completedTasks =>
      _completedSubject.stream;

  @override
  Stream<QueuedAudioDownloadTask> get failedTasks => _failedSubject.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<EnqueueAudioDownloadResult> enqueue(
    String reciterId,
    int surahNumber,
  ) async {
    final existing = _tasks[_key(reciterId, surahNumber)];
    if (existing != null &&
        (existing.status == QueuedAudioDownloadStatus.queued ||
            existing.status == QueuedAudioDownloadStatus.downloading)) {
      return EnqueueAudioDownloadResult.alreadyQueued;
    }
    final now = DateTime.now();
    _tasks[_key(reciterId, surahNumber)] = QueuedAudioDownloadTask(
      reciterId: reciterId,
      surahNumber: surahNumber,
      status: QueuedAudioDownloadStatus.queued,
      progress: 0,
      attemptCount: 0,
      error: null,
      createdAt: now,
      updatedAt: now,
    );
    _emitTasks();
    return EnqueueAudioDownloadResult.enqueued;
  }

  @override
  Future<Map<int, EnqueueAudioDownloadResult>> enqueueMany(
    String reciterId,
    List<int> surahNumbers,
  ) async {
    final results = <int, EnqueueAudioDownloadResult>{};
    for (final surahNumber in surahNumbers) {
      results[surahNumber] = await enqueue(reciterId, surahNumber);
    }
    return results;
  }

  @override
  Future<bool> retryFailed(String reciterId, int surahNumber) async {
    final key = _key(reciterId, surahNumber);
    final task = _tasks[key];
    if (task == null || task.status != QueuedAudioDownloadStatus.failed) {
      return false;
    }
    _tasks[key] = task.copyWith(
      status: QueuedAudioDownloadStatus.queued,
      progress: 0,
      clearError: true,
      updatedAt: DateTime.now(),
    );
    _emitTasks();
    return true;
  }

  @override
  Future<void> clearFailed({String? reciterId}) async {
    final keys = _tasks.entries
        .where(
          (entry) =>
              entry.value.status == QueuedAudioDownloadStatus.failed &&
              (reciterId == null || entry.value.reciterId == reciterId),
        )
        .map((entry) => entry.key)
        .toList();
    for (final key in keys) {
      _tasks.remove(key);
    }
    _emitTasks();
  }

  @override
  Future<bool> hasActiveOrQueuedForReciter(String reciterId) async {
    return _tasks.values.any(
      (task) =>
          task.reciterId == reciterId &&
          (task.status == QueuedAudioDownloadStatus.queued ||
              task.status == QueuedAudioDownloadStatus.downloading),
    );
  }

  void emitTasks(List<QueuedAudioDownloadTask> tasks) {
    _tasks
      ..clear()
      ..addEntries(
        tasks.map(
          (task) => MapEntry(_key(task.reciterId, task.surahNumber), task),
        ),
      );
    _emitTasks();
  }

  void _emitTasks() {
    final sorted = _tasks.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _tasksSubject.add(sorted);
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
    SurahMiniPlayerUiState? uiState,
    bool isSeekReady = true,
    PlaybackMode playbackMode = PlaybackMode.off,
  }) {
    emit(
      SurahMiniPlayerState(
        uiState:
            uiState ??
            (expanded
                ? SurahMiniPlayerUiState.expanded
                : SurahMiniPlayerUiState.collapsed),
        reciterId: 'imamsarr',
        surahNumber: surahNumber,
        surahName: surahName,
        downloadedQueue: const [1, 2, 3],
        playerState: AudioPlayerState.playing,
        position: const Duration(seconds: 5),
        duration: const Duration(minutes: 2),
        isSeekReady: isSeekReady,
        playbackMode: playbackMode,
      ),
    );
  }

  @override
  Future<void> attachToCurrentPlayback({
    bool expanded = true,
    bool resetShuffleHistory = false,
  }) async {
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
  required AudioDownloadQueueCubit audioDownloadQueueCubit,
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
        BlocProvider<AudioDownloadQueueCubit>.value(
          value: audioDownloadQueueCubit,
        ),
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

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = AudioPlayerService();
    await service.initialize();
    await service.stop();
    await service.reloadPlaybackModeFromPrefs();
    await service.setPlaybackMode(PlaybackMode.off);
  });

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
    'SurahMiniPlayerCubit loads downloaded queue and cycles playback mode',
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
      await audioService.setPlaybackMode(PlaybackMode.off);

      final cubit = SurahMiniPlayerCubit(
        audioPlayerService: audioService,
        downloadRepository: downloadRepository,
        audioRepository: audioRepository,
      );

      await cubit.refreshQueueForReciter('imamsarr');
      expect(cubit.state.downloadedQueue, [1, 9]);

      await cubit.cyclePlaybackMode();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.playbackMode, PlaybackMode.repeatOne);

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
    final queueService = _NoopAudioDownloadQueueService();
    final queueCubit = AudioDownloadQueueCubit(queueService: queueService);

    addTearDown(() async {
      await quranSettingsCubit.close();
      await availabilityCubit.close();
      await audioManagementCubit.close();
      await queueCubit.close();
      await miniPlayerCubit.close();
    });

    await tester.pumpWidget(
      _buildSurahAudioListHarness(
        quranSettingsCubit: quranSettingsCubit,
        audioAvailabilityCubit: availabilityCubit,
        audioManagementCubit: audioManagementCubit,
        audioDownloadQueueCubit: queueCubit,
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
      final queueService = _NoopAudioDownloadQueueService();
      final queueCubit = AudioDownloadQueueCubit(queueService: queueService);

      addTearDown(() async {
        await quranSettingsCubit.close();
        await availabilityCubit.close();
        await audioManagementCubit.close();
        await queueCubit.close();
        await miniPlayerCubit.close();
      });

      await tester.pumpWidget(
        _buildSurahAudioListHarness(
          quranSettingsCubit: quranSettingsCubit,
          audioAvailabilityCubit: availabilityCubit,
          audioManagementCubit: audioManagementCubit,
          audioDownloadQueueCubit: queueCubit,
          surahMiniPlayerCubit: miniPlayerCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
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
      final queueService = _NoopAudioDownloadQueueService();
      final queueCubit = AudioDownloadQueueCubit(queueService: queueService);

      addTearDown(() async {
        await quranSettingsCubit.close();
        await availabilityCubit.close();
        await audioManagementCubit.close();
        await queueCubit.close();
        await miniPlayerCubit.close();
      });

      await tester.pumpWidget(
        _buildSurahAudioListHarness(
          quranSettingsCubit: quranSettingsCubit,
          audioAvailabilityCubit: availabilityCubit,
          audioManagementCubit: audioManagementCubit,
          audioDownloadQueueCubit: queueCubit,
          surahMiniPlayerCubit: miniPlayerCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off_outlined), findsWidgets);
    },
  );

  testWidgets(
    'SurahAudioListPage auto-enqueues surah 1 when nothing is downloaded',
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
      final queueService = _NoopAudioDownloadQueueService();
      final queueCubit = AudioDownloadQueueCubit(queueService: queueService);

      addTearDown(() async {
        await quranSettingsCubit.close();
        await availabilityCubit.close();
        await audioManagementCubit.close();
        await queueCubit.close();
        await miniPlayerCubit.close();
      });

      await tester.pumpWidget(
        _buildSurahAudioListHarness(
          quranSettingsCubit: quranSettingsCubit,
          audioAvailabilityCubit: availabilityCubit,
          audioManagementCubit: audioManagementCubit,
          audioDownloadQueueCubit: queueCubit,
          surahMiniPlayerCubit: miniPlayerCubit,
        ),
      );
      await tester.pumpAndSettle();

      final task = queueCubit.state.taskFor(reciter.id, 1);
      expect(task, isNotNull);
      expect(task!.status, QueuedAudioDownloadStatus.queued);
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
    final queueService = _NoopAudioDownloadQueueService();
    final queueCubit = AudioDownloadQueueCubit(queueService: queueService);

    addTearDown(() async {
      await quranSettingsCubit.close();
      await availabilityCubit.close();
      await audioManagementCubit.close();
      await queueCubit.close();
      await miniPlayerCubit.close();
    });

    await tester.pumpWidget(
      _buildSurahAudioListHarness(
        quranSettingsCubit: quranSettingsCubit,
        audioAvailabilityCubit: availabilityCubit,
        audioManagementCubit: audioManagementCubit,
        audioDownloadQueueCubit: queueCubit,
        surahMiniPlayerCubit: miniPlayerCubit,
      ),
    );
    await tester.pumpAndSettle();

    queueService.emitTasks([
      QueuedAudioDownloadTask(
        reciterId: reciter.id,
        surahNumber: 1,
        status: QueuedAudioDownloadStatus.downloading,
        progress: 0.4,
        attemptCount: 0,
        error: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
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
    final queueService = _NoopAudioDownloadQueueService();
    final queueCubit = AudioDownloadQueueCubit(queueService: queueService);

    addTearDown(() async {
      await quranSettingsCubit.close();
      await availabilityCubit.close();
      await audioManagementCubit.close();
      await queueCubit.close();
      await miniPlayerCubit.close();
    });

    await tester.pumpWidget(
      _buildSurahAudioListHarness(
        quranSettingsCubit: quranSettingsCubit,
        audioAvailabilityCubit: availabilityCubit,
        audioManagementCubit: audioManagementCubit,
        audioDownloadQueueCubit: queueCubit,
        surahMiniPlayerCubit: miniPlayerCubit,
        withOverlay: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(audioManagementCubit.loadAyahAudiosCallCount, 1);
    expect(audioManagementCubit.playSurahCallCount, 1);
    expect(miniPlayerCubit.attachCallCount, 1);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
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

    expect(find.text('Al-Fatihah'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(miniPlayerCubit.state.uiState, SurahMiniPlayerUiState.hidden);
    expect(find.text('Al-Fatihah'), findsNothing);
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

  testWidgets('Mini-player playback mode button cycles through modes', (
    tester,
  ) async {
    final downloadRepository = _ConfigurableDownloadRepository();
    final audioRepository = _FakeAudioRepository();
    _registerLocatorDependencies(
      audioRepository: audioRepository,
      downloadRepository: downloadRepository,
    );

    final audioService = AudioPlayerService();
    await audioService.setPlaybackMode(PlaybackMode.off);

    final miniPlayerCubit = _SpySurahMiniPlayerCubit(
      audioPlayerService: audioService,
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
      playbackMode: PlaybackMode.off,
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.repeat_rounded));
    await tester.pump();

    expect(miniPlayerCubit.state.playbackMode, PlaybackMode.repeatOne);
    expect(find.byIcon(Icons.repeat_one_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.repeat_one_rounded));
    await tester.pump();

    expect(miniPlayerCubit.state.playbackMode, PlaybackMode.repeatAll);
    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.repeat_rounded));
    await tester.pump();

    expect(miniPlayerCubit.state.playbackMode, PlaybackMode.shuffle);
    expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
  });

  testWidgets('Fullscreen player reflects persisted playback mode', (
    tester,
  ) async {
    final downloadRepository = _ConfigurableDownloadRepository();
    final audioRepository = _FakeAudioRepository();
    _registerLocatorDependencies(
      audioRepository: audioRepository,
      downloadRepository: downloadRepository,
    );

    final audioService = AudioPlayerService();
    await audioService.setPlaybackMode(PlaybackMode.shuffle);
    await audioService.reloadPlaybackModeFromPrefs();

    final miniPlayerCubit = _SpySurahMiniPlayerCubit(
      audioPlayerService: audioService,
      downloadRepository: downloadRepository,
      audioRepository: audioRepository,
    );
    addTearDown(() async {
      await miniPlayerCubit.close();
    });

    await tester.pumpWidget(
      _buildLocalizedApp(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<SurahMiniPlayerCubit>.value(value: miniPlayerCubit),
            BlocProvider<QuranSettingsCubit>(
              create: (_) => _TestQuranSettingsCubit(),
            ),
          ],
          child: const Scaffold(body: SurahFullscreenPlayer()),
        ),
      ),
    );

    miniPlayerCubit.showForTest(
      surahNumber: 1,
      uiState: SurahMiniPlayerUiState.fullscreen,
      playbackMode: audioService.currentPlaybackMode,
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    expect(miniPlayerCubit.state.playbackMode, PlaybackMode.shuffle);
  });
}
