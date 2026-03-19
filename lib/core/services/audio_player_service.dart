import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// Enum for audio player state
enum AudioPlayerState { idle, loading, playing, paused, stopped, error }

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
  final BehaviorSubject<bool> _repeatSurahSubject =
      BehaviorSubject<bool>.seeded(false);

  // Playlist management
  List<String> _currentPlaylist = [];
  List<Duration?> _playlistCachedDurations = [];
  int _currentPlaylistIndex = 0;
  bool _isPlayingPlaylist = false;

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
  Stream<bool> get repeatSurah => _repeatSurahSubject.stream;

  // Current values
  AudioPlayerState get currentPlayerState => _playerStateSubject.value;
  PlayingAudioInfo? get currentPlayingAudio => _currentAudioSubject.value;
  bool get isPlaying => currentPlayerState == AudioPlayerState.playing;
  bool get isPlayingPlaylist => _isPlayingPlaylist;
  Duration get currentSurahGlobalPosition => _surahGlobalPositionSubject.value;
  Duration? get currentSurahGlobalDuration => _surahGlobalDurationSubject.value;
  bool get isSurahSeekReady => _surahSeekReadySubject.value;
  bool get isRepeatSurahEnabled => _repeatSurahSubject.value;

  /// Initialize the audio player service
  void initialize() {
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

    _audioPlayer.currentIndexStream.listen((index) {
      if (!_isPlayingPlaylist || index == null) {
        return;
      }
      _currentPlaylistIndex = index;
      _syncCurrentAudioAyahIndex(index);
      _emitSurahTimeline();
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
      await _stop();
      _isPlayingPlaylist = false;

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
      await _stop();
      if (filePaths.isEmpty) {
        return;
      }

      _currentPlaylist = filePaths;
      _currentPlaylistIndex = startIndex.clamp(0, filePaths.length - 1);
      _isPlayingPlaylist = true;
      _playlistCachedDurations = _normalizeDurations(
        rawDurations: ayahDurations,
        expectedLength: filePaths.length,
      );

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
    await _audioPlayer.seek(seekTarget.offset, index: seekTarget.ayahIndex);
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
      await _audioPlayer.seek(Duration.zero, index: nextIndex);
      _emitSurahTimeline();
    }
  }

  /// Skip to previous track in playlist
  Future<void> skipToPrevious() async {
    if (_isPlayingPlaylist && _currentPlaylistIndex > 0) {
      final previousIndex = _currentPlaylistIndex - 1;
      _currentPlaylistIndex = previousIndex;
      _syncCurrentAudioAyahIndex(previousIndex);
      await _audioPlayer.seek(Duration.zero, index: previousIndex);
      _emitSurahTimeline();
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Enable/disable repeat for surah playlist.
  Future<void> setRepeatSurah(bool enabled) async {
    _repeatSurahSubject.add(enabled);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _playerStateSubject.close();
    await _currentAudioSubject.close();
    await _positionSubject.close();
    await _durationSubject.close();
    await _surahGlobalPositionSubject.close();
    await _surahGlobalDurationSubject.close();
    await _surahSeekReadySubject.close();
    await _repeatSurahSubject.close();
  }

  /// Handle playback completion
  Future<void> _handlePlaybackCompleted() async {
    if (_isPlayingPlaylist) {
      if (_repeatSurahSubject.value && _currentPlaylist.isNotEmpty) {
        _currentPlaylistIndex = 0;
        _syncCurrentAudioAyahIndex(0);
        await _audioPlayer.seek(Duration.zero, index: 0);
        await _audioPlayer.play();
        _emitSurahTimeline();
        return;
      }
      _isPlayingPlaylist = false;
      _playerStateSubject.add(AudioPlayerState.stopped);
      _currentAudioSubject.add(null);
      _resetSurahTimeline();
      return;
    }

    _playerStateSubject.add(AudioPlayerState.stopped);
    _currentAudioSubject.add(null);
    _resetSurahTimeline();
  }

  /// Internal stop method
  Future<void> _stop() async {
    await _audioPlayer.stop();
    _isPlayingPlaylist = false;
    _currentPlaylist.clear();
    _playlistCachedDurations.clear();
    _currentPlaylistIndex = 0;
    _currentAudioSubject.add(null);
    _playerStateSubject.add(AudioPlayerState.stopped);
    _positionSubject.add(Duration.zero);
    _durationSubject.add(null);
    _resetSurahTimeline();
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
    final rawPosition = computeGlobalPosition(
      segmentDurations: durations,
      currentIndex: _audioPlayer.currentIndex ?? _currentPlaylistIndex,
      currentPosition: _positionSubject.value,
    );

    final position = total != null && rawPosition > total ? total : rawPosition;
    _surahGlobalPositionSubject.add(position);
    _surahGlobalDurationSubject.add(total);
    _surahSeekReadySubject.add(total != null && total.inMilliseconds > 0);
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
    return sequence.map((source) => source.duration).toList();
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
