import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/audio_player_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/audio_availability_cubit.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/ayah_playback_cubit.dart';
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

    await audioManagementCubit.refreshSurahStatus(reciterId, surahNumber);
    if (!context.mounted) {
      return;
    }

    final isDownloaded = audioManagementCubit.isSurahDownloaded(
      reciterId,
      surahNumber,
    );

    if (!isDownloaded) {
      final availabilityCubit = context.read<AudioAvailabilityCubit>();
      final isAvailableRemotely = availabilityCubit.state.isSurahAvailable(
        reciterId,
        surahNumber,
      );
      await _showDownloadPromptModal(
        context,
        reciterId: reciterId,
        isAvailableRemotely: isAvailableRemotely,
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

  Future<void> _showDownloadPromptModal(
    BuildContext context, {
    required String reciterId,
    required bool isAvailableRemotely,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final commonButtonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final commonButtonTextStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final secondaryButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: commonButtonShape,
      textStyle: commonButtonTextStyle,
      backgroundColor: colorScheme.surfaceContainerHighest,
      foregroundColor: colorScheme.error,
    );
    final primaryButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: commonButtonShape,
      textStyle: commonButtonTextStyle,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.download_for_offline_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          surahName ?? 'Surah $surahNumber',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAvailableRemotely
                        ? localizations.audioNotAvailable
                        : localizations.audioNotYetAvailable,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: FilledButton(
                          style: secondaryButtonStyle,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          //icon: const Icon(Icons.close_rounded, size: 18),
                          child: Text(localizations.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: FilledButton(
                          style: primaryButtonStyle,
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            if (!isAvailableRemotely) {
                              return;
                            }

                            final audioState = context
                                .read<AudioManagementCubit>()
                                .state;
                            if (audioState is AudioDownloading &&
                                (audioState.reciterId != reciterId ||
                                    audioState.surahNumber != surahNumber)) {
                              CustomSnackbar.showSnackbar(
                                context,
                                localizations.downloadInProgress,
                                duration: 2,
                              );
                              return;
                            }

                            context
                                .read<AudioManagementCubit>()
                                .downloadSurahAudio(reciterId, surahNumber);
                          },
                          // icon: Icon(
                          //   isAvailableRemotely
                          //       ? Icons.download_outlined
                          //       : Icons.check_circle_outline,
                          //   size: 18,
                          // ),
                          child: Text(
                            isAvailableRemotely
                                ? localizations.downloadLabel
                                : localizations.close,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
