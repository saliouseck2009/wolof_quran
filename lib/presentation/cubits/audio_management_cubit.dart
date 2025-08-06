import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/surah_audio_status.dart';
import '../../domain/entities/ayah_audio.dart';
import '../../domain/usecases/download_surah_audio_usecase.dart';
import '../../domain/usecases/get_surah_audio_status_usecase.dart';
import '../../domain/usecases/get_ayah_audios_usecase.dart';
import '../../domain/repositories/download_repository.dart';
import '../../core/services/audio_player_service.dart';

// States
abstract class AudioManagementState extends Equatable {
  const AudioManagementState();

  @override
  List<Object?> get props => [];
}

class AudioManagementInitial extends AudioManagementState {}

class AudioManagementLoading extends AudioManagementState {}

class AudioManagementLoaded extends AudioManagementState {
  final Map<String, SurahAudioStatus>
  surahStatusMap; // Key: "reciterId_surahNumber"
  final Map<String, List<AyahAudio>>
  ayahAudiosMap; // Key: "reciterId_surahNumber"

  const AudioManagementLoaded({
    required this.surahStatusMap,
    required this.ayahAudiosMap,
  });

  AudioManagementLoaded copyWith({
    Map<String, SurahAudioStatus>? surahStatusMap,
    Map<String, List<AyahAudio>>? ayahAudiosMap,
  }) {
    return AudioManagementLoaded(
      surahStatusMap: surahStatusMap ?? this.surahStatusMap,
      ayahAudiosMap: ayahAudiosMap ?? this.ayahAudiosMap,
    );
  }

  String _getKey(String reciterId, int surahNumber) =>
      '${reciterId}_$surahNumber';

  SurahAudioStatus? getSurahStatus(String reciterId, int surahNumber) {
    return surahStatusMap[_getKey(reciterId, surahNumber)];
  }

  List<AyahAudio> getAyahAudios(String reciterId, int surahNumber) {
    return ayahAudiosMap[_getKey(reciterId, surahNumber)] ?? [];
  }

  @override
  List<Object?> get props => [surahStatusMap, ayahAudiosMap];
}

class AudioManagementError extends AudioManagementState {
  final String message;

  const AudioManagementError(this.message);

  @override
  List<Object> get props => [message];
}

class AudioDownloading extends AudioManagementState {
  final String reciterId;
  final int surahNumber;
  final double progress;
  final Map<String, SurahAudioStatus> previousSurahStatusMap;
  final Map<String, List<AyahAudio>> previousAyahAudiosMap;

  const AudioDownloading({
    required this.reciterId,
    required this.surahNumber,
    required this.progress,
    required this.previousSurahStatusMap,
    required this.previousAyahAudiosMap,
  });

  @override
  List<Object> get props => [
    reciterId,
    surahNumber,
    progress,
    previousSurahStatusMap,
    previousAyahAudiosMap,
  ];
}

// Events
abstract class AudioManagementEvent extends Equatable {
  const AudioManagementEvent();

  @override
  List<Object> get props => [];
}

class LoadAudioData extends AudioManagementEvent {}

class DownloadSurahAudio extends AudioManagementEvent {
  final String reciterId;
  final int surahNumber;

  const DownloadSurahAudio({
    required this.reciterId,
    required this.surahNumber,
  });

  @override
  List<Object> get props => [reciterId, surahNumber];
}

class RefreshSurahStatus extends AudioManagementEvent {
  final String reciterId;
  final int surahNumber;

  const RefreshSurahStatus({
    required this.reciterId,
    required this.surahNumber,
  });

  @override
  List<Object> get props => [reciterId, surahNumber];
}

class LoadAyahAudios extends AudioManagementEvent {
  final String reciterId;
  final int surahNumber;

  const LoadAyahAudios({required this.reciterId, required this.surahNumber});

  @override
  List<Object> get props => [reciterId, surahNumber];
}

class PlayAyahAudio extends AudioManagementEvent {
  final AyahAudio ayahAudio;
  final String? surahName;

  const PlayAyahAudio({required this.ayahAudio, this.surahName});

  @override
  List<Object> get props => [ayahAudio, if (surahName != null) surahName!];
}

class PlaySurahPlaylist extends AudioManagementEvent {
  final String reciterId;
  final int surahNumber;
  final String? surahName;
  final int startAyahIndex;

  const PlaySurahPlaylist({
    required this.reciterId,
    required this.surahNumber,
    this.surahName,
    this.startAyahIndex = 0,
  });

  @override
  List<Object> get props => [
    reciterId,
    surahNumber,
    startAyahIndex,
    if (surahName != null) surahName!,
  ];
}

// Cubit
class AudioManagementCubit extends Cubit<AudioManagementState> {
  final DownloadSurahAudioUseCase downloadSurahAudioUseCase;
  final GetSurahAudioStatusUseCase getSurahAudioStatusUseCase;
  final GetAyahAudiosUseCase getAyahAudiosUseCase;
  final AudioPlayerService audioPlayerService;
  final DownloadRepository downloadRepository;

  StreamSubscription<double>? _downloadStreamSubscription;

  AudioManagementCubit({
    required this.downloadSurahAudioUseCase,
    required this.getSurahAudioStatusUseCase,
    required this.getAyahAudiosUseCase,
    required this.audioPlayerService,
    required this.downloadRepository,
  }) : super(AudioManagementInitial());

  @override
  Future<void> close() {
    _downloadStreamSubscription?.cancel();
    return super.close();
  }

  /// Initialize with empty data
  void initialize() {
    emit(const AudioManagementLoaded(surahStatusMap: {}, ayahAudiosMap: {}));
  }

  /// Download surah audio
  Future<void> downloadSurahAudio(String reciterId, int surahNumber) async {
    try {
      _downloadStreamSubscription?.cancel();

      // Get current state data
      Map<String, SurahAudioStatus> currentSurahStatusMap = {};
      Map<String, List<AyahAudio>> currentAyahAudiosMap = {};

      if (state is AudioManagementLoaded) {
        final loadedState = state as AudioManagementLoaded;
        currentSurahStatusMap = Map.from(loadedState.surahStatusMap);
        currentAyahAudiosMap = Map.from(loadedState.ayahAudiosMap);
      }

      // Mark download as in progress in database
      try {
        await downloadRepository.markSurahAsInProgress(
          reciterId,
          surahNumber,
          '',
        );
      } catch (e) {
        print('Could not mark download in database: $e');
        // Continue with download even if database marking fails
      }

      await downloadSurahAudioUseCase.call(
        params: DownloadSurahAudioParams(
          reciterId: reciterId,
          surahNumber: surahNumber,
          onProgress: (progress) {
            emit(
              AudioDownloading(
                reciterId: reciterId,
                surahNumber: surahNumber,
                progress: progress,
                previousSurahStatusMap: currentSurahStatusMap,
                previousAyahAudiosMap: currentAyahAudiosMap,
              ),
            );
          },
        ),
      );

      // Download completed, get the file path and mark as downloaded in database
      try {
        final downloadedSurah = await downloadRepository.getDownloadedSurah(
          reciterId,
          surahNumber,
        );
        if (downloadedSurah != null) {
          // Update the file path if needed and mark as complete
          final status = await getSurahAudioStatusUseCase(
            params: GetSurahAudioStatusParams(
              reciterId: reciterId,
              surahNumber: surahNumber,
            ),
          );

          if (status.isDownloaded && status.localPath != null) {
            await downloadRepository.markSurahAsDownloaded(
              reciterId,
              surahNumber,
              status.localPath!,
            );
          }
        }
      } catch (e) {
        print('Could not update download status in database: $e');
        // Continue even if database update fails
      }

      // Download completed, refresh status
      refreshSurahStatus(reciterId, surahNumber);
    } catch (e) {
      // Remove download record if it failed
      try {
        await downloadRepository.removeSurahDownload(reciterId, surahNumber);
      } catch (dbError) {
        print('Could not remove failed download from database: $dbError');
      }
      emit(AudioManagementError(e.toString()));
    }
  }

  /// Refresh surah audio status
  Future<void> refreshSurahStatus(String reciterId, int surahNumber) async {
    try {
      final currentState = state;

      // Get existing data from current state
      Map<String, SurahAudioStatus> currentSurahStatusMap = {};
      Map<String, List<AyahAudio>> currentAyahAudiosMap = {};

      if (currentState is AudioManagementLoaded) {
        currentSurahStatusMap = Map.from(currentState.surahStatusMap);
        currentAyahAudiosMap = Map.from(currentState.ayahAudiosMap);
      } else if (currentState is AudioDownloading) {
        currentSurahStatusMap = Map.from(currentState.previousSurahStatusMap);
        currentAyahAudiosMap = Map.from(currentState.previousAyahAudiosMap);
      }

      // Check database for download status
      bool isDownloaded = false;
      try {
        isDownloaded = await downloadRepository.isSurahDownloaded(
          reciterId,
          surahNumber,
        );
      } catch (e) {
        // If database is not available, fallback to original method
        print(
          'Database not available, falling back to original status check: $e',
        );
        isDownloaded = false;
      }

      SurahAudioStatus status;
      if (isDownloaded) {
        // Get the downloaded surah info from database
        try {
          final downloadedSurah = await downloadRepository.getDownloadedSurah(
            reciterId,
            surahNumber,
          );
          status = SurahAudioStatus(
            reciterId: reciterId,
            surahNumber: surahNumber,
            isDownloaded: true,
            localPath: downloadedSurah?.filePath ?? '',
            downloadProgress: 1.0,
          );
        } catch (e) {
          // Fallback to original method if database fails
          status = await getSurahAudioStatusUseCase(
            params: GetSurahAudioStatusParams(
              reciterId: reciterId,
              surahNumber: surahNumber,
            ),
          );
        }
      } else {
        // Get status from original source
        status = await getSurahAudioStatusUseCase(
          params: GetSurahAudioStatusParams(
            reciterId: reciterId,
            surahNumber: surahNumber,
          ),
        );
      }

      // Update the status map
      currentSurahStatusMap['${reciterId}_$surahNumber'] = status;

      // Emit the loaded state with updated data
      emit(
        AudioManagementLoaded(
          surahStatusMap: currentSurahStatusMap,
          ayahAudiosMap: currentAyahAudiosMap,
        ),
      );
    } catch (e) {
      emit(
        AudioManagementError('Failed to refresh surah status: ${e.toString()}'),
      );
    }
  }

  /// Load ayah audios for a surah
  Future<void> loadAyahAudios(String reciterId, int surahNumber) async {
    try {
      final currentState = state;
      if (currentState is AudioManagementLoaded) {
        final ayahAudios = await getAyahAudiosUseCase(
          params: GetAyahAudiosParams(
            reciterId: reciterId,
            surahNumber: surahNumber,
          ),
        );

        final updatedAyahAudiosMap = Map<String, List<AyahAudio>>.from(
          currentState.ayahAudiosMap,
        );
        updatedAyahAudiosMap['${reciterId}_$surahNumber'] = ayahAudios;

        emit(currentState.copyWith(ayahAudiosMap: updatedAyahAudiosMap));
      }
    } catch (e) {
      emit(AudioManagementError('Failed to load ayah audios: ${e.toString()}'));
    }
  }

  /// Play a specific ayah
  Future<void> playAyahAudio(AyahAudio ayahAudio, {String? surahName}) async {
    try {
      await audioPlayerService.playAyah(
        filePath: ayahAudio.localPath,
        surahNumber: ayahAudio.surahNumber,
        ayahNumber: ayahAudio.ayahNumber,
        reciterId: ayahAudio.reciterId,
        surahName: surahName,
      );
    } catch (e) {
      emit(AudioManagementError('Failed to play ayah audio: ${e.toString()}'));
    }
  }

  /// Play entire surah as playlist
  Future<void> playSurahPlaylist(
    String reciterId,
    int surahNumber, {
    String? surahName,
    int startAyahIndex = 0,
  }) async {
    try {
      final currentState = state;
      if (currentState is AudioManagementLoaded) {
        final ayahAudios = currentState.getAyahAudios(reciterId, surahNumber);

        if (ayahAudios.isEmpty) {
          emit(
            const AudioManagementError('No audio files found for this surah'),
          );
          return;
        }

        final filePaths = ayahAudios.map((audio) => audio.localPath).toList();

        await audioPlayerService.playSurahPlaylist(
          filePaths: filePaths,
          surahNumber: surahNumber,
          reciterId: reciterId,
          surahName: surahName,
          startIndex: startAyahIndex,
        );
      }
    } catch (e) {
      emit(
        AudioManagementError('Failed to play surah playlist: ${e.toString()}'),
      );
    }
  }

  /// Check if surah is downloaded
  bool isSurahDownloaded(String reciterId, int surahNumber) {
    final currentState = state;
    if (currentState is AudioManagementLoaded) {
      final status = currentState.getSurahStatus(reciterId, surahNumber);
      return status?.isDownloaded ?? false;
    }
    return false;
  }

  /// Get surah audio status
  SurahAudioStatus? getSurahStatus(String reciterId, int surahNumber) {
    final currentState = state;
    if (currentState is AudioManagementLoaded) {
      return currentState.getSurahStatus(reciterId, surahNumber);
    }
    return null;
  }

  /// Get ayah audios for a surah
  List<AyahAudio> getAyahAudios(String reciterId, int surahNumber) {
    final currentState = state;
    if (currentState is AudioManagementLoaded) {
      return currentState.getAyahAudios(reciterId, surahNumber);
    }
    return [];
  }
}
