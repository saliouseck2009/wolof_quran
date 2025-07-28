import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/services/audio_player_service.dart';
import 'audio_management_cubit.dart';

// States
abstract class AyahPlaybackState extends Equatable {
  const AyahPlaybackState();

  @override
  List<Object?> get props => [];
}

class AyahPlaybackInitial extends AyahPlaybackState {}

class AyahPlaybackLoading extends AyahPlaybackState {
  final int surahNumber;
  final int ayahNumber;
  final String reciterId;

  const AyahPlaybackLoading({
    required this.surahNumber,
    required this.ayahNumber,
    required this.reciterId,
  });

  @override
  List<Object?> get props => [surahNumber, ayahNumber, reciterId];
}

class AyahPlaybackError extends AyahPlaybackState {
  final String message;
  final int surahNumber;
  final int ayahNumber;

  const AyahPlaybackError({
    required this.message,
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  List<Object?> get props => [message, surahNumber, ayahNumber];
}

// Cubit
class AyahPlaybackCubit extends Cubit<AyahPlaybackState> {
  final AudioPlayerService _audioPlayerService;
  final AudioManagementCubit _audioManagementCubit;

  AyahPlaybackCubit({
    required AudioPlayerService audioPlayerService,
    required AudioManagementCubit audioManagementCubit,
  }) : _audioPlayerService = audioPlayerService,
       _audioManagementCubit = audioManagementCubit,
       super(AyahPlaybackInitial());

  /// Play or pause a specific ayah
  Future<void> toggleAyahPlayback({
    required int surahNumber,
    required int ayahNumber,
    required String reciterId,
    String? surahName,
  }) async {
    try {
      // Check if this ayah is currently playing
      final currentAudio = _audioPlayerService.currentPlayingAudio;
      final playerState = _audioPlayerService.currentPlayerState;

      final isThisAyahPlaying =
          currentAudio != null &&
          currentAudio.surahNumber == surahNumber &&
          currentAudio.ayahNumber == ayahNumber &&
          currentAudio.reciterId == reciterId;

      if (isThisAyahPlaying) {
        // If this ayah is currently playing, pause/resume
        if (playerState == AudioPlayerState.playing) {
          await _audioPlayerService.pause();
        } else if (playerState == AudioPlayerState.paused) {
          await _audioPlayerService.resume();
        }
      } else {
        // Need to play this ayah
        await _playAyah(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          reciterId: reciterId,
          surahName: surahName,
        );
      }
    } catch (e) {
      emit(
        AyahPlaybackError(
          message: e.toString(),
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
        ),
      );
    }
  }

  Future<void> _playAyah({
    required int surahNumber,
    required int ayahNumber,
    required String reciterId,
    String? surahName,
  }) async {
    emit(
      AyahPlaybackLoading(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        reciterId: reciterId,
      ),
    );

    try {
      // Ensure AudioManagementCubit is in loaded state first
      final currentState = _audioManagementCubit.state;
      if (currentState is! AudioManagementLoaded) {
        // Initialize the AudioManagementCubit properly
        _audioManagementCubit.initialize();

        // Wait a bit for the initialization to complete
        await Future.delayed(const Duration(milliseconds: 200));

        // Check if initialization was successful
        final newState = _audioManagementCubit.state;
        if (newState is! AudioManagementLoaded) {
          throw Exception('Failed to initialize audio management');
        }
      }

      // Load ayah audios for this surah if not already loaded
      await _audioManagementCubit.loadAyahAudios(reciterId, surahNumber);

      // Wait a bit for the loading to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Get the current state to find the audio file path
      final updatedState = _audioManagementCubit.state;
      if (updatedState is AudioManagementLoaded) {
        final ayahAudios = updatedState.getAyahAudios(reciterId, surahNumber);

        if (ayahAudios.isNotEmpty) {
          // Find the specific ayah audio
          final ayahAudio = ayahAudios.firstWhere(
            (audio) => audio.ayahNumber == ayahNumber,
            orElse: () =>
                throw Exception('Ayah audio not found for ayah $ayahNumber'),
          );

          // Play the ayah using AudioPlayerService
          await _audioPlayerService.playAyah(
            filePath: ayahAudio.localPath,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            reciterId: reciterId,
            surahName: surahName,
          );

          // Return to initial state after successful playback start
          emit(AyahPlaybackInitial());
        } else {
          throw Exception(
            'No audio files available for surah $surahNumber. Make sure you have downloaded the audio for this reciter.',
          );
        }
      } else {
        throw Exception('Failed to initialize audio management state');
      }
    } catch (e) {
      emit(
        AyahPlaybackError(
          message: e.toString(),
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
        ),
      );
    }
  }

  /// Check if a specific ayah is currently playing
  bool isAyahPlaying({
    required int surahNumber,
    required int ayahNumber,
    required String reciterId,
  }) {
    final currentAudio = _audioPlayerService.currentPlayingAudio;
    final playerState = _audioPlayerService.currentPlayerState;

    return currentAudio != null &&
        currentAudio.surahNumber == surahNumber &&
        currentAudio.ayahNumber == ayahNumber &&
        currentAudio.reciterId == reciterId &&
        playerState == AudioPlayerState.playing;
  }

  /// Check if a specific ayah is currently paused
  bool isAyahPaused({
    required int surahNumber,
    required int ayahNumber,
    required String reciterId,
  }) {
    final currentAudio = _audioPlayerService.currentPlayingAudio;
    final playerState = _audioPlayerService.currentPlayerState;

    return currentAudio != null &&
        currentAudio.surahNumber == surahNumber &&
        currentAudio.ayahNumber == ayahNumber &&
        currentAudio.reciterId == reciterId &&
        playerState == AudioPlayerState.paused;
  }

  /// Check if a specific ayah is currently loading
  bool isAyahLoading({
    required int surahNumber,
    required int ayahNumber,
    required String reciterId,
  }) {
    final currentState = state;
    return currentState is AyahPlaybackLoading &&
        currentState.surahNumber == surahNumber &&
        currentState.ayahNumber == ayahNumber &&
        currentState.reciterId == reciterId;
  }
}
