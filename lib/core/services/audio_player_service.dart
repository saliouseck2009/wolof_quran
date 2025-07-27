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

  // Playlist management
  List<String> _currentPlaylist = [];
  int _currentPlaylistIndex = 0;
  bool _isPlayingPlaylist = false;

  // Getters for streams
  Stream<AudioPlayerState> get playerState => _playerStateSubject.stream;
  Stream<PlayingAudioInfo?> get currentAudio => _currentAudioSubject.stream;
  Stream<Duration> get position => _positionSubject.stream;
  Stream<Duration?> get duration => _durationSubject.stream;

  // Current values
  AudioPlayerState get currentPlayerState => _playerStateSubject.value;
  PlayingAudioInfo? get currentPlayingAudio => _currentAudioSubject.value;
  bool get isPlaying => currentPlayerState == AudioPlayerState.playing;
  bool get isPlayingPlaylist => _isPlayingPlaylist;

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
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _durationSubject.add(duration);
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
    int startIndex = 0,
  }) async {
    try {
      await _stop();

      _currentPlaylist = filePaths;
      _currentPlaylistIndex = startIndex;
      _isPlayingPlaylist = true;

      _currentAudioSubject.add(
        PlayingAudioInfo(
          surahNumber: surahNumber,
          ayahNumber: startIndex + 1, // Ayah numbers are 1-based
          reciterId: reciterId,
          surahName: surahName,
          isPlaylist: true,
        ),
      );

      if (_currentPlaylist.isNotEmpty &&
          _currentPlaylistIndex < _currentPlaylist.length) {
        await _audioPlayer.setFilePath(_currentPlaylist[_currentPlaylistIndex]);
        await _audioPlayer.play();
      }
    } catch (e) {
      _playerStateSubject.add(AudioPlayerState.error);
      rethrow;
    }
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
    await _audioPlayer.seek(position);
  }

  /// Skip to next track in playlist
  Future<void> skipToNext() async {
    if (_isPlayingPlaylist &&
        _currentPlaylistIndex < _currentPlaylist.length - 1) {
      _currentPlaylistIndex++;
      await _playCurrentPlaylistItem();
    }
  }

  /// Skip to previous track in playlist
  Future<void> skipToPrevious() async {
    if (_isPlayingPlaylist && _currentPlaylistIndex > 0) {
      _currentPlaylistIndex--;
      await _playCurrentPlaylistItem();
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _playerStateSubject.close();
    await _currentAudioSubject.close();
    await _positionSubject.close();
    await _durationSubject.close();
  }

  /// Handle playback completion
  void _handlePlaybackCompleted() {
    if (_isPlayingPlaylist) {
      _playNextInPlaylist();
    } else {
      _playerStateSubject.add(AudioPlayerState.stopped);
      _currentAudioSubject.add(null);
    }
  }

  /// Play next item in playlist
  Future<void> _playNextInPlaylist() async {
    if (_currentPlaylistIndex < _currentPlaylist.length - 1) {
      _currentPlaylistIndex++;
      await _playCurrentPlaylistItem();
    } else {
      // Playlist finished
      _isPlayingPlaylist = false;
      _playerStateSubject.add(AudioPlayerState.stopped);
      _currentAudioSubject.add(null);
    }
  }

  /// Play current item in playlist
  Future<void> _playCurrentPlaylistItem() async {
    if (_currentPlaylistIndex < _currentPlaylist.length) {
      final currentAudio = _currentAudioSubject.value;
      if (currentAudio != null) {
        _currentAudioSubject.add(
          PlayingAudioInfo(
            surahNumber: currentAudio.surahNumber,
            ayahNumber: _currentPlaylistIndex + 1, // Ayah numbers are 1-based
            reciterId: currentAudio.reciterId,
            surahName: currentAudio.surahName,
            isPlaylist: true,
          ),
        );
      }

      await _audioPlayer.setFilePath(_currentPlaylist[_currentPlaylistIndex]);
      await _audioPlayer.play();
    }
  }

  /// Internal stop method
  Future<void> _stop() async {
    await _audioPlayer.stop();
    _isPlayingPlaylist = false;
    _currentPlaylist.clear();
    _currentPlaylistIndex = 0;
    _currentAudioSubject.add(null);
    _playerStateSubject.add(AudioPlayerState.stopped);
  }
}
