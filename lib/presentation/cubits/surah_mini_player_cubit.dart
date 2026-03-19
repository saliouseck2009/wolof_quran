import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../core/services/audio_player_service.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/repositories/download_repository.dart';

enum SurahMiniPlayerUiState { hidden, collapsed, expanded }

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
  final bool repeatSurah;

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
    this.repeatSurah = false,
  });

  bool get hasActiveSurah => reciterId != null && surahNumber != null;

  int get currentQueueIndex {
    if (surahNumber == null) {
      return -1;
    }
    return downloadedQueue.indexOf(surahNumber!);
  }

  bool get canGoPrevious => currentQueueIndex > 0;

  bool get canGoNext =>
      currentQueueIndex >= 0 && currentQueueIndex < downloadedQueue.length - 1;

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
    bool? repeatSurah,
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
      repeatSurah: repeatSurah ?? this.repeatSurah,
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
    repeatSurah,
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
  StreamSubscription<bool>? _repeatSub;

  SurahMiniPlayerCubit({
    required AudioPlayerService audioPlayerService,
    required DownloadRepository downloadRepository,
    required AudioRepository audioRepository,
  }) : _audioPlayerService = audioPlayerService,
       _downloadRepository = downloadRepository,
       _audioRepository = audioRepository,
       super(
         SurahMiniPlayerState(
           playerState: audioPlayerService.currentPlayerState,
           position: audioPlayerService.currentSurahGlobalPosition,
           duration: audioPlayerService.currentSurahGlobalDuration,
           isSeekReady: audioPlayerService.isSurahSeekReady,
           repeatSurah: audioPlayerService.isRepeatSurahEnabled,
         ),
       ) {
    _listenToPlayerStreams();
  }

  void _listenToPlayerStreams() {
    _audioSub = _audioPlayerService.currentAudio.listen(_handleCurrentAudio);
    _playerStateSub = _audioPlayerService.playerState.listen((playerState) {
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
    _repeatSub = _audioPlayerService.repeatSurah.listen((repeatEnabled) {
      emit(state.copyWith(repeatSurah: repeatEnabled));
    });
  }

  Future<void> _handleCurrentAudio(PlayingAudioInfo? audioInfo) async {
    if (audioInfo == null || !audioInfo.isPlaylist) {
      emit(
        state.copyWith(
          uiState: SurahMiniPlayerUiState.hidden,
          clearTrack: true,
          position: Duration.zero,
          clearDuration: true,
        ),
      );
      return;
    }

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
      ),
    );

    await refreshQueueForReciter(audioInfo.reciterId);
  }

  Future<void> attachToCurrentPlayback({bool expanded = true}) async {
    final current = _audioPlayerService.currentPlayingAudio;
    if (current == null || !current.isPlaylist) {
      return;
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

  Future<void> closePlayer() async {
    await _audioPlayerService.stop();
    emit(
      state.copyWith(
        uiState: SurahMiniPlayerUiState.hidden,
        clearTrack: true,
        position: Duration.zero,
        clearDuration: true,
      ),
    );
  }

  Future<void> togglePlayPause() async {
    switch (state.playerState) {
      case AudioPlayerState.playing:
      case AudioPlayerState.loading:
        await _audioPlayerService.pause();
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

  Future<void> toggleRepeat() async {
    await _audioPlayerService.setRepeatSurah(!state.repeatSurah);
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

    emit(state.copyWith(downloadedQueue: queue));
  }

  Future<void> playPreviousSurah() async {
    if (!state.canGoPrevious) {
      return;
    }

    final target = state.downloadedQueue[state.currentQueueIndex - 1];
    await _playSurahFromQueue(target);
  }

  Future<void> playNextSurah() async {
    if (!state.canGoNext) {
      return;
    }

    final target = state.downloadedQueue[state.currentQueueIndex + 1];
    await _playSurahFromQueue(target);
  }

  Future<void> _playSurahFromQueue(int surahNumber) async {
    final reciterId = state.reciterId;
    if (reciterId == null) {
      return;
    }

    final ayahAudios = await _audioRepository.getAyahAudios(
      reciterId,
      surahNumber,
    );
    if (ayahAudios.isEmpty) {
      return;
    }

    final filePaths = ayahAudios.map((audio) => audio.localPath).toList();
    final ayahDurations = ayahAudios.map((audio) => audio.duration).toList();
    final hasMissingDurations = ayahDurations.any(
      (duration) => duration == null || duration.inMilliseconds <= 0,
    );

    await _audioPlayerService.playSurahPlaylist(
      filePaths: filePaths,
      surahNumber: surahNumber,
      reciterId: reciterId,
      surahName: quran.getSurahNameEnglish(surahNumber),
      ayahDurations: ayahDurations,
      startIndex: 0,
    );

    if (hasMissingDurations) {
      unawaited(_warmUpDurationsAndUpdateTimeline(reciterId, surahNumber));
    }

    emit(
      state.copyWith(
        uiState: SurahMiniPlayerUiState.expanded,
        surahNumber: surahNumber,
        surahName: quran.getSurahNameEnglish(surahNumber),
      ),
    );
  }

  Future<void> _warmUpDurationsAndUpdateTimeline(
    String reciterId,
    int surahNumber,
  ) async {
    try {
      await _audioRepository.warmUpAyahDurations(reciterId, surahNumber);
      final ayahAudios = await _audioRepository.getAyahAudios(
        reciterId,
        surahNumber,
      );
      final durations = ayahAudios.map((audio) => audio.duration).toList();
      _audioPlayerService.updatePlaylistDurations(
        reciterId: reciterId,
        surahNumber: surahNumber,
        durations: durations,
      );
    } catch (_) {
      // Keep current timeline; runtime durations can still fill over time.
    }
  }

  @override
  Future<void> close() async {
    await _audioSub?.cancel();
    await _playerStateSub?.cancel();
    await _globalPositionSub?.cancel();
    await _globalDurationSub?.cancel();
    await _seekReadySub?.cancel();
    await _repeatSub?.cancel();
    return super.close();
  }
}
