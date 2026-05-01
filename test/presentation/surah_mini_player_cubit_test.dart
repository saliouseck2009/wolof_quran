import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolof_quran/core/services/audio_player_service.dart';
import 'package:wolof_quran/data/models/downloaded_surah.dart';
import 'package:wolof_quran/domain/entities/ayah_audio.dart';
import 'package:wolof_quran/domain/entities/surah_audio_status.dart';
import 'package:wolof_quran/domain/repositories/audio_repository.dart';
import 'package:wolof_quran/domain/repositories/download_repository.dart';
import 'package:wolof_quran/presentation/cubits/surah_mini_player_cubit.dart';

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
    return const <AyahAudio>[];
  }

  @override
  Future<List<int>> getDownloadedSurahs(String reciterId) async {
    return const <int>[];
  }

  @override
  Future<String> getSurahAudioPath(String reciterId, int surahNumber) async {
    return '/tmp/$reciterId/$surahNumber';
  }

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

  @override
  Future<void> warmUpAyahDurations(String reciterId, int surahNumber) async {}
}

class _FakeDownloadRepository implements DownloadRepository {
  final Set<String> _activeDownloads = <String>{};

  String _key(String reciterId, int surahNumber) => '${reciterId}_$surahNumber';

  @override
  bool tryStartSurahDownload(String reciterId, int surahNumber) {
    final key = _key(reciterId, surahNumber);
    if (_activeDownloads.contains(key)) {
      return false;
    }
    _activeDownloads.add(key);
    return true;
  }

  @override
  void finishSurahDownload(String reciterId, int surahNumber) {
    _activeDownloads.remove(_key(reciterId, surahNumber));
  }

  @override
  bool isSurahDownloadInProgress(String reciterId, int surahNumber) {
    return _activeDownloads.contains(_key(reciterId, surahNumber));
  }

  @override
  Future<DownloadedSurah?> getDownloadedSurah(
    String reciterId,
    int surahNumber,
  ) async {
    return null;
  }

  @override
  Future<List<DownloadedSurah>> getDownloadedSurahs(String reciterId) async {
    return const <DownloadedSurah>[];
  }

  @override
  Future<Map<String, int>> getDownloadStats(String reciterId) async {
    return <String, int>{'total': 0, 'completed': 0};
  }

  @override
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    return false;
  }

  @override
  Future<void> markSurahAsDownloaded(
    String reciterId,
    int surahNumber,
    String filePath,
  ) async {}

  @override
  Future<void> markSurahAsInProgress(
    String reciterId,
    int surahNumber,
    String filePath,
  ) async {}

  @override
  Future<void> removeSurahDownload(String reciterId, int surahNumber) async {}
}

class _TestSurahMiniPlayerCubit extends SurahMiniPlayerCubit {
  final List<int> playedSurahs = <int>[];

  _TestSurahMiniPlayerCubit({
    required super.audioPlayerService,
    required super.downloadRepository,
    required super.audioRepository,
    required super.randomIndexGenerator,
  }) : super();

  void seedState(SurahMiniPlayerState nextState) {
    emit(nextState);
  }

  @override
  Future<void> playSurahFromQueue(
    int surahNumber, {
    bool resetShuffleHistory = false,
    bool isQueueAdvance = false,
  }) async {
    playedSurahs.add(surahNumber);
    emit(
      state.copyWith(
        surahNumber: surahNumber,
        surahName: 'Surah $surahNumber',
        playerState: AudioPlayerState.loading,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = AudioPlayerService();
    await service.initialize();
    await service.stop();
    await service.reloadPlaybackModeFromPrefs();
    await service.setPlaybackMode(PlaybackMode.off);
  });

  group('SurahMiniPlayerCubit', () {
    test('repeatAll auto-advances then wraps on queue end', () async {
      final cubit = _TestSurahMiniPlayerCubit(
        audioPlayerService: AudioPlayerService(),
        downloadRepository: _FakeDownloadRepository(),
        audioRepository: _FakeAudioRepository(),
        randomIndexGenerator: (_) => 0,
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      cubit.seedState(
        const SurahMiniPlayerState(
          uiState: SurahMiniPlayerUiState.expanded,
          reciterId: 'imamsarr',
          surahNumber: 3,
          downloadedQueue: <int>[1, 3, 5],
          playbackMode: PlaybackMode.repeatAll,
        ),
      );

      await cubit.handlePlaybackCompleted(
        const PlaybackCompletedEvent(
          audioInfo: PlayingAudioInfo(
            surahNumber: 3,
            reciterId: 'imamsarr',
            isPlaylist: true,
          ),
          playbackMode: PlaybackMode.repeatAll,
        ),
      );
      expect(cubit.playedSurahs.last, 5);

      cubit.seedState(
        cubit.state.copyWith(
          surahNumber: 5,
          downloadedQueue: const <int>[1, 3, 5],
          playbackMode: PlaybackMode.repeatAll,
        ),
      );
      await cubit.handlePlaybackCompleted(
        const PlaybackCompletedEvent(
          audioInfo: PlayingAudioInfo(
            surahNumber: 5,
            reciterId: 'imamsarr',
            isPlaylist: true,
          ),
          playbackMode: PlaybackMode.repeatAll,
        ),
      );
      expect(cubit.playedSurahs.last, 1);
    });

    test('shuffle next avoids immediate repeat when possible', () async {
      final cubit = _TestSurahMiniPlayerCubit(
        audioPlayerService: AudioPlayerService(),
        downloadRepository: _FakeDownloadRepository(),
        audioRepository: _FakeAudioRepository(),
        randomIndexGenerator: (_) => 0,
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      cubit.seedState(
        const SurahMiniPlayerState(
          uiState: SurahMiniPlayerUiState.expanded,
          reciterId: 'imamsarr',
          surahNumber: 2,
          downloadedQueue: <int>[1, 2, 3],
          playbackMode: PlaybackMode.shuffle,
        ),
      );

      await cubit.playNextSurah();

      expect(cubit.playedSurahs.single, 1);
      expect(cubit.state.shuffleHistoryDepth, 1);
    });

    test('shuffle previous uses history stack', () async {
      final cubit = _TestSurahMiniPlayerCubit(
        audioPlayerService: AudioPlayerService(),
        downloadRepository: _FakeDownloadRepository(),
        audioRepository: _FakeAudioRepository(),
        randomIndexGenerator: (_) => 0,
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      cubit.seedState(
        const SurahMiniPlayerState(
          uiState: SurahMiniPlayerUiState.expanded,
          reciterId: 'imamsarr',
          surahNumber: 2,
          downloadedQueue: <int>[1, 2, 3],
          playbackMode: PlaybackMode.shuffle,
        ),
      );

      await cubit.playNextSurah();
      await cubit.playPreviousSurah();

      expect(cubit.playedSurahs, <int>[1, 2]);
      expect(cubit.state.shuffleHistoryDepth, 0);
    });

    test('repeatAll keeps player visible during auto-advance', () async {
      final cubit = _TestSurahMiniPlayerCubit(
        audioPlayerService: AudioPlayerService(),
        downloadRepository: _FakeDownloadRepository(),
        audioRepository: _FakeAudioRepository(),
        randomIndexGenerator: (_) => 0,
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      cubit.seedState(
        const SurahMiniPlayerState(
          uiState: SurahMiniPlayerUiState.fullscreen,
          reciterId: 'imamsarr',
          surahNumber: 1,
          downloadedQueue: <int>[1, 2],
          playbackMode: PlaybackMode.repeatAll,
        ),
      );

      await cubit.handlePlaybackCompleted(
        const PlaybackCompletedEvent(
          audioInfo: PlayingAudioInfo(
            surahNumber: 1,
            reciterId: 'imamsarr',
            isPlaylist: true,
          ),
          playbackMode: PlaybackMode.repeatAll,
        ),
      );

      expect(cubit.state.uiState, SurahMiniPlayerUiState.fullscreen);
      expect(cubit.playedSurahs.single, 2);
    });
  });
}
