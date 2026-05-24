import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

import 'audio_player_service.dart';
import '../config/localization/localization_service.dart';

class QuranAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  static const String _appAlbumLabel = 'Wolof Quran';
  static final Uri _androidArtworkUri = Uri.parse(
    'android.resource://com.saliouseck.wolofquran/mipmap/launcher_icon',
  );
  Uri _appArtworkUri = Uri.parse('asset:///assets/icon/app_icon.png');

  final AudioPlayerService _audioPlayerService;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String _languageCode = 'fr';

  QuranAudioHandler(this._audioPlayerService) {
    _subscriptions.add(
      _audioPlayerService.currentAudio.listen((_) => _broadcastMediaAndQueue()),
    );
    _subscriptions.add(
      _audioPlayerService.playerState.listen((_) => _broadcastPlaybackState()),
    );
    _subscriptions.add(
      _audioPlayerService.position.listen((_) => _broadcastPlaybackState()),
    );
    _subscriptions.add(
      _audioPlayerService.duration.listen((_) => _broadcastPlaybackState()),
    );
    _subscriptions.add(
      _audioPlayerService.surahGlobalPosition.listen(
        (_) => _broadcastPlaybackState(),
      ),
    );
    _subscriptions.add(
      _audioPlayerService.surahGlobalDuration.listen(
        (_) => _broadcastPlaybackState(),
      ),
    );

    _appArtworkUri = Platform.isAndroid
        ? _androidArtworkUri
        : Uri.parse('asset:///assets/icon/app_icon.png');
    unawaited(_prepareArtworkForPlatform());
    unawaited(_loadLanguagePreference());
    _broadcastMediaAndQueue();
    _broadcastPlaybackState();
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  @override
  Future<void> play() async {
    await _audioPlayerService.resume();
  }

  @override
  Future<void> pause() async {
    await _audioPlayerService.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayerService.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayerService.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await _audioPlayerService.skipToNextChapter();
  }

  @override
  Future<void> skipToPrevious() async {
    await _audioPlayerService.skipToPreviousChapter();
  }

  @override
  Future<void> onTaskRemoved() async {
    // Keep playback running when the app task is removed, similar to
    // dedicated audio players.
  }

  Future<void> _loadLanguagePreference() async {
    final saved = await LocalizationService.getSavedLanguageCode();
    _languageCode = saved ?? 'fr';
    _broadcastMediaAndQueue();
    _broadcastPlaybackState();
  }

  Future<void> _prepareArtworkForPlatform() async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      final byteData = await rootBundle.load('assets/icon/app_icon.png');
      final supportDir = await getApplicationSupportDirectory();
      final artworkFile = File('${supportDir.path}/lockscreen_app_icon.png');
      await artworkFile.writeAsBytes(
        byteData.buffer.asUint8List(),
        flush: true,
      );
      _appArtworkUri = Uri.file(artworkFile.path);
      _broadcastMediaAndQueue();
      _broadcastPlaybackState();
    } catch (_) {
      // Keep asset URI fallback if file generation fails.
    }
  }

  void _broadcastMediaAndQueue() {
    final currentAudio = _audioPlayerService.currentPlayingAudio;
    if (currentAudio == null) {
      queue.add(const <MediaItem>[]);
      mediaItem.add(null);
      return;
    }

    final reciterLabel = _reciterLabel(currentAudio.reciterId);
    final baseSurahName = _normalizedSurahName(currentAudio);
    final queueItems = _buildQueueItems(
      currentAudio: currentAudio,
      baseSurahName: baseSurahName,
      reciterLabel: reciterLabel,
    );
    queue.add(queueItems);

    if (queueItems.isEmpty) {
      mediaItem.add(
        _buildSingleMediaItem(
          currentAudio: currentAudio,
          baseSurahName: baseSurahName,
          reciterLabel: reciterLabel,
        ),
      );
      return;
    }

    final index = currentAudio.isPlaylist
        ? (currentAudio.ayahNumber ?? 0).clamp(0, queueItems.length - 1)
        : 0;
    mediaItem.add(queueItems[index]);
  }

  void _broadcastPlaybackState() {
    final currentAudio = _audioPlayerService.currentPlayingAudio;
    final playerState = _audioPlayerService.currentPlayerState;
    final isPlaying =
        playerState == AudioPlayerState.playing ||
        playerState == AudioPlayerState.loading;
    final canSkipPrevious = _audioPlayerService.canGoToPreviousChapter;
    final canSkipNext = _audioPlayerService.canGoToNextChapter;

    final controls = <MediaControl>[
      if (canSkipPrevious) MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      if (canSkipNext) MediaControl.skipToNext,
    ];

    final compactActionIndices = <int>[];
    if (canSkipPrevious) {
      compactActionIndices.add(0);
    }
    compactActionIndices.add(canSkipPrevious ? 1 : 0);
    if (canSkipNext) {
      compactActionIndices.add(canSkipPrevious ? 2 : 1);
    }

    final position = _audioPlayerService.isPlayingPlaylist
        ? _audioPlayerService.currentSurahGlobalPosition
        : _audioPlayerService.currentPosition;
    final duration = _audioPlayerService.isPlayingPlaylist
        ? _audioPlayerService.currentSurahGlobalDuration
        : _audioPlayerService.currentDuration;

    playbackState.add(
      PlaybackState(
        controls: controls,
        androidCompactActionIndices: compactActionIndices,
        systemActions: const <MediaAction>{MediaAction.seek},
        processingState: _mapProcessingState(playerState),
        playing: isPlaying,
        updatePosition: position,
        bufferedPosition: position,
        speed: 1.0,
        queueIndex: _currentQueueIndex(currentAudio),
      ),
    );

    if (duration != null) {
      final currentItem = mediaItem.valueOrNull;
      if (currentItem != null && currentItem.duration != duration) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    }
  }

  List<MediaItem> _buildQueueItems({
    required PlayingAudioInfo currentAudio,
    required String baseSurahName,
    required String reciterLabel,
  }) {
    if (!currentAudio.isPlaylist) {
      return <MediaItem>[
        _buildSingleMediaItem(
          currentAudio: currentAudio,
          baseSurahName: baseSurahName,
          reciterLabel: reciterLabel,
        ),
      ];
    }

    final length = _audioPlayerService.currentPlaylistLength;
    if (length <= 0) {
      return <MediaItem>[
        _buildSingleMediaItem(
          currentAudio: currentAudio,
          baseSurahName: baseSurahName,
          reciterLabel: reciterLabel,
        ),
      ];
    }

    return List<MediaItem>.generate(length, (index) {
      final ayahNumber = index + 1;
      return MediaItem(
        id:
            'surah_${currentAudio.surahNumber}_ayah_$ayahNumber'
            '_reciter_${currentAudio.reciterId}',
        title:
            '${currentAudio.surahNumber} $baseSurahName • ${_verseLabel()} $ayahNumber',
        artist: reciterLabel,
        album: _appAlbumLabel,
        artUri: _appArtworkUri,
        extras: <String, dynamic>{
          'surahNumber': currentAudio.surahNumber,
          'ayahNumber': ayahNumber,
          'reciterId': currentAudio.reciterId,
          'isPlaylist': true,
        },
      );
    });
  }

  MediaItem _buildSingleMediaItem({
    required PlayingAudioInfo currentAudio,
    required String baseSurahName,
    required String reciterLabel,
  }) {
    final ayahNumber = _displayAyahNumber(currentAudio);
    final title = ayahNumber == null
        ? '${currentAudio.surahNumber} $baseSurahName'
        : '${currentAudio.surahNumber} $baseSurahName • ${_verseLabel()} $ayahNumber';

    return MediaItem(
      id:
          'surah_${currentAudio.surahNumber}_ayah_${ayahNumber ?? 0}'
          '_reciter_${currentAudio.reciterId}',
      title: title,
      artist: reciterLabel,
      album: _appAlbumLabel,
      artUri: _appArtworkUri,
      extras: <String, dynamic>{
        'surahNumber': currentAudio.surahNumber,
        'ayahNumber': ayahNumber,
        'reciterId': currentAudio.reciterId,
        'isPlaylist': currentAudio.isPlaylist,
      },
    );
  }

  int _currentQueueIndex(PlayingAudioInfo? currentAudio) {
    if (currentAudio == null) {
      return 0;
    }
    if (!currentAudio.isPlaylist) {
      return 0;
    }
    final playlistIndex = currentAudio.ayahNumber ?? 0;
    return playlistIndex.clamp(
      0,
      (_audioPlayerService.currentPlaylistLength - 1).clamp(0, 1000000),
    );
  }

  int? _displayAyahNumber(PlayingAudioInfo audio) {
    final rawAyah = audio.ayahNumber;
    if (rawAyah == null) {
      return null;
    }
    if (audio.isPlaylist) {
      return rawAyah + 1;
    }
    return rawAyah;
  }

  String _normalizedSurahName(PlayingAudioInfo audio) {
    try {
      switch (_languageCode) {
        case 'ar':
          return quran.getSurahNameArabic(audio.surahNumber);
        case 'en':
          return quran.getSurahNameEnglish(audio.surahNumber);
        case 'fr':
        default:
          return quran.getSurahNameFrench(audio.surahNumber);
      }
    } catch (_) {
      switch (_languageCode) {
        case 'ar':
          return 'سورة ${audio.surahNumber}';
        case 'en':
          return 'Surah ${audio.surahNumber}';
        case 'fr':
        default:
          return 'Sourate ${audio.surahNumber}';
      }
    }
  }

  String _verseLabel() {
    switch (_languageCode) {
      case 'ar':
        return 'آية';
      case 'en':
        return 'Ayah';
      case 'fr':
      default:
        return 'Verset';
    }
  }

  String _reciterLabel(String reciterId) {
    switch (reciterId) {
      case 'imamsarr':
        return 'Imam Sarr';
      default:
        return reciterId;
    }
  }

  AudioProcessingState _mapProcessingState(AudioPlayerState state) {
    switch (state) {
      case AudioPlayerState.loading:
        return AudioProcessingState.loading;
      case AudioPlayerState.playing:
      case AudioPlayerState.paused:
        return AudioProcessingState.ready;
      case AudioPlayerState.error:
        return AudioProcessingState.error;
      case AudioPlayerState.stopped:
      case AudioPlayerState.idle:
        return AudioProcessingState.idle;
    }
  }
}
