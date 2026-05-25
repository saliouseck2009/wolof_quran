import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Enum for audio player state
enum AudioPlayerState { idle, loading, playing, paused, stopped, error }

enum PlaybackMode { off, repeatOne, repeatAll, shuffle }

extension PlaybackModeX on PlaybackMode {
  String get prefsValue {
    switch (this) {
      case PlaybackMode.off:
        return 'off';
      case PlaybackMode.repeatOne:
        return 'repeat_one';
      case PlaybackMode.repeatAll:
        return 'repeat_all';
      case PlaybackMode.shuffle:
        return 'shuffle';
    }
  }

  static PlaybackMode fromPrefs(String? raw) {
    switch (raw) {
      case 'repeat_one':
        return PlaybackMode.repeatOne;
      case 'repeat_all':
        return PlaybackMode.repeatAll;
      case 'shuffle':
        return PlaybackMode.shuffle;
      case 'off':
      default:
        return PlaybackMode.off;
    }
  }
}

/// Model for current playing audio info
class PlayingAudioInfo {
  final int surahNumber;
  final int? ayahNumber;
  final String reciterId;
  final String? surahName;
  final bool isPlaylist;

  const PlayingAudioInfo({
    required this.surahNumber,
    this.ayahNumber,
    required this.reciterId,
    this.surahName,
    this.isPlaylist = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingAudioInfo &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber &&
          ayahNumber == other.ayahNumber &&
          reciterId == other.reciterId;

  @override
  int get hashCode =>
      surahNumber.hashCode ^ ayahNumber.hashCode ^ reciterId.hashCode;
}

/// Target inside a split ayah playlist for a global surah seek.
class SurahSeekTarget {
  final int ayahIndex;
  final Duration offset;

  const SurahSeekTarget({required this.ayahIndex, required this.offset});
}

class PlaybackCompletedEvent {
  final PlayingAudioInfo audioInfo;
  final PlaybackMode playbackMode;

  const PlaybackCompletedEvent({
    required this.audioInfo,
    required this.playbackMode,
  });
}

/// A queued surah inside the active ConcatenatingAudioSource. Each segment
/// occupies a contiguous range of indices `[startIndex, startIndex + length)`.
/// Multiple segments let the player transition between surahs gaplessly,
/// which is required to keep iOS background audio alive across queue advances.
class _PlaylistSegment {
  final int surahNumber;
  final String reciterId;
  final String? surahName;
  final int startIndex;
  final int length;
  final List<String> filePaths;
  List<Duration?> ayahDurations;

  _PlaylistSegment({
    required this.surahNumber,
    required this.reciterId,
    required this.surahName,
    required this.startIndex,
    required this.length,
    required this.filePaths,
    required this.ayahDurations,
  });

  int get endIndex => startIndex + length;
  bool containsGlobalIndex(int idx) => idx >= startIndex && idx < endIndex;
}

class QueuedSurahChange {
  final int surahNumber;
  final String reciterId;
  final String? surahName;

  const QueuedSurahChange({
    required this.surahNumber,
    required this.reciterId,
    required this.surahName,
  });
}

/// Global audio player service using just_audio
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Streams for reactive state management
  final BehaviorSubject<AudioPlayerState> _playerStateSubject =
      BehaviorSubject<AudioPlayerState>.seeded(AudioPlayerState.idle);
  final BehaviorSubject<PlayingAudioInfo?> _currentAudioSubject =
      BehaviorSubject<PlayingAudioInfo?>.seeded(null);
  final BehaviorSubject<Duration> _positionSubject =
      BehaviorSubject<Duration>.seeded(Duration.zero);
  final BehaviorSubject<Duration?> _durationSubject =
      BehaviorSubject<Duration?>.seeded(null);
  final BehaviorSubject<Duration> _surahGlobalPositionSubject =
      BehaviorSubject<Duration>.seeded(Duration.zero);
  final BehaviorSubject<Duration?> _surahGlobalDurationSubject =
      BehaviorSubject<Duration?>.seeded(null);
  final BehaviorSubject<bool> _surahSeekReadySubject =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<PlaybackMode> _playbackModeSubject =
      BehaviorSubject<PlaybackMode>.seeded(PlaybackMode.off);
  final PublishSubject<PlaybackCompletedEvent> _playbackCompletedSubject =
      PublishSubject<PlaybackCompletedEvent>();

  // Playlist management. _currentPlaylist / _currentPlaylistIndex /
  // _playlistCachedDurations are LOCAL to the currently-playing segment; they
  // mirror `_segments[_currentSegmentIdx]` so the rest of the service can
  // continue to reason about a single surah at a time.
  List<String> _currentPlaylist = [];
  List<Duration?> _playlistCachedDurations = [];
  int _currentPlaylistIndex = 0;
  bool _isPlayingPlaylist = false;
  final List<_PlaylistSegment> _segments = [];
  int? _currentSegmentIdx;
  final PublishSubject<QueuedSurahChange> _queuedSurahPlayingSubject =
      PublishSubject<QueuedSurahChange>();
  bool _initialized = false;
  Future<void>? _initializationFuture;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;
  Future<void> Function()? _chapterNextDelegate;
  Future<void> Function()? _chapterPreviousDelegate;
  bool Function()? _canGoChapterNextDelegate;
  bool Function()? _canGoChapterPreviousDelegate;

  static const String _playbackModeKey = 'audio_playback_mode';

  // Getters for streams
  Stream<AudioPlayerState> get playerState => _playerStateSubject.stream;
  Stream<PlayingAudioInfo?> get currentAudio => _currentAudioSubject.stream;
  Stream<Duration> get position => _positionSubject.stream;
  Stream<Duration?> get duration => _durationSubject.stream;
  Stream<Duration> get surahGlobalPosition =>
      _surahGlobalPositionSubject.stream;
  Stream<Duration?> get surahGlobalDuration =>
      _surahGlobalDurationSubject.stream;
  Stream<bool> get surahSeekReady => _surahSeekReadySubject.stream;
  Stream<PlaybackMode> get playbackMode => _playbackModeSubject.stream;
  Stream<PlaybackCompletedEvent> get playbackCompleted =>
      _playbackCompletedSubject.stream;

  /// Emits when the player crosses into a new surah segment that was
  /// previously queued via [appendSurahToQueue]. Consumers should use this
  /// to update their notion of "currently playing surah" and to top up the
  /// queue with the next surah ahead of time.
  Stream<QueuedSurahChange> get queuedSurahPlaying =>
      _queuedSurahPlayingSubject.stream;

  // Current values
  AudioPlayerState get currentPlayerState => _playerStateSubject.value;
  PlayingAudioInfo? get currentPlayingAudio => _currentAudioSubject.value;
  bool get isPlaying => currentPlayerState == AudioPlayerState.playing;
  bool get isPlayingPlaylist => _isPlayingPlaylist;
  int get currentPlaylistIndex => _currentPlaylistIndex;
  int get currentPlaylistLength => _currentPlaylist.length;
  bool get canSkipToNext =>
      _isPlayingPlaylist && _currentPlaylistIndex < _currentPlaylist.length - 1;
  bool get canSkipToPrevious => _isPlayingPlaylist && _currentPlaylistIndex > 0;
  bool get canGoToNextChapter => _canGoChapterNextDelegate?.call() ?? false;
  bool get canGoToPreviousChapter =>
      _canGoChapterPreviousDelegate?.call() ?? false;
  Duration get currentPosition => _positionSubject.value;
  Duration? get currentDuration => _durationSubject.value;
  Duration get currentSurahGlobalPosition => _surahGlobalPositionSubject.value;
  Duration? get currentSurahGlobalDuration => _surahGlobalDurationSubject.value;
  bool get isSurahSeekReady => _surahSeekReadySubject.value;
  PlaybackMode get currentPlaybackMode => _playbackModeSubject.value;

  /// Initialize the audio player service
  Future<void> initialize() {
    _initializationFuture ??= _initializeInternal();
    return _initializationFuture!;
  }

  Future<void> _initializeInternal() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await reloadPlaybackModeFromPrefs();
    await _configureAudioSession();

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      switch (playerState.processingState) {
        case ProcessingState.idle:
          _playerStateSubject.add(AudioPlayerState.idle);
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          _playerStateSubject.add(AudioPlayerState.loading);
          break;
        case ProcessingState.ready:
          if (_audioPlayer.playing) {
            _playerStateSubject.add(AudioPlayerState.playing);
          } else {
            _playerStateSubject.add(AudioPlayerState.paused);
          }
          break;
        case ProcessingState.completed:
          _handlePlaybackCompleted();
          break;
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _positionSubject.add(position);
      _emitSurahTimeline();
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _durationSubject.add(duration);
      _emitSurahTimeline();
    });

    _audioPlayer.currentIndexStream.listen((globalIndex) {
      if (!_isPlayingPlaylist || globalIndex == null) {
        return;
      }
      _handleGlobalIndexChange(globalIndex);
    });

    _audioPlayer.sequenceStateStream.listen((_) {
      _emitSurahTimeline();
    });
  }

  /// Play a single ayah
  Future<void> playAyah({
    required String filePath,
    required int surahNumber,
    required int ayahNumber,
    required String reciterId,
    String? surahName,
  }) async {
    try {
      await _replaceCurrentPlayback();

      _currentAudioSubject.add(
        PlayingAudioInfo(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          reciterId: reciterId,
          surahName: surahName,
          isPlaylist: false,
        ),
      );

      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
      _emitSurahTimeline();
    } catch (e) {
      _playerStateSubject.add(AudioPlayerState.error);
      rethrow;
    }
  }

  /// Play an entire surah as a playlist
  Future<void> playSurahPlaylist({
    required List<String> filePaths,
    required int surahNumber,
    required String reciterId,
    String? surahName,
    List<Duration?>? ayahDurations,
    int startIndex = 0,
  }) async {
    try {
      await _replaceCurrentPlayback();
      if (filePaths.isEmpty) {
        return;
      }

      final normalizedDurations = _normalizeDurations(
        rawDurations: ayahDurations,
        expectedLength: filePaths.length,
      );

      _segments
        ..clear()
        ..add(
          _PlaylistSegment(
            surahNumber: surahNumber,
            reciterId: reciterId,
            surahName: surahName,
            startIndex: 0,
            length: filePaths.length,
            filePaths: List<String>.from(filePaths),
            ayahDurations: List<Duration?>.from(normalizedDurations),
          ),
        );
      _currentSegmentIdx = 0;

      _currentPlaylist = List<String>.from(filePaths);
      _currentPlaylistIndex = startIndex.clamp(0, filePaths.length - 1);
      _isPlayingPlaylist = true;
      _playlistCachedDurations = List<Duration?>.from(normalizedDurations);

      _currentAudioSubject.add(
        PlayingAudioInfo(
          surahNumber: surahNumber,
          ayahNumber: _currentPlaylistIndex, // 0-based index in playlist
          reciterId: reciterId,
          surahName: surahName,
          isPlaylist: true,
        ),
      );

      final source = ConcatenatingAudioSource(
        useLazyPreparation: false,
        children: filePaths.map((path) => AudioSource.file(path)).toList(),
      );

      await _audioPlayer.setAudioSource(
        source,
        initialIndex: _currentPlaylistIndex,
        initialPosition: Duration.zero,
      );
      _emitSurahTimeline();
      await _audioPlayer.play();
    } catch (e) {
      _playerStateSubject.add(AudioPlayerState.error);
      rethrow;
    }
  }

  /// Append the next surah's ayahs to the currently playing ConcatenatingAudioSource.
  ///
  /// The player transitions across surah boundaries without ever stopping its
  /// audio output. This is what keeps iOS background audio alive during
  /// `repeat all` / `shuffle` queue advances — iOS only keeps a backgrounded
  /// app running while audio is actively being produced.
  ///
  /// Returns `true` if the surah was queued, `false` otherwise (e.g. nothing
  /// is currently playing, or the source isn't a ConcatenatingAudioSource).
  Future<bool> appendSurahToQueue({
    required List<String> filePaths,
    required int surahNumber,
    required String reciterId,
    String? surahName,
    List<Duration?>? ayahDurations,
  }) async {
    if (!_isPlayingPlaylist || filePaths.isEmpty || _segments.isEmpty) {
      return false;
    }
    final source = _audioPlayer.audioSource;
    if (source is! ConcatenatingAudioSource) {
      return false;
    }
    // Skip if the surah is already queued ahead of the currently-playing one
    // (avoids unbounded growth when the cubit re-triggers a top-up).
    final currentIdx = _currentSegmentIdx ?? 0;
    final alreadyQueuedAhead = _segments
        .skip(currentIdx + 1)
        .any(
          (segment) =>
              segment.surahNumber == surahNumber &&
              segment.reciterId == reciterId,
        );
    if (alreadyQueuedAhead) {
      return false;
    }

    final startIndex = _segments.last.endIndex;
    final normalizedDurations = _normalizeDurations(
      rawDurations: ayahDurations,
      expectedLength: filePaths.length,
    );

    try {
      await source.addAll(
        filePaths.map((path) => AudioSource.file(path)).toList(),
      );
    } catch (_) {
      return false;
    }

    _segments.add(
      _PlaylistSegment(
        surahNumber: surahNumber,
        reciterId: reciterId,
        surahName: surahName,
        startIndex: startIndex,
        length: filePaths.length,
        filePaths: List<String>.from(filePaths),
        ayahDurations: List<Duration?>.from(normalizedDurations),
      ),
    );
    return true;
  }

  bool get hasQueuedSurahAhead {
    final currentIdx = _currentSegmentIdx;
    if (currentIdx == null) return false;
    return currentIdx + 1 < _segments.length;
  }

  /// The surah currently expected to play after the active one, if any was
  /// pre-queued via [appendSurahToQueue].
  QueuedSurahChange? get nextQueuedSurah {
    final currentIdx = _currentSegmentIdx;
    if (currentIdx == null) return null;
    if (currentIdx + 1 >= _segments.length) return null;
    final next = _segments[currentIdx + 1];
    return QueuedSurahChange(
      surahNumber: next.surahNumber,
      reciterId: next.reciterId,
      surahName: next.surahName,
    );
  }

  void _handleGlobalIndexChange(int globalIndex) {
    if (_segments.isEmpty) {
      _currentPlaylistIndex = globalIndex;
      _syncCurrentAudioAyahIndex(globalIndex);
      _emitSurahTimeline();
      return;
    }

    final segmentIdx = _findSegmentForGlobalIndex(globalIndex);
    if (segmentIdx == null) {
      return;
    }

    final segment = _segments[segmentIdx];
    final localIndex = globalIndex - segment.startIndex;

    if (segmentIdx != _currentSegmentIdx) {
      // The player crossed into a new surah without us stopping it — this is
      // the gapless transition path. Swap our "current segment" state to the
      // new surah and emit fresh now-playing info.
      _currentSegmentIdx = segmentIdx;
      _currentPlaylist = List<String>.from(segment.filePaths);
      _playlistCachedDurations = List<Duration?>.from(segment.ayahDurations);
      _currentPlaylistIndex = localIndex;

      _currentAudioSubject.add(
        PlayingAudioInfo(
          surahNumber: segment.surahNumber,
          ayahNumber: localIndex,
          reciterId: segment.reciterId,
          surahName: segment.surahName,
          isPlaylist: true,
        ),
      );
      _queuedSurahPlayingSubject.add(
        QueuedSurahChange(
          surahNumber: segment.surahNumber,
          reciterId: segment.reciterId,
          surahName: segment.surahName,
        ),
      );
    } else {
      _currentPlaylistIndex = localIndex;
      _syncCurrentAudioAyahIndex(localIndex);
    }

    _emitSurahTimeline();
  }

  int? _findSegmentForGlobalIndex(int globalIndex) {
    for (var i = 0; i < _segments.length; i++) {
      if (_segments[i].containsGlobalIndex(globalIndex)) {
        return i;
      }
    }
    return null;
  }

  int _globalIndexForLocal(int localIndex) {
    final segmentIdx = _currentSegmentIdx;
    if (segmentIdx == null) {
      return localIndex;
    }
    return _segments[segmentIdx].startIndex + localIndex;
  }

  /// Live update of known ayah durations for current surah playlist.
  void updatePlaylistDurations({
    required String reciterId,
    required int surahNumber,
    required List<Duration?> durations,
  }) {
    if (!_isPlayingPlaylist || _currentPlaylist.isEmpty) {
      return;
    }
    final current = _currentAudioSubject.value;
    if (current == null ||
        !current.isPlaylist ||
        current.reciterId != reciterId ||
        current.surahNumber != surahNumber) {
      return;
    }
    _playlistCachedDurations = _normalizeDurations(
      rawDurations: durations,
      expectedLength: _currentPlaylist.length,
    );
    final segmentIdx = _currentSegmentIdx;
    if (segmentIdx != null && segmentIdx < _segments.length) {
      _segments[segmentIdx].ayahDurations = List<Duration?>.from(
        _playlistCachedDurations,
      );
    }
    _emitSurahTimeline();
  }

  /// Pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  /// Stop playback
  Future<void> stop() async {
    await _stop();
  }

  void configureChapterNavigation({
    required Future<void> Function() onNextChapter,
    required Future<void> Function() onPreviousChapter,
    required bool Function() canGoNextChapter,
    required bool Function() canGoPreviousChapter,
  }) {
    _chapterNextDelegate = onNextChapter;
    _chapterPreviousDelegate = onPreviousChapter;
    _canGoChapterNextDelegate = canGoNextChapter;
    _canGoChapterPreviousDelegate = canGoPreviousChapter;
  }

  void clearChapterNavigation() {
    _chapterNextDelegate = null;
    _chapterPreviousDelegate = null;
    _canGoChapterNextDelegate = null;
    _canGoChapterPreviousDelegate = null;
  }

  Future<void> skipToNextChapter() async {
    final action = _chapterNextDelegate;
    if (action == null) {
      return;
    }
    await action();
  }

  Future<void> skipToPreviousChapter() async {
    final action = _chapterPreviousDelegate;
    if (action == null) {
      return;
    }
    await action();
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    if (_isPlayingPlaylist) {
      await seekWithinSurah(position);
      return;
    }
    await _audioPlayer.seek(position);
  }

  /// Seek on the global surah timeline, independent of ayah split.
  Future<void> seekWithinSurah(Duration target) async {
    if (!_isPlayingPlaylist) {
      await _audioPlayer.seek(target);
      return;
    }

    final segmentDurations = _playlistDurations();
    if (segmentDurations == null || segmentDurations.isEmpty) {
      return;
    }

    final seekTarget = mapGlobalSeekTarget(
      target: target,
      segmentDurations: segmentDurations,
    );
    _currentPlaylistIndex = seekTarget.ayahIndex;
    _syncCurrentAudioAyahIndex(seekTarget.ayahIndex);
    await _audioPlayer.seek(
      seekTarget.offset,
      index: _globalIndexForLocal(seekTarget.ayahIndex),
    );
    _emitSurahTimeline();
  }

  /// Seek relative to current position.
  Future<void> seekBy(Duration delta) async {
    if (_isPlayingPlaylist) {
      final target = computeSeekTarget(
        current: _surahGlobalPositionSubject.value,
        delta: delta,
        total: _surahGlobalDurationSubject.value,
      );
      await seekWithinSurah(target);
      return;
    }

    final target = computeSeekTarget(
      current: _positionSubject.value,
      delta: delta,
      total: _durationSubject.value,
    );

    await _audioPlayer.seek(target);
  }

  /// Skip to next track in playlist
  Future<void> skipToNext() async {
    if (_isPlayingPlaylist &&
        _currentPlaylistIndex < _currentPlaylist.length - 1) {
      final nextIndex = _currentPlaylistIndex + 1;
      _currentPlaylistIndex = nextIndex;
      _syncCurrentAudioAyahIndex(nextIndex);
      await _audioPlayer.seek(
        Duration.zero,
        index: _globalIndexForLocal(nextIndex),
      );
      _emitSurahTimeline();
    }
  }

  /// Skip to previous track in playlist
  Future<void> skipToPrevious() async {
    if (_isPlayingPlaylist && _currentPlaylistIndex > 0) {
      final previousIndex = _currentPlaylistIndex - 1;
      _currentPlaylistIndex = previousIndex;
      _syncCurrentAudioAyahIndex(previousIndex);
      await _audioPlayer.seek(
        Duration.zero,
        index: _globalIndexForLocal(previousIndex),
      );
      _emitSurahTimeline();
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  PlaybackMode nextPlaybackMode(PlaybackMode current) {
    switch (current) {
      case PlaybackMode.off:
        return PlaybackMode.repeatOne;
      case PlaybackMode.repeatOne:
        return PlaybackMode.repeatAll;
      case PlaybackMode.repeatAll:
        return PlaybackMode.shuffle;
      case PlaybackMode.shuffle:
        return PlaybackMode.off;
    }
  }

  Future<void> cyclePlaybackMode() async {
    await setPlaybackMode(nextPlaybackMode(currentPlaybackMode));
  }

  Future<void> setPlaybackMode(PlaybackMode mode) async {
    _playbackModeSubject.add(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_playbackModeKey, mode.prefsValue);
    } catch (_) {
      // Keep the in-memory mode even if persistence fails.
    }
  }

  Future<void> reloadPlaybackModeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_playbackModeKey);
      _playbackModeSubject.add(PlaybackModeX.fromPrefs(stored));
    } catch (_) {
      _playbackModeSubject.add(PlaybackMode.off);
    }
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      await _interruptionSub?.cancel();
      _interruptionSub = session.interruptionEventStream.listen((event) async {
        if (event.begin) {
          if (event.type == AudioInterruptionType.duck) {
            await _audioPlayer.setVolume(0.5);
            return;
          }
          await pause();
          return;
        }
        if (event.type == AudioInterruptionType.duck) {
          await _audioPlayer.setVolume(1.0);
        }
      });
      await _becomingNoisySub?.cancel();
      _becomingNoisySub = session.becomingNoisyEventStream.listen((_) async {
        await pause();
      });
    } catch (_) {
      // Audio playback still works without explicit session configuration,
      // but iOS background behavior is more reliable when this succeeds.
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _interruptionSub?.cancel();
    await _becomingNoisySub?.cancel();
    await _audioPlayer.dispose();
    await _playerStateSubject.close();
    await _currentAudioSubject.close();
    await _positionSubject.close();
    await _durationSubject.close();
    await _surahGlobalPositionSubject.close();
    await _surahGlobalDurationSubject.close();
    await _surahSeekReadySubject.close();
    await _playbackModeSubject.close();
    await _playbackCompletedSubject.close();
    await _queuedSurahPlayingSubject.close();
  }

  /// Handle playback completion
  Future<void> _handlePlaybackCompleted() async {
    final currentAudio = _currentAudioSubject.value;
    if (currentAudio == null) {
      await _stop();
      return;
    }
    final mode = _playbackModeSubject.value;

    if (_isPlayingPlaylist) {
      switch (mode) {
        case PlaybackMode.repeatOne:
          if (_currentPlaylist.isEmpty) {
            await _stop();
            return;
          }
          _currentPlaylistIndex = 0;
          _syncCurrentAudioAyahIndex(0);
          await _audioPlayer.seek(
            Duration.zero,
            index: _globalIndexForLocal(0),
          );
          await _audioPlayer.play();
          _emitSurahTimeline();
          return;
        case PlaybackMode.repeatAll:
        case PlaybackMode.shuffle:
          _playbackCompletedSubject.add(
            PlaybackCompletedEvent(audioInfo: currentAudio, playbackMode: mode),
          );
          return;
        case PlaybackMode.off:
          _playbackCompletedSubject.add(
            PlaybackCompletedEvent(audioInfo: currentAudio, playbackMode: mode),
          );
          _isPlayingPlaylist = false;
          _playerStateSubject.add(AudioPlayerState.stopped);
          _currentAudioSubject.add(null);
          _resetSurahTimeline();
          return;
      }
    }

    if (mode == PlaybackMode.repeatOne) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      _emitSurahTimeline();
      return;
    }

    _playbackCompletedSubject.add(
      PlaybackCompletedEvent(audioInfo: currentAudio, playbackMode: mode),
    );
    _playerStateSubject.add(AudioPlayerState.stopped);
    _currentAudioSubject.add(null);
    _resetSurahTimeline();
  }

  /// Internal stop method
  Future<void> _stop() async {
    await _audioPlayer.stop();
    _clearPlaybackSession(clearCurrentAudio: true, emitStoppedState: true);
  }

  Future<void> _replaceCurrentPlayback() async {
    // Do not call `_audioPlayer.stop()` here. On iOS, just_audio's stop()
    // deactivates the AVAudioSession (via `_setPlatformActive(false)`), which
    // makes the system suspend the app between tracks when playing in the
    // background — breaking `repeat all` queue advances. `setAudioSource()`
    // performs the source swap without dropping the active session.
    _clearPlaybackSession(clearCurrentAudio: false, emitStoppedState: false);
  }

  void _clearPlaybackSession({
    required bool clearCurrentAudio,
    required bool emitStoppedState,
  }) {
    _isPlayingPlaylist = false;
    _currentPlaylist.clear();
    _playlistCachedDurations.clear();
    _currentPlaylistIndex = 0;
    _segments.clear();
    _currentSegmentIdx = null;
    _positionSubject.add(Duration.zero);
    _durationSubject.add(null);
    _resetSurahTimeline();

    if (clearCurrentAudio) {
      _currentAudioSubject.add(null);
    }
    if (emitStoppedState) {
      _playerStateSubject.add(AudioPlayerState.stopped);
    }
  }

  void _syncCurrentAudioAyahIndex(int ayahIndex) {
    final currentAudio = _currentAudioSubject.value;
    if (currentAudio == null || !currentAudio.isPlaylist) {
      return;
    }

    _currentAudioSubject.add(
      PlayingAudioInfo(
        surahNumber: currentAudio.surahNumber,
        ayahNumber: ayahIndex,
        reciterId: currentAudio.reciterId,
        surahName: currentAudio.surahName,
        isPlaylist: true,
      ),
    );
  }

  void _emitSurahTimeline() {
    if (!_isPlayingPlaylist) {
      final singleDuration = _durationSubject.value;
      _surahGlobalPositionSubject.add(_positionSubject.value);
      _surahGlobalDurationSubject.add(singleDuration);
      _surahSeekReadySubject.add(
        singleDuration != null && singleDuration.inMilliseconds > 0,
      );
      return;
    }

    final durations = _effectivePlaylistDurations();
    if (durations.isEmpty) {
      _resetSurahTimeline();
      return;
    }

    final total = computeTotalDuration(durations);
    final localIndex = _localIndexForCurrentPosition();
    final rawPosition = computeGlobalPosition(
      segmentDurations: durations,
      currentIndex: localIndex,
      currentPosition: _positionSubject.value,
    );

    final position = total != null && rawPosition > total ? total : rawPosition;
    _surahGlobalPositionSubject.add(position);
    _surahGlobalDurationSubject.add(total);
    _surahSeekReadySubject.add(total != null && total.inMilliseconds > 0);
  }

  int _localIndexForCurrentPosition() {
    final globalIndex = _audioPlayer.currentIndex;
    final segmentIdx = _currentSegmentIdx;
    if (globalIndex != null &&
        segmentIdx != null &&
        segmentIdx < _segments.length) {
      final segment = _segments[segmentIdx];
      final relative = globalIndex - segment.startIndex;
      if (relative >= 0 && relative < segment.length) {
        return relative;
      }
    }
    return _currentPlaylistIndex;
  }

  void _resetSurahTimeline() {
    _surahGlobalPositionSubject.add(Duration.zero);
    _surahGlobalDurationSubject.add(null);
    _surahSeekReadySubject.add(false);
  }

  List<Duration?> _sequenceDurationsNullable() {
    final sequence = _audioPlayer.sequence;
    if (sequence == null || sequence.isEmpty) {
      return const [];
    }
    final segmentIdx = _currentSegmentIdx;
    if (segmentIdx == null || segmentIdx >= _segments.length) {
      return sequence.map((source) => source.duration).toList();
    }
    final segment = _segments[segmentIdx];
    final end = segment.endIndex.clamp(0, sequence.length);
    final start = segment.startIndex.clamp(0, end);
    return sequence
        .getRange(start, end)
        .map((source) => source.duration)
        .toList();
  }

  List<Duration?> _effectivePlaylistDurations() {
    final sequenceDurations = _sequenceDurationsNullable();
    if (_playlistCachedDurations.isEmpty) {
      return sequenceDurations;
    }
    final length = _playlistCachedDurations.length;
    final merged = List<Duration?>.from(_playlistCachedDurations);

    for (var i = 0; i < length && i < sequenceDurations.length; i++) {
      final runtime = sequenceDurations[i];
      if (runtime != null &&
          runtime.inMilliseconds > 0 &&
          (merged[i] == null || merged[i]!.inMilliseconds <= 0)) {
        merged[i] = runtime;
      }
    }

    _playlistCachedDurations = List<Duration?>.from(merged);
    return merged;
  }

  List<Duration>? _playlistDurations() {
    final durations = _effectivePlaylistDurations();
    if (durations.isEmpty || durations.any((duration) => duration == null)) {
      return null;
    }
    return durations.cast<Duration>();
  }

  List<Duration?> _normalizeDurations({
    required List<Duration?>? rawDurations,
    required int expectedLength,
  }) {
    if (expectedLength <= 0) {
      return const [];
    }
    if (rawDurations == null || rawDurations.isEmpty) {
      return List<Duration?>.filled(expectedLength, null);
    }

    final normalized = List<Duration?>.filled(expectedLength, null);
    for (var i = 0; i < expectedLength && i < rawDurations.length; i++) {
      final value = rawDurations[i];
      if (value != null && value.inMilliseconds > 0) {
        normalized[i] = value;
      }
    }
    return normalized;
  }

  /// Computes a clamped seek target from a delta.
  static Duration computeSeekTarget({
    required Duration current,
    required Duration delta,
    Duration? total,
  }) {
    var target = current + delta;
    if (target.isNegative) {
      target = Duration.zero;
    }
    if (total != null && target > total) {
      target = total;
    }
    return target;
  }

  /// Sum a list of segment durations. Returns null if at least one is unknown.
  static Duration? computeTotalDuration(List<Duration?> segmentDurations) {
    if (segmentDurations.isEmpty) {
      return null;
    }
    var totalMs = 0;
    for (final duration in segmentDurations) {
      if (duration == null) {
        return null;
      }
      totalMs += duration.inMilliseconds;
    }
    return Duration(milliseconds: totalMs);
  }

  /// Computes global position from segment durations and current item offset.
  static Duration computeGlobalPosition({
    required List<Duration?> segmentDurations,
    required int currentIndex,
    required Duration currentPosition,
  }) {
    if (segmentDurations.isEmpty) {
      return Duration.zero;
    }

    final safeIndex = currentIndex.clamp(0, segmentDurations.length - 1);
    var elapsedMs = 0;
    for (var i = 0; i < safeIndex; i++) {
      final duration = segmentDurations[i];
      if (duration != null) {
        elapsedMs += duration.inMilliseconds;
      }
    }
    elapsedMs += currentPosition.inMilliseconds;
    return Duration(milliseconds: elapsedMs);
  }

  /// Maps a global target to an ayah index + offset inside that ayah.
  static SurahSeekTarget mapGlobalSeekTarget({
    required Duration target,
    required List<Duration> segmentDurations,
  }) {
    if (segmentDurations.isEmpty) {
      return const SurahSeekTarget(ayahIndex: 0, offset: Duration.zero);
    }

    final totalMs = segmentDurations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    final clampedMs = target.inMilliseconds.clamp(0, totalMs);

    var cursor = 0;
    for (var index = 0; index < segmentDurations.length; index++) {
      final segmentMs = segmentDurations[index].inMilliseconds;
      final segmentEnd = cursor + segmentMs;
      if (clampedMs <= segmentEnd) {
        final offsetMs = clampedMs - cursor;
        return SurahSeekTarget(
          ayahIndex: index,
          offset: Duration(milliseconds: offsetMs.clamp(0, segmentMs)),
        );
      }
      cursor = segmentEnd;
    }

    final lastIndex = segmentDurations.length - 1;
    return SurahSeekTarget(
      ayahIndex: lastIndex,
      offset: segmentDurations[lastIndex],
    );
  }

  /// Returns the next playlist index or null if playback should end.
  static int? computeNextPlaylistIndex({
    required int currentIndex,
    required int playlistLength,
    required bool repeatEnabled,
  }) {
    if (playlistLength <= 0 ||
        currentIndex < 0 ||
        currentIndex >= playlistLength) {
      return null;
    }
    if (currentIndex < playlistLength - 1) {
      return currentIndex + 1;
    }
    if (repeatEnabled) {
      return 0;
    }
    return null;
  }
}
