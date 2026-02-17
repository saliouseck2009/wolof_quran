import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/theme/app_color.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../blocs/surah_download_status_bloc.dart';
import '../../cubits/audio_management_cubit.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../../utils/audio_error_formatter.dart';
import '../snackbar.dart';

class SurahPlayButton extends StatelessWidget {
  final int surahNumber;
  final String surahName;

  const SurahPlayButton({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      builder: (context, quranSettingsState) {
        if (quranSettingsState.selectedReciter == null) {
          return const SizedBox.shrink();
        }

        final selectedReciter = quranSettingsState.selectedReciter!;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentState = context.read<SurahDownloadStatusBloc>().state;
          if (currentState is! SurahDownloadStatusLoaded ||
              currentState.reciterId != selectedReciter.id ||
              currentState.surahNumber != surahNumber) {
            context.read<SurahDownloadStatusBloc>().add(
                  CheckSurahDownloadStatus(
                    reciterId: selectedReciter.id,
                    surahNumber: surahNumber,
                  ),
                );
          }
        });

        return BlocConsumer<SurahDownloadStatusBloc, SurahDownloadStatusState>(
          listener: (context, downloadStatusState) {
            if (downloadStatusState is SurahDownloadStatusError) {
              final formattedError = formatAudioError(
                downloadStatusState.message,
                localizations,
              );
              CustomSnackbar.showErrorSnackbar(
                context,
                localizations.errorCheckingDownloadStatus(formattedError),
                duration: 3,
              );
            }
          },
          builder: (context, downloadStatusState) {
            if (downloadStatusState is SurahDownloadStatusLoading) {
              final colorScheme = Theme.of(context).colorScheme;
              final isDark = colorScheme.brightness == Brightness.dark;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 140,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHigh
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            if (downloadStatusState is! SurahDownloadStatusLoaded) {
              final colorScheme = Theme.of(context).colorScheme;
              final isDark = colorScheme.brightness == Brightness.dark;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHigh
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        localizations.checkFailed,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isDownloaded = downloadStatusState.isDownloaded;

            if (!isDownloaded) {
              return _DownloadSurahButton(
                reciterId: selectedReciter.id,
                surahNumber: surahNumber,
                surahName: surahName,
              );
            }

            return _PlaySurahButton(
              selectedReciter: selectedReciter.id,
              surahNumber: surahNumber,
              surahName: surahName,
            );
          },
        );
      },
    );
  }
}

class _DownloadSurahButton extends StatelessWidget {
  final String reciterId;
  final int surahNumber;
  final String surahName;

  const _DownloadSurahButton({
    required this.reciterId,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return BlocConsumer<AudioManagementCubit, AudioManagementState>(
      listenWhen: (previous, current) {
        if (previous is AudioDownloading &&
            previous.reciterId == reciterId &&
            previous.surahNumber == surahNumber) {
          return current is AudioManagementLoaded ||
              current is AudioManagementError;
        }
        return false;
      },
      listener: (context, currentState) {
        if (currentState is AudioManagementLoaded) {
          context.read<SurahDownloadStatusBloc>().add(
                RefreshSurahDownloadStatus(
                  reciterId: reciterId,
                  surahNumber: surahNumber,
                ),
              );
          CustomSnackbar.showSnackbar(
            context,
            localizations.downloadedSuccessfully(surahName),
          );
        } else if (currentState is AudioManagementError) {
          final formattedError = formatAudioError(
            currentState.message,
            localizations,
          );
          CustomSnackbar.showSnackbar(
            context,
            localizations.downloadFailedWithError(formattedError),
            duration: 5,
          );
        }
      },
      builder: (context, currentState) {
        final isDownloading =
            currentState is AudioDownloading &&
                currentState.reciterId == reciterId &&
                currentState.surahNumber == surahNumber;

        if (isDownloading) {
          final progressPercent = (currentState.progress * 100).toInt();
          final bgColor = isDark
              ? colorScheme.surfaceContainerHigh
              : Colors.white.withValues(alpha: 0.2);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      value: currentState.progress,
                      strokeWidth: 2,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${localizations.downloading} $progressPercent%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final bgColor =
            isDark ? colorScheme.surfaceContainer : Colors.white.withValues(
              alpha: 0.2,
            );
        final fgColor = isDark ? colorScheme.onSurface : Colors.white;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              final audioState = context.read<AudioManagementCubit>().state;
              if (audioState is AudioDownloading &&
                  (audioState.reciterId != reciterId ||
                      audioState.surahNumber != surahNumber)) {
                CustomSnackbar.showSnackbar(
                  context,
                  AppLocalizations.of(context)!.downloadInProgress,
                  duration: 2,
                );
                return;
              }

              context.read<AudioManagementCubit>().downloadSurahAudio(
                    reciterId,
                    surahNumber,
                  );
            },
            icon: const Icon(Icons.download_outlined, size: 20),
            label: Text(
              localizations.downloadToPlay,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlaySurahButton extends StatelessWidget {
  final String selectedReciter;
  final int surahNumber;
  final String surahName;

  const _PlaySurahButton({
    required this.selectedReciter,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    return BlocListener<AudioManagementCubit, AudioManagementState>(
      listenWhen: (previous, current) {
        if (previous is AudioDownloading && current is AudioManagementLoaded) {
          if (previous.reciterId == selectedReciter &&
              previous.surahNumber == surahNumber) {
            return true;
          }
        }
        return false;
      },
      listener: (context, state) {
        context.read<SurahDownloadStatusBloc>().add(
              RefreshSurahDownloadStatus(
                reciterId: selectedReciter,
                surahNumber: surahNumber,
              ),
            );
      },
      child: BlocBuilder<AudioManagementCubit, AudioManagementState>(
        builder: (context, audioState) {
          return StreamBuilder<AudioPlayerState>(
            stream: context
                .read<AudioManagementCubit>()
                .audioPlayerService
                .playerState,
            builder: (context, playerStateSnapshot) {
              return StreamBuilder<PlayingAudioInfo?>(
                stream: context
                    .read<AudioManagementCubit>()
                    .audioPlayerService
                    .currentAudio,
                builder: (context, currentAudioSnapshot) {
                  final playerState =
                      playerStateSnapshot.data ?? AudioPlayerState.stopped;
                  final currentAudio = currentAudioSnapshot.data;
                  final audioPlayerService =
                      context.read<AudioManagementCubit>().audioPlayerService;

                  final isThisSurahPlaying =
                      currentAudio != null &&
                          currentAudio.surahNumber == surahNumber &&
                          currentAudio.reciterId == selectedReciter &&
                          audioPlayerService.isPlayingPlaylist;

                  final isPlaying = isThisSurahPlaying &&
                      (playerState == AudioPlayerState.playing ||
                          playerState == AudioPlayerState.loading);
                  final isPaused =
                      isThisSurahPlaying &&
                          playerState == AudioPlayerState.paused;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final audioManagementCubit =
                            context.read<AudioManagementCubit>();

                        if (isThisSurahPlaying) {
                          if (isPlaying) {
                            await audioPlayerService.pause();
                          } else if (isPaused) {
                            await audioPlayerService.resume();
                          }
                          return;
                        }

                        await audioManagementCubit.loadAyahAudios(
                          selectedReciter,
                          surahNumber,
                        );

                        audioManagementCubit.playSurahPlaylist(
                          selectedReciter,
                          surahNumber,
                          surahName: surahName,
                          startAyahIndex: 0,
                        );
                      },
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: isThisSurahPlaying
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                        size: 20,
                      ),
                      label: Text(
                        isPlaying
                            ? localizations.pauseSurah
                            : isPaused
                                ? localizations.resumeSurah
                                : localizations.playSurah,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isThisSurahPlaying
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.brightness == Brightness.dark
                                ? theme.colorScheme.surfaceContainer
                                : AppColor.pureWhite,
                        foregroundColor: isThisSurahPlaying
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                        elevation: isThisSurahPlaying ? 4 : 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: isThisSurahPlaying
                              ? BorderSide(
                                  color: theme.colorScheme.secondary,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
