import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../core/config/theme/app_color.dart';
import '../../core/services/audio_download_queue_service.dart';
import '../../core/services/audio_player_service.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/entities/queued_audio_download_task.dart';
import '../../domain/usecases/get_downloaded_surahs_usecase.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../service_locator.dart';
import '../blocs/reciter_chapters_bloc.dart';
import '../cubits/audio_availability_cubit.dart';
import '../cubits/audio_download_queue_cubit.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/surah_mini_player_cubit.dart';
import '../utils/audio_error_formatter.dart';
import '../utils/download_network_guard.dart';
import '../widgets/snackbar.dart';

class SurahAudioListPage extends StatelessWidget {
  static const String routeName = '/surah-audio-list';

  const SurahAudioListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      builder: (context, quranSettingsState) {
        final selectedReciter = quranSettingsState.selectedReciter;

        if (selectedReciter == null) {
          return Scaffold(
            appBar: AppBar(title: Text(localizations.recitation)),
            body: _NoReciterSelectedState(localizations: localizations),
          );
        }

        return KeyedSubtree(
          key: ValueKey<String>('surah-audio-list-${selectedReciter.id}'),
          child: BlocProvider(
            create: (context) => ReciterChaptersBloc(
              getDownloadedSurahsUseCase: locator<GetDownloadedSurahsUseCase>(),
            )..add(LoadReciterChapters(selectedReciter)),
            child: _SurahAudioListBody(reciter: selectedReciter),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ════════════════════════════════════════════════════════════════════════════

class _NoReciterSelectedState extends StatelessWidget {
  final AppLocalizations localizations;

  const _NoReciterSelectedState({required this.localizations});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.record_voice_over_outlined,
                size: 42,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.noReciterSelected,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              localizations.selectReciter,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/reciter-list'),
              icon: const Icon(Icons.manage_accounts_outlined),
              label: Text(localizations.selectReciter),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BODY
// ════════════════════════════════════════════════════════════════════════════

class _SurahAudioListBody extends StatelessWidget {
  final Reciter reciter;

  const _SurahAudioListBody({required this.reciter});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final translation = context.watch<QuranSettingsCubit>().currentTranslation;

    return MultiBlocListener(
      listeners: [
        BlocListener<ReciterChaptersBloc, ReciterChaptersState>(
          listenWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType ||
              (previous is ReciterChaptersLoaded &&
                  current is ReciterChaptersLoaded &&
                  previous.downloadedSurahNumbers !=
                      current.downloadedSurahNumbers),
          listener: (context, state) {
            if (state is! ReciterChaptersLoaded) {
              return;
            }
            unawaited(_maybeAutoEnqueueFirstSurah(context, state));
          },
        ),
        BlocListener<AudioDownloadQueueCubit, AudioDownloadQueueState>(
          listenWhen: (previous, current) =>
              previous.taskCountForReciter(reciter.id) !=
              current.taskCountForReciter(reciter.id),
          listener: (context, _) {
            context.read<ReciterChaptersBloc>().add(
              RefreshDownloadedSurahs(reciter.id),
            );
            context.read<SurahMiniPlayerCubit>().refreshQueueForReciter(
              reciter.id,
            );
          },
        ),
        BlocListener<AudioDownloadQueueCubit, AudioDownloadQueueState>(
          listenWhen: (previous, current) =>
              previous.completionVersion != current.completionVersion,
          listener: (context, queueState) {
            final task = queueState.lastCompletedTask;
            if (task == null || task.reciterId != reciter.id) {
              return;
            }
            final translatedName = QuranSettingsCubit.getSurahNameInTranslation(
              task.surahNumber,
              translation,
            );
            CustomSnackbar.showSnackbar(
              context,
              localizations.downloadedSuccessfully(translatedName),
              duration: 2,
            );
          },
        ),
        BlocListener<AudioDownloadQueueCubit, AudioDownloadQueueState>(
          listenWhen: (previous, current) =>
              previous.failureVersion != current.failureVersion,
          listener: (context, queueState) {
            final task = queueState.lastFailedTask;
            if (task == null || task.reciterId != reciter.id) {
              return;
            }
            CustomSnackbar.showErrorSnackbar(
              context,
              localizations.downloadFailedShort,
              duration: 3,
            );
          },
        ),
        BlocListener<AudioManagementCubit, AudioManagementState>(
          listenWhen: (previous, current) => current is AudioManagementError,
          listener: (context, audioState) {
            if (audioState is AudioManagementError) {
              final formatted = formatAudioError(
                audioState.message,
                localizations,
              );
              CustomSnackbar.showErrorSnackbar(context, formatted, duration: 3);
            }
          },
        ),
        BlocListener<AudioManagementCubit, AudioManagementState>(
          listenWhen: (_, current) =>
              current is AudioDownloadAlreadyInProgress &&
              current.reciterId == reciter.id,
          listener: (context, _) {
            CustomSnackbar.showSnackbar(
              context,
              localizations.surahDownloadAlreadyInProgress,
              duration: 2,
            );
          },
        ),
      ],
      child: BlocBuilder<ReciterChaptersBloc, ReciterChaptersState>(
        builder: (context, chaptersState) {
          if (chaptersState is ReciterChaptersLoading) {
            return const _LoadingPlaceholder();
          }

          if (chaptersState is ReciterChaptersError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  formatAudioError(chaptersState.message, localizations),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (chaptersState is! ReciterChaptersLoaded) {
            return const SizedBox.shrink();
          }

          final downloadedCount = List.generate(
            114,
            (i) => chaptersState.isSurahDownloaded(i + 1),
          ).where((v) => v).length;

          return BlocBuilder<AudioAvailabilityCubit, AudioAvailabilityState>(
            builder: (context, availabilityState) {
              final snapshot = availabilityState.snapshotForReciter(reciter.id);
              final remoteAvailableSet = snapshot?.availableSurahs.toSet();
              final hasAvailabilityData = snapshot != null;

              return BlocBuilder<
                AudioDownloadQueueCubit,
                AudioDownloadQueueState
              >(
                builder: (context, queueState) {
                  return BlocBuilder<
                    SurahMiniPlayerCubit,
                    SurahMiniPlayerState
                  >(
                    builder: (context, playerState) {
                      final colorScheme = Theme.of(context).colorScheme;

                      return ColoredBox(
                        color: colorScheme.surface,
                        child: CustomScrollView(
                          key: const PageStorageKey<String>('surah-audio-list'),
                          slivers: [
                            _ReciterSliverHeader(
                              reciter: reciter,
                              downloadedCount: downloadedCount,
                              localizations: localizations,
                              playerState: playerState,
                              translation: translation,
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                120,
                              ),
                              sliver: SliverList.builder(
                                itemCount: 114,
                                itemBuilder: (context, index) {
                                  final surahNumber = index + 1;
                                  final isDownloaded = chaptersState
                                      .isSurahDownloaded(surahNumber);
                                  final isAvailableRemotely =
                                      !hasAvailabilityData ||
                                      (remoteAvailableSet?.contains(
                                            surahNumber,
                                          ) ??
                                          false);
                                  final queueTask = queueState.taskFor(
                                    reciter.id,
                                    surahNumber,
                                  );
                                  final isDownloading =
                                      queueTask?.status ==
                                      QueuedAudioDownloadStatus.downloading;
                                  final isQueued =
                                      queueTask?.status ==
                                      QueuedAudioDownloadStatus.queued;
                                  final isFailed =
                                      queueTask?.status ==
                                      QueuedAudioDownloadStatus.failed;
                                  final downloadProgress =
                                      queueTask?.progress ?? 0.0;
                                  final queuePosition = queueState
                                      .queuedPositionFor(
                                        reciter.id,
                                        surahNumber,
                                      );
                                  final isNowPlaying =
                                      playerState.hasActiveSurah &&
                                      playerState.surahNumber == surahNumber &&
                                      playerState.reciterId == reciter.id;

                                  final translatedName =
                                      QuranSettingsCubit.getSurahNameInTranslation(
                                        surahNumber,
                                        translation,
                                      );

                                  return _SurahTrackTile(
                                    surahNumber: surahNumber,
                                    surahNameArabic: quran.getSurahNameArabic(
                                      surahNumber,
                                    ),
                                    surahNameTranslated: translatedName,
                                    versesCount: quran.getVerseCount(
                                      surahNumber,
                                    ),
                                    isDownloaded: isDownloaded,
                                    isDownloading: isDownloading,
                                    isQueued: isQueued,
                                    isFailed: isFailed,
                                    queuePosition: queuePosition,
                                    downloadProgress: downloadProgress,
                                    isAvailableRemotely: isAvailableRemotely,
                                    isNowPlaying: isNowPlaying,
                                    playerState: playerState,
                                    reciterId: reciter.id,
                                    localizations: localizations,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _maybeAutoEnqueueFirstSurah(
    BuildContext context,
    ReciterChaptersLoaded chaptersState,
  ) async {
    if (chaptersState.downloadedSurahNumbers.isNotEmpty) {
      return;
    }

    final queueState = context.read<AudioDownloadQueueCubit>().state;
    if (queueState.hasActiveOrQueuedForReciter(reciter.id)) {
      return;
    }
    final existingTaskForFirst = queueState.taskFor(reciter.id, 1);
    if (existingTaskForFirst?.isFailed == true) {
      return;
    }

    final audioState = context.read<AudioManagementCubit>().state;
    if (audioState is AudioDownloading) {
      return;
    }

    final availabilitySnapshot = context
        .read<AudioAvailabilityCubit>()
        .state
        .snapshotForReciter(reciter.id);
    if (availabilitySnapshot != null &&
        !availabilitySnapshot.availableSurahs.contains(1)) {
      return;
    }

    final canAutoDownload = await DownloadNetworkGuard.canAutoDownload();
    if (!canAutoDownload || !context.mounted) {
      return;
    }

    await context.read<AudioDownloadQueueCubit>().enqueue(reciter.id, 1);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SLIVER HEADER (reciter banner)
// ════════════════════════════════════════════════════════════════════════════

class _ReciterSliverHeader extends StatelessWidget {
  final Reciter reciter;
  final int downloadedCount;
  final AppLocalizations localizations;
  final SurahMiniPlayerState playerState;
  final quran.Translation translation;

  const _ReciterSliverHeader({
    required this.reciter,
    required this.downloadedCount,
    required this.localizations,
    required this.playerState,
    required this.translation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasNowPlaying = playerState.hasActiveSurah;
    final currentSurahNumber = playerState.surahNumber;
    final currentSurahName = currentSurahNumber == null
        ? null
        : QuranSettingsCubit.getSurahNameInTranslation(
            currentSurahNumber,
            translation,
          );

    return SliverAppBar(
      expandedHeight: hasNowPlaying ? 216 : 150,
      pinned: true,
      centerTitle: false,
      title: Text(
        localizations.recitation,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: isDark
          ? colorScheme.surfaceContainerLowest
          : colorScheme.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      bottom: hasNowPlaying && currentSurahName != null
          ? _HeaderNowPlayingBar(
              playerState: playerState,
              surahName: currentSurahName,
              localizations: localizations,
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColor.primary,
                AppColor.primary.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Reciter avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reciter.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _Chip(
                                  label:
                                      '$downloadedCount / 114 ${localizations.downloaded}',
                                  icon: Icons.download_done_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderNowPlayingBar extends StatelessWidget
    implements PreferredSizeWidget {
  final SurahMiniPlayerState playerState;
  final String surahName;
  final AppLocalizations localizations;

  const _HeaderNowPlayingBar({
    required this.playerState,
    required this.surahName,
    required this.localizations,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPlaying =
        playerState.playerState == AudioPlayerState.playing ||
        playerState.playerState == AudioPlayerState.loading;
    final cubit = context.read<SurahMiniPlayerCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        height: preferredSize.height - 10,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${playerState.surahNumber ?? ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.nowPlaying,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    surahName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: playerState.canGoPrevious
                  ? cubit.playPreviousSurah
                  : null,
              tooltip: localizations.previousSurah,
              icon: const Icon(Icons.skip_previous_rounded, size: 22),
              color: Colors.white,
              disabledColor: Colors.white.withValues(alpha: 0.45),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: cubit.togglePlayPause,
              tooltip: isPlaying
                  ? localizations.pauseSurah
                  : localizations.playSurah,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 22,
              ),
              color: Colors.white,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            IconButton(
              onPressed: playerState.canGoNext ? cubit.playNextSurah : null,
              tooltip: localizations.nextSurah,
              icon: const Icon(Icons.skip_next_rounded, size: 22),
              color: Colors.white,
              disabledColor: Colors.white.withValues(alpha: 0.45),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TRACK TILE
// ════════════════════════════════════════════════════════════════════════════

class _SurahTrackTile extends StatelessWidget {
  final int surahNumber;
  final String surahNameArabic;
  final String surahNameTranslated;
  final int versesCount;
  final bool isDownloaded;
  final bool isDownloading;
  final bool isQueued;
  final bool isFailed;
  final int queuePosition;
  final double downloadProgress;
  final bool isAvailableRemotely;
  final bool isNowPlaying;
  final SurahMiniPlayerState playerState;
  final String reciterId;
  final AppLocalizations localizations;

  const _SurahTrackTile({
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameTranslated,
    required this.versesCount,
    required this.isDownloaded,
    required this.isDownloading,
    required this.isQueued,
    required this.isFailed,
    required this.queuePosition,
    required this.downloadProgress,
    required this.isAvailableRemotely,
    required this.isNowPlaying,
    required this.playerState,
    required this.reciterId,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final isPlaying =
        isNowPlaying &&
        (playerState.playerState == AudioPlayerState.playing ||
            playerState.playerState == AudioPlayerState.loading);

    // In dark mode, primary (#006E62) is too dark on dark surfaces.
    // Use tertiary (#4DB6AC) as a lighter, readable teal accent instead.
    final accentColor = isDark ? colorScheme.primary : colorScheme.primary;

    // Now-playing background:
    //  • dark  → elevated surface (surfaceContainerHigh)
    //  • light → soft primaryContainer wash (much more visible than 7% primary)
    final bgColor = isNowPlaying
        ? (isDark
              ? colorScheme.surfaceContainerHigh
              : colorScheme.primary.withValues(alpha: 0.15))
        : (isDark ? colorScheme.surfaceContainerLow : colorScheme.onPrimary);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      // Material(transparent) gives InkWell a surface to paint its ripple on,
      // while AnimatedContainer keeps ownership of the background color.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isDownloaded ? () => _play(context) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // ── Left: number / equalizer ───────────────────────────────
                SizedBox(
                  width: 42,
                  height: 42,
                  child: isPlaying
                      ? _EqualizerBadge(color: accentColor)
                      : _NumberBadge(
                          number: surahNumber,
                          isDownloaded: isDownloaded,
                          isNowPlaying: isNowPlaying,
                          accentColor: accentColor,
                          colorScheme: colorScheme,
                        ),
                ),

                const SizedBox(width: 12),

                // ── Center: names + meta ───────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              surahNameTranslated,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isNowPlaying ? accentColor : null,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            surahNameArabic,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isNowPlaying
                                  ? accentColor
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            localizations.ayahCountLabel(versesCount),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Right: action ──────────────────────────────────────────
                _TrackAction(
                  isDownloaded: isDownloaded,
                  isDownloading: isDownloading,
                  isQueued: isQueued,
                  isFailed: isFailed,
                  queuePosition: queuePosition,
                  downloadProgress: downloadProgress,
                  isAvailableRemotely: isAvailableRemotely,
                  isNowPlaying: isNowPlaying,
                  isPlaying: isPlaying,
                  accentColor: accentColor,
                  colorScheme: colorScheme,
                  localizations: localizations,
                  onPlay: () => _play(context),
                  onDownload: () => _download(context),
                  onRetry: () => _retry(context),
                ),
              ],
            ),
          ),
        ), // InkWell
      ), // Material
    );
  }

  Future<void> _play(BuildContext context) async {
    final audioMgmt = context.read<AudioManagementCubit>();
    await audioMgmt.loadAyahAudios(reciterId, surahNumber);
    if (!context.mounted) return;

    await audioMgmt.playSurahPlaylist(
      reciterId,
      surahNumber,
      surahName: surahNameTranslated,
      startAyahIndex: 0,
    );
    if (!context.mounted) return;

    await context.read<SurahMiniPlayerCubit>().attachToCurrentPlayback(
      expanded: true,
      resetShuffleHistory: true,
    );
  }

  Future<void> _download(BuildContext context) async {
    final audioState = context.read<AudioManagementCubit>().state;
    if (audioState is AudioDownloading) {
      final isSameSurah =
          audioState.reciterId == reciterId &&
          audioState.surahNumber == surahNumber;
      CustomSnackbar.showSnackbar(
        context,
        isSameSurah
            ? localizations.surahDownloadAlreadyInProgress
            : localizations.downloadInProgress,
        duration: 2,
      );
      return;
    }

    final canProceed = await DownloadNetworkGuard.confirmManualDownload(
      context,
    );
    if (!canProceed || !context.mounted) {
      return;
    }

    final result = await context.read<AudioDownloadQueueCubit>().enqueue(
      reciterId,
      surahNumber,
    );
    if (!context.mounted) {
      return;
    }
    if (result == EnqueueAudioDownloadResult.alreadyQueued) {
      CustomSnackbar.showSnackbar(context, localizations.alreadyQueued);
    } else if (result == EnqueueAudioDownloadResult.alreadyInProgress) {
      CustomSnackbar.showSnackbar(
        context,
        localizations.surahDownloadAlreadyInProgress,
        duration: 2,
      );
    } else if (result == EnqueueAudioDownloadResult.alreadyDownloaded) {
      CustomSnackbar.showSnackbar(
        context,
        localizations.downloadedSuccessfully(surahNameTranslated),
        duration: 2,
      );
      context.read<ReciterChaptersBloc>().add(
        RefreshDownloadedSurahs(reciterId),
      );
    }
  }

  Future<void> _retry(BuildContext context) async {
    final retried = await context.read<AudioDownloadQueueCubit>().retryFailed(
      reciterId,
      surahNumber,
    );
    if (!retried && context.mounted) {
      await _download(context);
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _NumberBadge extends StatelessWidget {
  final int number;
  final bool isDownloaded;
  final bool isNowPlaying;
  final Color accentColor;
  final ColorScheme colorScheme;

  const _NumberBadge({
    required this.number,
    required this.isDownloaded,
    required this.isNowPlaying,
    required this.accentColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = colorScheme.brightness == Brightness.dark;

    // Now playing: solid accent fill
    // Downloaded (light): use primaryContainer for a clear but soft teal chip
    // Downloaded (dark): semi-transparent accent
    // Default: neutral grey tint
    final bgColor = isNowPlaying
        ? accentColor
        : isDownloaded
        ? (isDark ? accentColor.withValues(alpha: 0.25) : colorScheme.primary)
        : colorScheme.onSurface.withValues(alpha: 0.07);

    final textColor = isNowPlaying
        ? colorScheme.onPrimary
        : isDownloaded
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Animated equalizer bars — shown when the surah is currently playing.
class _EqualizerBadge extends StatefulWidget {
  final Color color;

  const _EqualizerBadge({required this.color});

  @override
  State<_EqualizerBadge> createState() => _EqualizerBadgeState();
}

class _EqualizerBadgeState extends State<_EqualizerBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _EqBar(height: 8 + _ctrl.value * 14),
              _EqBar(height: 14 + (1 - _ctrl.value) * 8),
              _EqBar(height: 6 + _ctrl.value * 16),
              _EqBar(height: 12 + (1 - _ctrl.value) * 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _EqBar extends StatelessWidget {
  final double height;

  const _EqBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height.clamp(4.0, 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _TrackAction extends StatelessWidget {
  final bool isDownloaded;
  final bool isDownloading;
  final bool isQueued;
  final bool isFailed;
  final int queuePosition;
  final double downloadProgress;
  final bool isAvailableRemotely;
  final bool isNowPlaying;
  final bool isPlaying;
  final Color accentColor;
  final ColorScheme colorScheme;
  final AppLocalizations localizations;
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  final VoidCallback onRetry;

  const _TrackAction({
    required this.isDownloaded,
    required this.isDownloading,
    required this.isQueued,
    required this.isFailed,
    required this.queuePosition,
    required this.downloadProgress,
    required this.isAvailableRemotely,
    required this.isNowPlaying,
    required this.isPlaying,
    required this.accentColor,
    required this.colorScheme,
    required this.localizations,
    required this.onPlay,
    required this.onDownload,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = colorScheme.brightness == Brightness.dark;

    // Downloading: circular progress
    if (isDownloading) {
      final pct = (downloadProgress * 100).toInt();
      return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: downloadProgress,
              strokeWidth: 3,
              color: accentColor,
              backgroundColor: accentColor.withValues(alpha: 0.15),
            ),
            Text(
              '$pct%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    if (isQueued) {
      final position = queuePosition > 0 ? queuePosition : 1;
      return Tooltip(
        message: localizations.queuePositionLabel(position),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? accentColor.withValues(alpha: 0.15)
                : colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 20,
                color: isDark ? accentColor : colorScheme.onPrimary,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$position',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isFailed) {
      return Tooltip(
        message: localizations.retryDownload,
        child: GestureDetector(
          onTap: onRetry,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: colorScheme.error,
            ),
          ),
        ),
      );
    }

    // Downloaded: play/pause button
    if (isDownloaded) {
      // Now playing  → solid accent fill, white icon
      // Idle (light)  → primary teal fill, white icon
      // Idle (dark)   → primaryContainer tint, primary-colored icon (more visible than 20% alpha)
      final btnBg = isDark ? colorScheme.primary : colorScheme.primary;
      final iconColor = isDark ? colorScheme.onPrimary : colorScheme.onPrimary;

      return GestureDetector(
        onTap: onPlay,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: btnBg, shape: BoxShape.circle),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 22,
            color: iconColor,
          ),
        ),
      );
    }

    // Not available remotely → disabled appearance (Material spec: 8–12% onSurface bg, 35% icon)
    if (!isAvailableRemotely) {
      return Tooltip(
        message: localizations.audioNotYetAvailable,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(
              alpha: isDark ? 0.10 : 0.08,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_off_outlined,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      );
    }

    // Available for download → soft primary tint = harmonieux avec le thème teal
    // Light: primary @ 13% bg + icône primary (teal léger, suggère l'action à venir)
    // Dark:  primary @ 18% bg + icône primary (plus visible sur fond sombre)
    return GestureDetector(
      onTap: onDownload,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.13),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.download_rounded,
          size: 20,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LOADING PLACEHOLDER
// ════════════════════════════════════════════════════════════════════════════

class _LoadingPlaceholder extends StatefulWidget {
  const _LoadingPlaceholder();

  @override
  State<_LoadingPlaceholder> createState() => _LoadingPlaceholderState();
}

class _LoadingPlaceholderState extends State<_LoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: 12,
          itemBuilder: (_, i) => Container(
            height: 62,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: _anim.value * 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }
}
