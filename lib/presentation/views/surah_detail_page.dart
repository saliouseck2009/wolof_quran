import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wolof_quran/domain/repositories/bookmark_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';

import '../../core/helpers/revelation_place_enum.dart';
import '../../core/services/audio_player_service.dart';
import '../../domain/entities/bookmark.dart';
import '../cubits/surah_detail_cubit.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/bookmark_cubit.dart';
import '../blocs/surah_download_status_bloc.dart';
import '../widgets/ayah_card.dart';
import '../widgets/ayah_play_button.dart';
import '../widgets/snackbar.dart';
import '../utils/audio_error_formatter.dart';
import '../../service_locator.dart';
import '../../domain/usecases/get_downloaded_surahs_usecase.dart';

class SurahDetailPage extends StatelessWidget {
  static const String routeName = "/surah-detail";
  final int surahNumber;

  const SurahDetailPage({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SurahDetailCubit()..loadSurah(surahNumber),
        ),
        BlocProvider(
          create: (context) =>
              BookmarkCubit(locator<BookmarkRepository>())..loadBookmarks(),
        ),
      ],
      child: SurahDetailView(surahNumber: surahNumber),
    );
  }
}

class SurahDetailView extends StatelessWidget {
  final int surahNumber;

  const SurahDetailView({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SurahDetailCubit, SurahDetailState>(
        builder: (context, state) {
          if (state is SurahDetailLoading) {
            return const SurahDetailLoadingWidget();
          }

          if (state is SurahDetailError) {
            return SurahDetailErrorWidget(
              message: state.message,
              onRetry: () =>
                  context.read<SurahDetailCubit>().loadSurah(surahNumber),
            );
          }

          if (state is! SurahDetailLoaded) {
            return const SizedBox.shrink();
          }

          return SurahDetailContent(state: state, surahNumber: surahNumber);
        },
      ),
    );
  }
}

class SurahDetailLoadingWidget extends StatelessWidget {
  const SurahDetailLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class SurahDetailErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SurahDetailErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(localizations.tryAgain),
          ),
        ],
      ),
    );
  }
}

class SurahDetailContent extends StatelessWidget {
  final SurahDetailLoaded state;
  final int surahNumber;

  const SurahDetailContent({
    super.key,
    required this.state,
    required this.surahNumber,
  });

  void _initializeAudioManagement(BuildContext context) {
    // Initialize the AudioManagementCubit if not already initialized
    final audioManagementCubit = context.read<AudioManagementCubit>();
    final currentState = audioManagementCubit.state;

    if (currentState is! AudioManagementLoaded) {
      audioManagementCubit.initialize();
    }

    // Load ayah audios for this surah with the selected reciter
    final quranSettingsCubit = context.read<QuranSettingsCubit>();
    final quranSettingsState = quranSettingsCubit.state;

    if (quranSettingsState.selectedReciter != null) {
      audioManagementCubit.loadAyahAudios(
        quranSettingsState.selectedReciter!.id,
        surahNumber,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize audio management when widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAudioManagement(context);
    });

    return CustomScrollView(
      slivers: [
        // Modern App Bar with Surah Info
        SurahDetailAppBar(state: state),

        // Basmala (except for Surah At-Tawbah) - only show if Arabic is visible
        if (surahNumber != 9 &&
            (state.displayMode == AyahDisplayMode.both ||
                state.displayMode == AyahDisplayMode.arabicOnly))
          const SurahBasmalaWidget(),

        // List of Ayahs
        SurahAyahsList(
          surahNumber: surahNumber,
          ayahs: state.ayahs,
          translationSource: state.translationSource,
          displayMode: state.displayMode,
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 64)),
      ],
    );
  }
}

class SurahDetailAppBar extends StatelessWidget {
  final SurahDetailLoaded state;

  const SurahDetailAppBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final revelationType = quran.getPlaceOfRevelation(state.surahNumber);

    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 2,
      backgroundColor: colorScheme.primary,
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      title: Text(
        state.surahNameTranslated,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
          fontSize: 18,
        ),
      ),
      actions: [
        // Display Mode Toggle Button
        PopupMenuButton<AyahDisplayMode>(
          icon: Icon(
            _getDisplayModeIcon(state.displayMode),
            color: colorScheme.onPrimary,
          ),
          color: colorScheme.surface,
          onSelected: (mode) {
            context.read<SurahDetailCubit>().changeDisplayMode(mode);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: AyahDisplayMode.both,
              child: Row(
                children: [
                  Icon(
                    Icons.view_headline,
                    color: state.displayMode == AyahDisplayMode.both
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.arabicAndTranslation,
                    style: TextStyle(
                      color: state.displayMode == AyahDisplayMode.both
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: state.displayMode == AyahDisplayMode.both
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: AyahDisplayMode.arabicOnly,
              child: Row(
                children: [
                  Icon(
                    Icons.format_textdirection_r_to_l,
                    color: state.displayMode == AyahDisplayMode.arabicOnly
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.arabicOnly,
                    style: TextStyle(
                      color: state.displayMode == AyahDisplayMode.arabicOnly
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight:
                          state.displayMode == AyahDisplayMode.arabicOnly
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: AyahDisplayMode.translationOnly,
              child: Row(
                children: [
                  Icon(
                    Icons.translate,
                    color: state.displayMode == AyahDisplayMode.translationOnly
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.translationOnly,
                    style: TextStyle(
                      color:
                          state.displayMode == AyahDisplayMode.translationOnly
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight:
                          state.displayMode == AyahDisplayMode.translationOnly
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.settings, color: colorScheme.onPrimary),
          onPressed: () async {
            final result = await Navigator.pushNamed(
              context,
              '/quran-settings',
            );
            // Reload the Surah if user changed translation
            if (result == true && context.mounted) {
              context.read<SurahDetailCubit>().loadSurah(state.surahNumber);
            }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Container(
          decoration: BoxDecoration(color: colorScheme.primary),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SurahHeaderContent(
                state: state,
                localizations: localizations,
                revelationType: revelationType,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDisplayModeIcon(AyahDisplayMode mode) {
    switch (mode) {
      case AyahDisplayMode.both:
        return Icons.view_headline;
      case AyahDisplayMode.arabicOnly:
        return Icons.format_textdirection_r_to_l;
      case AyahDisplayMode.translationOnly:
        return Icons.translate;
    }
  }
}

class SurahHeaderContent extends StatelessWidget {
  final SurahDetailLoaded state;
  final AppLocalizations localizations;
  final dynamic revelationType;

  const SurahHeaderContent({
    super.key,
    required this.state,
    required this.localizations,
    required this.revelationType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Arabic name
        Text(
          state.surahNameArabic,
          style: TextStyle(
            fontFamily: 'Hafs',
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),

        const SizedBox(height: 16),

        // Play Surah Button
        BlocProvider(
          create: (context) => SurahDownloadStatusBloc(
            getDownloadedSurahsUseCase: locator<GetDownloadedSurahsUseCase>(),
          ),
          child: SurahPlayButton(
            surahNumber: state.surahNumber,
            surahName: state.surahNameTranslated,
          ),
        ),

        // Info chips
        SurahInfoChips(
          versesCount: state.versesCount,
          localizations: localizations,
          revelationType: revelationType,
        ),
      ],
    );
  }
}

class SurahInfoChips extends StatelessWidget {
  final int versesCount;
  final AppLocalizations localizations;
  final dynamic revelationType;

  const SurahInfoChips({
    super.key,
    required this.versesCount,
    required this.localizations,
    required this.revelationType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SurahInfoChip(
          label: '$versesCount ${localizations.verses}',
          icon: Icons.format_list_numbered,
        ),
        const SizedBox(width: 12),
        SurahInfoChip(
          label: revelationType == RevelationPlaceEnum.meccan
              ? localizations.meccan
              : localizations.medinan,
          icon: revelationType == RevelationPlaceEnum.meccan
              ? Icons.location_on
              : Icons.location_city,
        ),
      ],
    );
  }
}

class SurahInfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const SurahInfoChip({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SurahBasmalaWidget extends StatelessWidget {
  const SurahBasmalaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          quran.basmala,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Hafs',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}

class SurahAyahsList extends StatelessWidget {
  final int surahNumber;
  final List<AyahData> ayahs;
  final String translationSource;
  final AyahDisplayMode displayMode;

  const SurahAyahsList({
    super.key,
    required this.surahNumber,
    required this.ayahs,
    required this.translationSource,
    required this.displayMode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final ayah = ayahs[index];
        return AyahCard(
          verseNumber: ayah.verseNumber,
          arabicText: ayah.arabicText,
          translationSource: translationSource,
          translation: ayah.translation,
          displayMode: displayMode,
          surahNumber: surahNumber,
          surahName: quran.getSurahName(surahNumber),
          actions: [
            AyahPlayButton(
              surahNumber: surahNumber,
              ayahNumber: ayah.verseNumber,
              surahName: quran.getSurahName(surahNumber),
            ),
            IconButton(
              icon: BlocBuilder<BookmarkCubit, BookmarkState>(
                builder: (context, bookmarkState) {
                  final isBookmarked = context
                      .read<BookmarkCubit>()
                      .isBookmarked(surahNumber, ayah.verseNumber);

                  return Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked
                        ? colorScheme.primary
                        : colorScheme.outline,
                  );
                },
              ),
              onPressed: () {
                final bookmarkCubit = context.read<BookmarkCubit>();
                final bookmark = BookmarkedAyah(
                  surahNumber: surahNumber,
                  verseNumber: ayah.verseNumber,
                  surahName: quran.getSurahName(surahNumber),
                  arabicText: ayah.arabicText,
                  translation: ayah.translation,
                  translationSource: translationSource,
                  createdAt: DateTime.now(),
                );

                bookmarkCubit.toggleBookmark(bookmark);
              },
            ),
          ],
        );
      }, childCount: ayahs.length),
    );
  }
}

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

        // Trigger check for download status when reciter is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentState = context.read<SurahDownloadStatusBloc>().state;

          // Only trigger if not already loaded for this specific reciter/surah
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
            // Handle errors
            if (downloadStatusState is SurahDownloadStatusError) {
              final formattedError = formatAudioError(
                downloadStatusState.message,
                localizations,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizations.errorCheckingDownloadStatus(formattedError),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          builder: (context, downloadStatusState) {
            // Loading state
            if (downloadStatusState is SurahDownloadStatusLoading) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 140,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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

            // Error state or initial state - show disabled button
            if (downloadStatusState is! SurahDownloadStatusLoaded) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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

            // Not downloaded - show download button
            if (!isDownloaded) {
              return BlocConsumer<AudioManagementCubit, AudioManagementState>(
                listenWhen: (previous, current) {
                  // Listen when download completes or fails for this specific surah
                  if (previous is AudioDownloading &&
                      previous.reciterId == selectedReciter.id &&
                      previous.surahNumber == surahNumber) {
                    return current is AudioManagementLoaded ||
                        current is AudioManagementError;
                  }
                  return false;
                },
                listener: (context, currentState) {
                  if (currentState is AudioManagementLoaded) {
                    // Refresh download status when download completes
                    context.read<SurahDownloadStatusBloc>().add(
                      RefreshSurahDownloadStatus(
                        reciterId: selectedReciter.id,
                        surahNumber: surahNumber,
                      ),
                    );

                    // Show success message
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
                  // Check if currently downloading this specific surah
                  final isDownloading =
                      currentState is AudioDownloading &&
                      currentState.reciterId == selectedReciter.id &&
                      currentState.surahNumber == surahNumber;

                  if (isDownloading) {
                    final downloadingState =
                        currentState as AudioDownloading;
                    final progressPercent =
                        (downloadingState.progress * 100).toInt();
                    // Show download progress
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
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
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${localizations.downloading} $progressPercent%',
                              style: TextStyle(
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

                  // Show download button
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final audioState = context
                            .read<AudioManagementCubit>()
                            .state;
                        if (audioState is AudioDownloading &&
                            (audioState.reciterId != selectedReciter.id ||
                                audioState.surahNumber != surahNumber)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.downloadInProgress,
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        // Trigger download
                        context.read<AudioManagementCubit>().downloadSurahAudio(
                          selectedReciter.id,
                          surahNumber,
                        );
                      },
                      icon: Icon(Icons.download_outlined, size: 20),
                      label: Text(
                        localizations.downloadToPlay,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
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

            // Downloaded - show play button with audio management
            return BlocListener<AudioManagementCubit, AudioManagementState>(
              listenWhen: (previous, current) {
                // Listen for download completion for this specific surah
                if (previous is AudioDownloading &&
                    current is AudioManagementLoaded) {
                  if (previous.reciterId == selectedReciter.id &&
                      previous.surahNumber == surahNumber) {
                    return true;
                  }
                }
                return false;
              },
              listener: (context, state) {
                // Refresh download status when a download completes for this surah
                context.read<SurahDownloadStatusBloc>().add(
                  RefreshSurahDownloadStatus(
                    reciterId: selectedReciter.id,
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
                              playerStateSnapshot.data ??
                              AudioPlayerState.stopped;
                          final currentAudio = currentAudioSnapshot.data;
                          final audioPlayerService = context
                              .read<AudioManagementCubit>()
                              .audioPlayerService;

                          // Check if this surah is currently playing in playlist mode
                          final isThisSurahPlaying =
                              currentAudio != null &&
                              currentAudio.surahNumber == surahNumber &&
                              currentAudio.reciterId == selectedReciter.id &&
                              audioPlayerService.isPlayingPlaylist;

                          final isPlaying =
                              isThisSurahPlaying &&
                              playerState == AudioPlayerState.playing;
                          final isPaused =
                              isThisSurahPlaying &&
                              playerState == AudioPlayerState.paused;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final audioManagementCubit = context
                                    .read<AudioManagementCubit>();

                                if (isThisSurahPlaying) {
                                  // If this surah is playing, toggle play/pause
                                  if (isPlaying) {
                                    await audioPlayerService.pause();
                                  } else if (isPaused) {
                                    await audioPlayerService.resume();
                                  }
                                } else {
                                  // Load ayah audios for this surah first
                                  await audioManagementCubit.loadAyahAudios(
                                    selectedReciter.id,
                                    surahNumber,
                                  );

                                  // Play the entire surah as playlist
                                  audioManagementCubit.playSurahPlaylist(
                                    selectedReciter.id,
                                    surahNumber,
                                    surahName: surahName,
                                    startAyahIndex: 0,
                                  );
                                }
                              },
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: isThisSurahPlaying
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              label: Text(
                                isPlaying
                                    ? localizations.pauseSurah
                                    : isPaused
                                    ? localizations.resumeSurah
                                    : localizations.playSurah,
                                style: TextStyle(
                                  fontFamily: 'Hafs',
                                  fontWeight: FontWeight.w600,
                                  color: isThisSurahPlaying
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.pureWhite,
                                foregroundColor: isThisSurahPlaying
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.primary,
                                elevation: isThisSurahPlaying ? 4 : 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  side: isThisSurahPlaying
                                      ? BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
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
          },
        );
      },
    );
  }
}
