import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../core/services/audio_player_service.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/repositories/download_repository.dart';

enum SurahMiniPlayerUiState { hidden, collapsed, expanded, fullscreen }

class SurahMiniPlayerState extends Equatable {
  final SurahMiniPlayerUiState uiState;
  final String? reciterId;
  final int? surahNumber;
  final String? surahName;
  final List<int> downloadedQueue;
  final AudioPlayerState playerState;
  final Duration position;
  final Duration? duration;
  final bool isSeekReady;
  final PlaybackMode playbackMode;
  final int shuffleHistoryDepth;

  const SurahMiniPlayerState({
    this.uiState = SurahMiniPlayerUiState.hidden,
    this.reciterId,
    this.surahNumber,
    this.surahName,
    this.downloadedQueue = const [],
    this.playerState = AudioPlayerState.idle,
    this.position = Duration.zero,
    this.duration,
    this.isSeekReady = false,
    this.playbackMode = PlaybackMode.off,
    this.shuffleHistoryDepth = 0,
  });

  bool get hasActiveSurah => reciterId != null && surahNumber != null;

  int get currentQueueIndex {
    if (surahNumber == null) {
      return -1;
    }
    return downloadedQueue.indexOf(surahNumber!);
  }

  bool get canGoPrevious {
    if (!hasActiveSurah || currentQueueIndex < 0) {
      return false;
    }
    switch (playbackMode) {
      case PlaybackMode.shuffle:
        return shuffleHistoryDepth > 0;
      case PlaybackMode.repeatAll:
        return downloadedQueue.isNotEmpty;
      case PlaybackMode.off:
      case PlaybackMode.repeatOne:
        return currentQueueIndex > 0;
    }
  }

  bool get canGoNext {
    if (!hasActiveSurah || currentQueueIndex < 0) {
      return false;
    }
    switch (playbackMode) {
      case PlaybackMode.shuffle:
      case PlaybackMode.repeatAll:
        return downloadedQueue.isNotEmpty;
      case PlaybackMode.off:
      case PlaybackMode.repeatOne:
        return currentQueueIndex < downloadedQueue.length - 1;
    }
  }

  SurahMiniPlayerState copyWith({
    SurahMiniPlayerUiState? uiState,
    String? reciterId,
    int? surahNumber,
    String? surahName,
    List<int>? downloadedQueue,
    AudioPlayerState? playerState,
    Duration? position,
    Duration? duration,
    bool clearDuration = false,
    bool? isSeekReady,
    PlaybackMode? playbackMode,
    int? shuffleHistoryDepth,
    bool clearTrack = false,
  }) {
    return SurahMiniPlayerState(
      uiState: uiState ?? this.uiState,
      reciterId: clearTrack ? null : (reciterId ?? this.reciterId),
      surahNumber: clearTrack ? null : (surahNumber ?? this.surahNumber),
      surahName: clearTrack ? null : (surahName ?? this.surahName),
      downloadedQueue: downloadedQueue ?? this.downloadedQueue,
      playerState: playerState ?? this.playerState,
      position: position ?? this.position,
      duration: clearDuration ? null : (duration ?? this.duration),
      isSeekReady: isSeekReady ?? this.isSeekReady,
      playbackMode: playbackMode ?? this.playbackMode,
      shuffleHistoryDepth: shuffleHistoryDepth ?? this.shuffleHistoryDepth,
    );
  }

  @override
  List<Object?> get props => [
    uiState,
    reciterId,
    surahNumber,
    surahName,
    downloadedQueue,
    playerState,
    position,
    duration,
    isSeekReady,
    playbackMode,
    shuffleHistoryDepth,
  ];
}

class SurahMiniPlayerCubit extends Cubit<SurahMiniPlayerState> {
  final AudioPlayerService _audioPlayerService;
  final DownloadRepository _downloadRepository;
  final AudioRepository _audioRepository;

  StreamSubscription<PlayingAudioInfo?>? _audioSub;
  StreamSubscription<AudioPlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _globalPositionSub;
  StreamSubscription<Duration?>? _globalDurationSub;
  StreamSubscription<bool>? _seekReadySub;
  StreamSubscription<PlaybackMode>? _playbackModeSub;
  StreamSubscription<PlaybackCompletedEvent>? _playbackCompletedSub;
  final int Function(int max) _nextRandomInt;
  final List<int> _shuffleHistory = <int>[];
  bool _isAdvancingQueue = false;

  SurahMiniPlayerCubit({
    required AudioPlayerService audioPlayerService,
    required DownloadRepository downloadRepository,
    required AudioRepository audioRepository,
    int Function(int max)? randomIndexGenerator,
  }) : _audioPlayerService = audioPlayerService,
       _downloadRepository = downloadRepository,
       _audioRepository = audioRepository,
       _nextRandomInt = randomIndexGenerator ?? Random().nextInt,
       super(
         SurahMiniPlayerState(
           playerState: audioPlayerService.currentPlayerState,
           position: audioPlayerService.currentSurahGlobalPosition,
           duration: audioPlayerService.currentSurahGlobalDuration,
           isSeekReady: audioPlayerService.isSurahSeekReady,
           playbackMode: audioPlayerService.currentPlaybackMode,
         ),
       ) {
    _listenToPlayerStreams();
  }

  void _listenToPlayerStreams() {
    _audioSub = _audioPlayerService.currentAudio.listen(_handleCurrentAudio);
    _playerStateSub = _audioPlayerService.playerState.listen((playerState) {
      if (_isAdvancingQueue &&
          (playerState == AudioPlayerState.stopped ||
              playerState == AudioPlayerState.idle)) {
        return;
      }
      if ((playerState == AudioPlayerState.stopped ||
              playerState == AudioPlayerState.idle) &&
          _audioPlayerService.currentPlayingAudio == null &&
          state.hasActiveSurah) {
        _clearShuffleHistory();
        emit(
          state.copyWith(
            uiState: SurahMiniPlayerUiState.hidden,
            playerState: playerState,
            clearTrack: true,
            position: Duration.zero,
            clearDuration: true,
            shuffleHistoryDepth: 0,
          ),
        );
        return;
      }
      emit(state.copyWith(playerState: playerState));
    });
    _globalPositionSub = _audioPlayerService.surahGlobalPosition.listen((
      position,
    ) {
      emit(state.copyWith(position: position));
    });
    _globalDurationSub = _audioPlayerService.surahGlobalDuration.listen((
      duration,
    ) {
      emit(state.copyWith(duration: duration));
    });
    _seekReadySub = _audioPlayerService.surahSeekReady.listen((isSeekReady) {
      emit(state.copyWith(isSeekReady: isSeekReady));
    });
    _playbackModeSub = _audioPlayerService.playbackMode.listen((playbackMode) {
      emit(state.copyWith(playbackMode: playbackMode));
    });
    _playbackCompletedSub = _audioPlayerService.playbackCompleted.listen(
      handlePlaybackCompleted,
    );
  }

  Future<void> _handleCurrentAudio(PlayingAudioInfo? audioInfo) async {
    if (audioInfo == null) {
      if (_isAdvancingQueue) {
        return;
      }
      final currentPlayerState = _audioPlayerService.currentPlayerState;
      final hasTransientPlaybackState =
          currentPlayerState == AudioPlayerState.playing ||
          currentPlayerState == AudioPlayerState.loading ||
          currentPlayerState == AudioPlayerState.paused;

      // Guard against transient null emissions from the player while playback
      // is still active (or paused) to prevent fullscreen from being dismissed.
      if (hasTransientPlaybackState && state.hasActiveSurah) {
        return;
      }
      _clearShuffleHistory();
      emit(
        state.copyWith(
          uiState: SurahMiniPlayerUiState.hidden,
          clearTrack: true,
          position: Duration.zero,
          clearDuration: true,
          shuffleHistoryDepth: 0,
        ),
      );
      return;
    }

    if (!audioInfo.isPlaylist) {
      if (_isAdvancingQueue) {
        return;
      }
      _clearShuffleHistory();
      emit(
        state.copyWith(
          uiState: SurahMiniPlayerUiState.hidden,
          clearTrack: true,
          position: Duration.zero,
          clearDuration: true,
          shuffleHistoryDepth: 0,
        ),
      );
      return;
    }

    _isAdvancingQueue = false;

    final resolvedName =
        audioInfo.surahName ?? quran.getSurahNameEnglish(audioInfo.surahNumber);
    final nextUiState = state.uiState == SurahMiniPlayerUiState.hidden
        ? SurahMiniPlayerUiState.collapsed
        : state.uiState;

    emit(
      state.copyWith(
        uiState: nextUiState,
        reciterId: audioInfo.reciterId,
        surahNumber: audioInfo.surahNumber,
        surahName: resolvedName,
        shuffleHistoryDepth: _shuffleHistory.length,
      ),
    );

    await refreshQueueForReciter(audioInfo.reciterId);
  }

  Future<void> attachToCurrentPlayback({
    bool expanded = true,
    bool resetShuffleHistory = false,
  }) async {
    final current = _audioPlayerService.currentPlayingAudio;
    if (current == null || !current.isPlaylist) {
      return;
    }

    if (resetShuffleHistory) {
      _clearShuffleHistory();
    }

    final resolvedName =
        current.surahName ?? quran.getSurahNameEnglish(current.surahNumber);
    emit(
      state.copyWith(
        uiState: expanded
            ? SurahMiniPlayerUiState.expanded
            : SurahMiniPlayerUiState.collapsed,
        reciterId: current.reciterId,
        surahNumber: current.surahNumber,
        surahName: resolvedName,
        shuffleHistoryDepth: _shuffleHistory.length,
      ),
    );

    await refreshQueueForReciter(current.reciterId);
  }

  void expand() {
    if (!state.hasActiveSurah) {
      return;
    }
    emit(state.copyWith(uiState: SurahMiniPlayerUiState.expanded));
  }

  void collapse() {
    if (!state.hasActiveSurah) {
      return;
    }
    emit(state.copyWith(uiState: SurahMiniPlayerUiState.collapsed));
  }

  void openFullscreen() {
    if (!state.hasActiveSurah) return;
    emit(state.copyWith(uiState: SurahMiniPlayerUiState.fullscreen));
  }

  void closeFullscreen() {
    if (!state.hasActiveSurah) return;
    emit(state.copyWith(uiState: SurahMiniPlayerUiState.expanded));
  }

  Future<void> closePlayer() async {
    _clearShuffleHistory();
    await _audioPlayerService.stop();
    emit(
      state.copyWith(
        uiState: SurahMiniPlayerUiState.hidden,
        clearTrack: true,
        position: Duration.zero,
        clearDuration: true,
        shuffleHistoryDepth: 0,
      ),
    );
  }

  Future<void> togglePlayPause() async {
    switch (state.playerState) {
      case AudioPlayerState.playing:
        await _audioPlayerService.pause();
        break;
      case AudioPlayerState.loading:
        // Calling pause() while just_audio is loading a source interrupts the
        // platform activation and throws "Loading interrupted". Ignore the tap.
        break;
      case AudioPlayerState.paused:
      case AudioPlayerState.stopped:
      case AudioPlayerState.idle:
      case AudioPlayerState.error:
        await _audioPlayerService.resume();
        break;
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayerService.seekWithinSurah(position);
  }

  Future<void> seekBySeconds(int seconds) async {
    await _audioPlayerService.seekBy(Duration(seconds: seconds));
  }

  Future<void> cyclePlaybackMode() async {
    await _audioPlayerService.cyclePlaybackMode();
  }

  Future<void> refreshQueueForReciter(String reciterId) async {
    final downloaded = await _downloadRepository.getDownloadedSurahs(reciterId);
    final queue =
        downloaded
            .where((item) => item.isComplete)
            .map((item) => item.surahNumber)
            .toSet()
            .toList()
          ..sort();

    emit(
      state.copyWith(
        downloadedQueue: queue,
        shuffleHistoryDepth: _shuffleHistory.length,
      ),
    );
  }

  Future<void> playPreviousSurah() async {
    if (!state.canGoPrevious) {
      return;
    }

    switch (state.playbackMode) {
      case PlaybackMode.shuffle:
        await _playPreviousShuffledSurah();
        return;
      case PlaybackMode.repeatAll:
        await _playLinearSurah(forward: false, wrap: true);
        return;
      case PlaybackMode.off:
      case PlaybackMode.repeatOne:
        await _playLinearSurah(forward: false, wrap: false);
        return;
    }
  }

  Future<void> playNextSurah() async {
    if (!state.canGoNext) {
      return;
    }

    switch (state.playbackMode) {
      case PlaybackMode.shuffle:
        await _playNextShuffledSurah(recordHistory: true);
        return;
      case PlaybackMode.repeatAll:
        await _playLinearSurah(forward: true, wrap: true);
        return;
      case PlaybackMode.off:
      case PlaybackMode.repeatOne:
        await _playLinearSurah(forward: true, wrap: false);
        return;
    }
  }

  Future<void> handlePlaybackCompleted(PlaybackCompletedEvent event) async {
    if (!event.audioInfo.isPlaylist ||
        state.reciterId != event.audioInfo.reciterId ||
        state.surahNumber != event.audioInfo.surahNumber) {
      return;
    }

    switch (event.playbackMode) {
      case PlaybackMode.repeatAll:
        await _playLinearSurah(forward: true, wrap: true, isQueueAdvance: true);
        return;
      case PlaybackMode.shuffle:
        await _playNextShuffledSurah(recordHistory: true, isQueueAdvance: true);
        return;
      case PlaybackMode.off:
      case PlaybackMode.repeatOne:
        return;
    }
  }

  static int? computeLinearQueueTarget({
    required int currentIndex,
    required int queueLength,
    required bool forward,
    required bool wrap,
  }) {
    if (queueLength <= 0 || currentIndex < 0 || currentIndex >= queueLength) {
      return null;
    }

    final candidate = forward ? currentIndex + 1 : currentIndex - 1;
    if (candidate >= 0 && candidate < queueLength) {
      return candidate;
    }
    if (!wrap) {
      return null;
    }
    return forward ? 0 : queueLength - 1;
  }

  static int? selectShuffleTarget({
    required List<int> queue,
    required int currentSurah,
    required int Function(int max) nextInt,
  }) {
    if (queue.isEmpty) {
      return null;
    }

    final candidates = queue.where((surah) => surah != currentSurah).toList();
    if (candidates.isEmpty) {
      return queue.first;
    }
    return candidates[nextInt(candidates.length)];
  }

  Future<void> playSurahFromQueue(
    int surahNumber, {
    bool resetShuffleHistory = false,
    bool isQueueAdvance = false,
  }) async {
    final reciterId = state.reciterId;
    if (reciterId == null) {
      return;
    }

    final targetUiState = state.uiState == SurahMiniPlayerUiState.hidden
        ? SurahMiniPlayerUiState.expanded
        : state.uiState;

    if (resetShuffleHistory) {
      _clearShuffleHistory();
    }
    if (isQueueAdvance) {
      _beginQueueAdvance();
    }

    try {
      final ayahAudios = await _audioRepository.getAyahAudios(
        reciterId,
        surahNumber,
      );
      if (ayahAudios.isEmpty) {
        if (isQueueAdvance) {
          _isAdvancingQueue = false;
        }
        return;
      }

      final filePaths = ayahAudios.map((audio) => audio.localPath).toList();
      var ayahDurations = ayahAudios.map((audio) => audio.duration).toList();
      final hasMissingDurations = ayahDurations.any(
        (duration) => duration == null || duration.inMilliseconds <= 0,
      );

      // Warmup durations before playback so the UI has them immediately.
      if (hasMissingDurations) {
        try {
          await _audioRepository.warmUpAyahDurations(reciterId, surahNumber);
          final warmedAyahs = await _audioRepository.getAyahAudios(
            reciterId,
            surahNumber,
          );
          ayahDurations = warmedAyahs.map((audio) => audio.duration).toList();
        } catch (_) {
          // Continue with partial durations.
        }
      }

      await _audioPlayerService.playSurahPlaylist(
        filePaths: filePaths,
        surahNumber: surahNumber,
        reciterId: reciterId,
        surahName: quran.getSurahNameEnglish(surahNumber),
        ayahDurations: ayahDurations,
        startIndex: 0,
      );

      // Do not override playerState here — the service streams already emitted
      // the correct state (playing/loading) during playSurahPlaylist. Emitting
      // loading again would permanently stick the cubit at loading even though
      // audio has already started playing.
      emit(
        state.copyWith(
          uiState: targetUiState,
          surahNumber: surahNumber,
          surahName: quran.getSurahNameEnglish(surahNumber),
          shuffleHistoryDepth: _shuffleHistory.length,
        ),
      );
    } catch (_) {
      _isAdvancingQueue = false;
      rethrow;
    }
  }

  Future<void> _playLinearSurah({
    required bool forward,
    required bool wrap,
    bool isQueueAdvance = false,
  }) async {
    final targetIndex = computeLinearQueueTarget(
      currentIndex: state.currentQueueIndex,
      queueLength: state.downloadedQueue.length,
      forward: forward,
      wrap: wrap,
    );
    if (targetIndex == null) {
      if (isQueueAdvance) {
        _isAdvancingQueue = false;
        await _audioPlayerService.stop();
      }
      return;
    }
    await playSurahFromQueue(
      state.downloadedQueue[targetIndex],
      isQueueAdvance: isQueueAdvance,
    );
  }

  Future<void> _playNextShuffledSurah({
    required bool recordHistory,
    bool isQueueAdvance = false,
  }) async {
    final currentSurah = state.surahNumber;
    if (currentSurah == null || state.downloadedQueue.isEmpty) {
      if (isQueueAdvance) {
        _isAdvancingQueue = false;
        await _audioPlayerService.stop();
      }
      return;
    }

    final target = selectShuffleTarget(
      queue: state.downloadedQueue,
      currentSurah: currentSurah,
      nextInt: _nextRandomInt,
    );
    if (target == null) {
      if (isQueueAdvance) {
        _isAdvancingQueue = false;
        await _audioPlayerService.stop();
      }
      return;
    }

    if (recordHistory) {
      _shuffleHistory.add(currentSurah);
      _syncShuffleHistoryDepth();
    }

    await playSurahFromQueue(target, isQueueAdvance: isQueueAdvance);
  }

  Future<void> _playPreviousShuffledSurah() async {
    if (_shuffleHistory.isEmpty) {
      return;
    }

    final target = _shuffleHistory.removeLast();
    _syncShuffleHistoryDepth();
    await playSurahFromQueue(target, isQueueAdvance: true);
  }

  void _beginQueueAdvance() {
    _isAdvancingQueue = true;
    emit(state.copyWith(playerState: AudioPlayerState.loading));
  }

  void _clearShuffleHistory() {
    _shuffleHistory.clear();
  }

  void _syncShuffleHistoryDepth() {
    emit(state.copyWith(shuffleHistoryDepth: _shuffleHistory.length));
  }

  @override
  Future<void> close() async {
    await _audioSub?.cancel();
    await _playerStateSub?.cancel();
    await _globalPositionSub?.cancel();
    await _globalDurationSub?.cancel();
    await _seekReadySub?.cancel();
    await _playbackModeSub?.cancel();
    await _playbackCompletedSub?.cancel();
    return super.close();
  }
}
