import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../core/services/audio_player_service.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/repositories/download_repository.dart';
import 'quran_settings_cubit.dart';

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
  StreamSubscription<QueuedSurahChange>? _queuedSurahPlayingSub;
  final int Function(int max) _nextRandomInt;
  final List<int> _shuffleHistory = <int>[];
  bool _isAdvancingQueue = false;
  int _navigationToken = 0;
  bool _isTopUpInFlight = false;

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
    _audioPlayerService.configureChapterNavigation(
      onNextChapter: playNextSurah,
      onPreviousChapter: playPreviousSurah,
      canGoNextChapter: () => state.canGoNext,
      canGoPreviousChapter: () => state.canGoPrevious,
    );
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
      // Switching to a looping/random mode mid-playback means we suddenly need
      // a queued surah ahead; switching back to off/repeatOne doesn't undo a
      // surah we already appended (it will just play and stop at the end).
      if (playbackMode == PlaybackMode.repeatAll ||
          playbackMode == PlaybackMode.shuffle) {
        unawaited(_topUpQueueIfNeeded());
      }
    });
    _playbackCompletedSub = _audioPlayerService.playbackCompleted.listen(
      handlePlaybackCompleted,
    );
    _queuedSurahPlayingSub = _audioPlayerService.queuedSurahPlaying.listen((
      _,
    ) {
      // The player just transitioned (gaplessly) into the next surah we had
      // queued. Top up the queue again so the *next* surah is ready before
      // this one ends — this is what keeps iOS background audio alive.
      unawaited(_topUpQueueIfNeeded());
    });
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
    // Capture a token so that if another navigation starts while this one is
    // awaiting I/O, the older call detects it has been superseded and exits
    // before touching the audio player. This prevents concurrent stop/load
    // calls that cause the MediaCodec dead-thread crash on Android.
    final myToken = ++_navigationToken;

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
      final translation = await QuranSettingsCubit.getCurrentTranslation();
      final localizedSurahName = QuranSettingsCubit.getSurahNameInTranslation(
        surahNumber,
        translation,
      );
      final ayahAudios = await _audioRepository.getAyahAudios(
        reciterId,
        surahNumber,
      );
      if (myToken != _navigationToken) {
        if (isQueueAdvance) _isAdvancingQueue = false;
        return;
      }
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
          if (myToken != _navigationToken) {
            if (isQueueAdvance) _isAdvancingQueue = false;
            return;
          }
          final warmedAyahs = await _audioRepository.getAyahAudios(
            reciterId,
            surahNumber,
          );
          if (myToken != _navigationToken) {
            if (isQueueAdvance) _isAdvancingQueue = false;
            return;
          }
          ayahDurations = warmedAyahs.map((audio) => audio.duration).toList();
        } catch (_) {
          // Continue with partial durations.
          if (myToken != _navigationToken) {
            if (isQueueAdvance) _isAdvancingQueue = false;
            return;
          }
        }
      }

      await _audioPlayerService.playSurahPlaylist(
        filePaths: filePaths,
        surahNumber: surahNumber,
        reciterId: reciterId,
        surahName: localizedSurahName,
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
          surahName: localizedSurahName,
          shuffleHistoryDepth: _shuffleHistory.length,
        ),
      );

      // With the new surah playing, prepare the *next* one ahead of time so
      // the player can transition gaplessly when this surah ends. iOS will
      // suspend the app the moment audio actually stops in background, so we
      // can't rely on completion → fetch → setAudioSource — we must already
      // have the next ayah ready inside the active source.
      unawaited(_topUpQueueIfNeeded());
    } catch (_) {
      _isAdvancingQueue = false;
      rethrow;
    }
  }

  /// Compute the surah that should play after [currentSurahNumber] given the
  /// current playback mode, or `null` if nothing should be queued (off /
  /// repeatOne / empty queue).
  int? _nextSurahForQueue(int currentSurahNumber) {
    final queue = state.downloadedQueue;
    if (queue.isEmpty) return null;
    final currentIdx = queue.indexOf(currentSurahNumber);
    if (currentIdx < 0) return null;

    switch (state.playbackMode) {
      case PlaybackMode.repeatAll:
        final nextIdx = computeLinearQueueTarget(
          currentIndex: currentIdx,
          queueLength: queue.length,
          forward: true,
          wrap: true,
        );
        if (nextIdx == null) return null;
        return queue[nextIdx];
      case PlaybackMode.shuffle:
        return selectShuffleTarget(
          queue: queue,
          currentSurah: currentSurahNumber,
          nextInt: _nextRandomInt,
        );
      case PlaybackMode.off:
      case PlaybackMode.repeatOne:
        return null;
    }
  }

  /// Ensure the surah after the currently playing one is appended to the
  /// active ConcatenatingAudioSource. Safe to call repeatedly — the service
  /// dedupes if the same surah is already queued ahead.
  Future<void> _topUpQueueIfNeeded() async {
    if (_isTopUpInFlight) return;
    final reciterId = state.reciterId;
    final currentSurah = state.surahNumber;
    if (reciterId == null || currentSurah == null) return;
    if (_audioPlayerService.hasQueuedSurahAhead) return;

    final nextSurahNumber = _nextSurahForQueue(currentSurah);
    if (nextSurahNumber == null) return;

    _isTopUpInFlight = true;
    try {
      var ayahAudios = await _audioRepository.getAyahAudios(
        reciterId,
        nextSurahNumber,
      );
      if (ayahAudios.isEmpty) return;

      // Warm up durations *before* appending so the seeker has a valid total
      // duration the moment the player crosses into this segment. Without
      // this, the cached durations passed to appendSurahToQueue contain nulls,
      // computeTotalDuration returns null, and the seeker stays disabled even
      // while audio plays correctly.
      var ayahDurations = ayahAudios.map((audio) => audio.duration).toList();
      final hasMissingDurations = ayahDurations.any(
        (duration) => duration == null || duration.inMilliseconds <= 0,
      );
      if (hasMissingDurations) {
        try {
          await _audioRepository.warmUpAyahDurations(reciterId, nextSurahNumber);
          final warmedAyahs = await _audioRepository.getAyahAudios(
            reciterId,
            nextSurahNumber,
          );
          if (warmedAyahs.isNotEmpty) {
            ayahAudios = warmedAyahs;
            ayahDurations = warmedAyahs
                .map((audio) => audio.duration)
                .toList();
          }
        } catch (_) {
          // Fall through with whatever durations we have.
        }
      }

      if (state.reciterId != reciterId ||
          state.surahNumber != currentSurah ||
          _audioPlayerService.hasQueuedSurahAhead) {
        // The player's state changed while we were fetching; another top-up
        // will run on the new state if needed.
        return;
      }
      final translation = await QuranSettingsCubit.getCurrentTranslation();
      final localizedSurahName = QuranSettingsCubit.getSurahNameInTranslation(
        nextSurahNumber,
        translation,
      );
      await _audioPlayerService.appendSurahToQueue(
        filePaths: ayahAudios.map((audio) => audio.localPath).toList(),
        surahNumber: nextSurahNumber,
        reciterId: reciterId,
        surahName: localizedSurahName,
        ayahDurations: ayahDurations,
      );
    } catch (_) {
      // Best-effort; if queuing fails we'll fall back to handlePlaybackCompleted.
    } finally {
      _isTopUpInFlight = false;
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
    _audioPlayerService.clearChapterNavigation();
    await _audioSub?.cancel();
    await _playerStateSub?.cancel();
    await _globalPositionSub?.cancel();
    await _globalDurationSub?.cancel();
    await _seekReadySub?.cancel();
    await _playbackModeSub?.cancel();
    await _playbackCompletedSub?.cancel();
    await _queuedSurahPlayingSub?.cancel();
    return super.close();
  }
}
