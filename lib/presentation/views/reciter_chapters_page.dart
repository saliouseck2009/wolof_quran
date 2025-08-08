import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:quran/quran.dart' as quran;

import '../../core/config/theme/app_color.dart';
import '../../core/services/audio_player_service.dart';
import '../../domain/entities/reciter.dart';
import '../blocs/reciter_chapters_bloc.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../../service_locator.dart';
import '../../domain/usecases/get_downloaded_surahs_usecase.dart';

class ReciterChaptersPage extends StatelessWidget {
  final Reciter reciter;

  const ReciterChaptersPage({super.key, required this.reciter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (context) => ReciterChaptersBloc(
        getDownloadedSurahsUseCase: locator<GetDownloadedSurahsUseCase>(),
      )..add(LoadReciterChapters(reciter)),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: isDark
                  ? AppColor.charcoal
                  : AppColor.primaryGreen,
              foregroundColor: AppColor.pureWhite,
              surfaceTintColor: Colors.transparent,
              shadowColor: isDark
                  ? AppColor.charcoal.withValues(alpha: 0.3)
                  : AppColor.primaryGreen.withValues(alpha: 0.3),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColor.primaryGreen.withValues(alpha: 0.8),
                        AppColor.primaryGreen,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColor.pureWhite.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: AppColor.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          reciter.name,
                          style: TextStyle(
                            fontFamily: 'Hafs',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColor.pureWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ReciterChaptersContent(reciter: reciter),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReciterChaptersContent extends StatelessWidget {
  final Reciter reciter;

  const _ReciterChaptersContent({required this.reciter});

  String _getSurahDisplayName(int surahNumber, quran.Translation? translation) {
    final arabicName = quran.getSurahNameArabic(surahNumber);
    if (translation != null) {
      final translatedName = QuranSettingsCubit.getSurahNameInTranslation(
        surahNumber,
        translation,
      );
      return '$arabicName - $translatedName';
    }
    return '$arabicName - ${quran.getSurahNameEnglish(surahNumber)}';
  }

  String _getFormattedErrorMessage(
    String error,
    AppLocalizations localizations,
  ) {
    if (error.contains('SocketException') || error.contains('connection')) {
      return localizations.checkInternetConnection;
    }
    if (error.contains('timeout') || error.contains('Timeout')) {
      return localizations.connectionTimeout;
    }
    if (error.contains('404') || error.contains('not found')) {
      return localizations.audioFileNotFound;
    }
    if (error.contains('403') || error.contains('forbidden')) {
      return localizations.accessDeniedToAudio;
    }
    if (error.contains('storage') || error.contains('space')) {
      return localizations.notEnoughStorage;
    }
    return localizations.downloadFailed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ReciterChaptersBloc, ReciterChaptersState>(
      builder: (context, state) {
        if (state is ReciterChaptersLoading) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: CircularProgressIndicator(color: AppColor.primaryGreen),
            ),
          );
        }

        if (state is ReciterChaptersError) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColor.error),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _getFormattedErrorMessage(state.message, localizations),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Hafs',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is ReciterChaptersLoaded) {
          final translation = context
              .read<QuranSettingsCubit>()
              .currentTranslation;

          return _buildChaptersList(
            context,
            isDark,
            state,
            translation,
            localizations,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildChaptersList(
    BuildContext context,
    bool isDark,
    ReciterChaptersLoaded state,
    quran.Translation? translation,
    AppLocalizations localizations,
  ) {
    return Column(
      children: [
        // Download status summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.download_done, color: AppColor.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.surahsDownloaded(
                  state.downloadedSurahNumbers.length,
                ),
                style: TextStyle(
                  fontFamily: 'Hafs',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColor.primaryGreen,
                ),
              ),
            ],
          ),
        ),

        // Chapters list
        ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 48),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 114,
          itemBuilder: (context, index) {
            final surahNumber = index + 1;
            final isDownloaded = state.isSurahDownloaded(surahNumber);

            return _ChapterCard(
              reciter: reciter,
              surahNumber: surahNumber,
              translation: translation,
              isDark: isDark,
              isDownloaded: isDownloaded,
              getSurahDisplayName: (number) =>
                  _getSurahDisplayName(number, translation),
              localizations: localizations,
              onDownloadComplete: () {
                // Refresh the downloaded surahs when download completes
                context.read<ReciterChaptersBloc>().add(
                  RefreshDownloadedSurahs(reciter.id),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final Reciter reciter;
  final int surahNumber;
  final quran.Translation? translation;
  final bool isDark;
  final bool isDownloaded;
  final String Function(int) getSurahDisplayName;
  final AppLocalizations localizations;
  final VoidCallback onDownloadComplete;

  const _ChapterCard({
    required this.reciter,
    required this.surahNumber,
    required this.translation,
    required this.isDark,
    required this.isDownloaded,
    required this.getSurahDisplayName,
    required this.localizations,
    required this.onDownloadComplete,
  });

  String _getFormattedErrorMessage(String error) {
    if (error.contains('SocketException') || error.contains('connection')) {
      return localizations.checkInternetConnection;
    }
    if (error.contains('timeout') || error.contains('Timeout')) {
      return localizations.connectionTimeout;
    }
    if (error.contains('404') || error.contains('not found')) {
      return localizations.audioFileNotFound;
    }
    if (error.contains('403') || error.contains('forbidden')) {
      return localizations.accessDeniedToAudio;
    }
    if (error.contains('storage') || error.contains('space')) {
      return localizations.notEnoughStorage;
    }
    return localizations.downloadFailed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColor.charcoal : AppColor.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Chapter number
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColor.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$surahNumber',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primaryGreen,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Chapter info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getSurahDisplayName(surahNumber),
                    style: TextStyle(
                      fontFamily: 'Hafs',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColor.pureWhite : AppColor.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  BlocBuilder<AudioManagementCubit, AudioManagementState>(
                    builder: (context, currentState) {
                      String statusText = isDownloaded
                          ? localizations.downloaded
                          : localizations.notDownloaded;

                      if (currentState is AudioDownloading &&
                          currentState.reciterId == reciter.id &&
                          currentState.surahNumber == surahNumber) {
                        statusText =
                            '${localizations.downloading.replaceAll('...', '')} ${(currentState.progress * 100).toInt()}%';
                      }

                      return Text(
                        statusText,
                        style: TextStyle(
                          fontFamily: 'Hafs',
                          fontSize: 14,
                          color: isDownloaded
                              ? AppColor.success
                              : AppColor.mediumGray,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Action button and listener
            BlocConsumer<AudioManagementCubit, AudioManagementState>(
              listenWhen: (previous, current) {
                // Listen when download completes or fails for this specific surah
                if (previous is AudioDownloading &&
                    previous.reciterId == reciter.id &&
                    previous.surahNumber == surahNumber) {
                  return current is AudioManagementLoaded ||
                      current is AudioManagementError;
                }
                return false;
              },
              listener: (context, currentState) {
                // Notify parent when download completes
                if (currentState is AudioManagementLoaded) {
                  onDownloadComplete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        localizations.downloadedSuccessfully(
                          getSurahDisplayName(surahNumber),
                        ),
                      ),
                      backgroundColor: AppColor.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else if (currentState is AudioManagementError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        localizations.downloadFailedWithError(
                          _getFormattedErrorMessage(currentState.message),
                        ),
                      ),
                      backgroundColor: AppColor.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              builder: (context, currentState) {
                // Check if currently downloading this specific surah
                if (currentState is AudioDownloading &&
                    currentState.reciterId == reciter.id &&
                    currentState.surahNumber == surahNumber) {
                  // Show progress indicator with percentage
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              value: currentState.progress,
                              strokeWidth: 3,
                              color: AppColor.primaryGreen,
                              backgroundColor: AppColor.primaryGreen.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          Text(
                            '${(currentState.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontFamily: 'Hafs',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColor.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Downloading...',
                        style: TextStyle(
                          fontFamily: 'Hafs',
                          fontSize: 10,
                          color: AppColor.primaryGreen,
                        ),
                      ),
                    ],
                  );
                }

                if (isDownloaded) {
                  // Play/Stop button with stream builder to monitor player state
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
                              playerStateSnapshot.data ??
                              AudioPlayerState.stopped;
                          final currentAudio = currentAudioSnapshot.data;
                          final audioPlayerService = context
                              .read<AudioManagementCubit>()
                              .audioPlayerService;

                          // Check if this specific surah is currently playing
                          final isThisSurahPlaying =
                              currentAudio != null &&
                              currentAudio.surahNumber == surahNumber &&
                              currentAudio.reciterId == reciter.id &&
                              audioPlayerService.isPlayingPlaylist;

                          final isPlaying =
                              isThisSurahPlaying &&
                              (playerState == AudioPlayerState.playing ||
                                  playerState == AudioPlayerState.loading);

                          return IconButton(
                            onPressed: () async {
                              if (isThisSurahPlaying &&
                                  playerState == AudioPlayerState.playing) {
                                // Stop the current playback
                                await audioPlayerService.stop();
                              } else {
                                // Load ayah audios and play surah playlist
                                context
                                    .read<AudioManagementCubit>()
                                    .loadAyahAudios(reciter.id, surahNumber);
                                context
                                    .read<AudioManagementCubit>()
                                    .playSurahPlaylist(
                                      reciter.id,
                                      surahNumber,
                                      surahName: getSurahDisplayName(
                                        surahNumber,
                                      ),
                                      startAyahIndex: 0,
                                    );
                              }
                            },
                            icon: Icon(
                              isPlaying
                                  ? Icons.stop_circle
                                  : Icons.play_circle_filled,
                              color: AppColor.primaryGreen,
                              size: 32,
                            ),
                          );
                        },
                      );
                    },
                  );
                }

                // Download button
                return IconButton(
                  onPressed: () {
                    context.read<AudioManagementCubit>().downloadSurahAudio(
                      reciter.id,
                      surahNumber,
                    );
                  },
                  icon: Icon(
                    Icons.download,
                    color: AppColor.primaryGreen,
                    size: 32,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
