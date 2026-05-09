import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/audio_player_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/audio_availability_cubit.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/ayah_playback_cubit.dart';
import 'audio_download_to_play_modal.dart';
import 'snackbar.dart';

/// A reusable play button widget for ayah audio playback
/// that integrates with QuranSettingsCubit for selected reciter
/// and AyahPlaybackCubit for playback control
class AyahPlayButton extends StatelessWidget {
  final int surahNumber;
  final int ayahNumber;
  final String? surahName;
  final double size;
  final Color? color;

  const AyahPlayButton({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.surahName,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedColor = color ?? colorScheme.primary;

    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      builder: (context, settingsState) {
        // Only show button if we have a selected reciter
        if (settingsState.selectedReciter == null) {
          return Icon(
            Icons.play_disabled,
            size: size,
            color: colorScheme.onSurfaceVariant,
          );
        }

        final selectedReciter = settingsState.selectedReciter!;

        return BlocConsumer<AyahPlaybackCubit, AyahPlaybackState>(
          listener: (context, playbackState) {
            // Show error messages
            if (playbackState is AyahPlaybackError &&
                playbackState.surahNumber == surahNumber &&
                playbackState.ayahNumber == ayahNumber) {
              final localizations = AppLocalizations.of(context)!;

              CustomSnackbar.showErrorSnackbar(
                context,
                localizations.audioNotAvailable,
                duration: 3,
              );
            }
          },
          builder: (context, playbackState) {
            return StreamBuilder<AudioPlayerState>(
              stream: AudioPlayerService().playerState,
              builder: (context, playerStateSnapshot) {
                return StreamBuilder<PlayingAudioInfo?>(
                  stream: AudioPlayerService().currentAudio,
                  builder: (context, currentAudioSnapshot) {
                    final playerState =
                        playerStateSnapshot.data ?? AudioPlayerState.idle;
                    final currentAudio = currentAudioSnapshot.data;

                    // Check if this specific ayah is currently playing
                    final isThisAyahPlaying =
                        currentAudio != null &&
                        currentAudio.surahNumber == surahNumber &&
                        currentAudio.ayahNumber == ayahNumber &&
                        currentAudio.reciterId == selectedReciter.id;

                    // Check if this ayah is loading
                    final isThisAyahLoading =
                        playbackState is AyahPlaybackLoading &&
                        playbackState.surahNumber == surahNumber &&
                        playbackState.ayahNumber == ayahNumber &&
                        playbackState.reciterId == selectedReciter.id;

                    // Determine the icon and state
                    IconData iconData;
                    if (isThisAyahLoading ||
                        (isThisAyahPlaying &&
                            playerState == AudioPlayerState.loading)) {
                      iconData = Icons.pause;
                    } else if (isThisAyahPlaying &&
                        playerState == AudioPlayerState.playing) {
                      iconData = Icons.pause;
                    } else {
                      iconData = Icons.play_arrow;
                    }

                    return IconButton(
                      icon: isThisAyahLoading
                          ? Icon(
                              iconData,
                              color: isThisAyahPlaying
                                  ? colorScheme.primary
                                  : resolvedColor,
                              size: size,
                            )
                          : Icon(
                              iconData,
                              color: isThisAyahPlaying
                                  ? colorScheme.primary
                                  : resolvedColor,
                              size: size,
                            ),
                      onPressed: () =>
                          _handlePlayButtonPress(context, selectedReciter.id),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handlePlayButtonPress(
    BuildContext context,
    String reciterId,
  ) async {
    final audioManagementCubit = context.read<AudioManagementCubit>();
    final localizations = AppLocalizations.of(context)!;

    final currentAudioState = audioManagementCubit.state;
    final isDownloadingSameSurah =
        currentAudioState is AudioDownloading &&
        currentAudioState.reciterId == reciterId &&
        currentAudioState.surahNumber == surahNumber;
    final isAlreadyInProgressSameSurah =
        currentAudioState is AudioDownloadAlreadyInProgress &&
        currentAudioState.reciterId == reciterId &&
        currentAudioState.surahNumber == surahNumber;

    if (currentAudioState is AudioDownloading && !isDownloadingSameSurah) {
      CustomSnackbar.showSnackbar(
        context,
        localizations.downloadInProgress,
        duration: 2,
      );
      return;
    }

    var isDownloaded = false;
    if (!isDownloadingSameSurah && !isAlreadyInProgressSameSurah) {
      await audioManagementCubit.refreshSurahStatus(reciterId, surahNumber);
      if (!context.mounted) {
        return;
      }
      isDownloaded = audioManagementCubit.isSurahDownloaded(
        reciterId,
        surahNumber,
      );
    }

    if (!isDownloaded ||
        isDownloadingSameSurah ||
        isAlreadyInProgressSameSurah) {
      final availabilityCubit = context.read<AudioAvailabilityCubit>();
      final isAvailableRemotely = availabilityCubit.state.isSurahAvailable(
        reciterId,
        surahNumber,
      );
      final modalSurahName =
          surahName ?? '${localizations.surah} $surahNumber';
      final shouldPlayAfterDownload = await showAudioDownloadToPlayModal(
        context: context,
        reciterId: reciterId,
        surahNumber: surahNumber,
        surahName: modalSurahName,
        isAvailableRemotely: isAvailableRemotely,
      );
      if (!context.mounted || !shouldPlayAfterDownload) {
        return;
      }
      context.read<AyahPlaybackCubit>().toggleAyahPlayback(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        reciterId: reciterId,
        surahName: surahName,
      );
      return;
    }

    context.read<AyahPlaybackCubit>().toggleAyahPlayback(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      reciterId: reciterId,
      surahName: surahName,
    );
  }
}
