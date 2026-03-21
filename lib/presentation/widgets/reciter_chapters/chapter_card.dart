import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../domain/entities/reciter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/audio_download_queue_cubit.dart';
import '../../cubits/audio_management_cubit.dart';
import '../snackbar.dart';
import '../reciter_chapters/chapter_number_widget.dart';
import '../../../core/services/audio_download_queue_service.dart';

class ChapterCard extends StatelessWidget {
  final Reciter reciter;
  final int surahNumber;
  final quran.Translation? translation;
  final bool isDark;
  final bool isDownloaded;
  final bool isAvailableRemotely;
  final Color accentGreen;
  final Color darkSurfaceHigh;
  final String Function(int) getSurahDisplayName;
  final AppLocalizations localizations;
  final VoidCallback onDownloadComplete;

  const ChapterCard({
    super.key,
    required this.reciter,
    required this.surahNumber,
    required this.translation,
    required this.isDark,
    required this.isDownloaded,
    required this.isAvailableRemotely,
    required this.accentGreen,
    required this.darkSurfaceHigh,
    required this.getSurahDisplayName,
    required this.localizations,
    required this.onDownloadComplete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? darkSurfaceHigh
            : Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: accentGreen.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        border: isDark
            ? Border.all(
                color: accentGreen.withValues(alpha: isDark ? 0.12 : 0.15),
                width: 1,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            ChapterNumberWidget(
              color: accentGreen,
              surahNumber: surahNumber,
              textTheme: textTheme,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    getSurahDisplayName(surahNumber),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _DownloadActions(
              reciter: reciter,
              surahNumber: surahNumber,
              isDownloaded: isDownloaded,
              isAvailableRemotely: isAvailableRemotely,
              accentGreen: accentGreen,
              localizations: localizations,
              getSurahDisplayName: getSurahDisplayName,
              onDownloadComplete: onDownloadComplete,
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadActions extends StatelessWidget {
  final Reciter reciter;
  final int surahNumber;
  final bool isDownloaded;
  final bool isAvailableRemotely;
  final Color accentGreen;
  final AppLocalizations localizations;
  final String Function(int) getSurahDisplayName;
  final VoidCallback onDownloadComplete;

  const _DownloadActions({
    required this.reciter,
    required this.surahNumber,
    required this.isDownloaded,
    required this.isAvailableRemotely,
    required this.accentGreen,
    required this.localizations,
    required this.getSurahDisplayName,
    required this.onDownloadComplete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<AudioDownloadQueueCubit, AudioDownloadQueueState>(
      builder: (context, queueState) {
        final task = queueState.taskFor(reciter.id, surahNumber);

        if (task?.isDownloading == true) {
          final progress = task?.progress ?? 0.0;
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
                      value: progress,
                      strokeWidth: 3,
                      color: accentGreen,
                      backgroundColor: accentGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accentGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                localizations.downloading,
                style: textTheme.labelSmall?.copyWith(color: accentGreen),
              ),
            ],
          );
        }

        if (task?.isQueued == true) {
          final position = queueState.queuedPositionFor(
            reciter.id,
            surahNumber,
          );
          return Tooltip(
            message: localizations.queuePositionLabel(
              position > 0 ? position : 1,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.schedule_rounded, color: accentGreen, size: 30),
                    Positioned(
                      top: -2,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: accentGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${position > 0 ? position : 1}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.queued,
                  style: textTheme.labelSmall?.copyWith(color: accentGreen),
                ),
              ],
            ),
          );
        }

        if (task?.isFailed == true) {
          return IconButton(
            onPressed: () => _retryFailed(context),
            icon: Icon(Icons.refresh_rounded, color: accentGreen, size: 30),
            tooltip: localizations.retryDownload,
          );
        }

        if (isDownloaded) {
          return IconButton(
            onPressed: () async {
              await context.read<AudioManagementCubit>().deleteSurahAudio(
                reciter.id,
                surahNumber,
              );
              onDownloadComplete();
              if (context.mounted) {
                CustomSnackbar.showSnackbar(
                  context,
                  localizations.surahAudioDeleted(
                    getSurahDisplayName(surahNumber),
                  ),
                  duration: 2,
                );
              }
            },
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
              size: 28,
            ),
            tooltip: localizations.clear,
          );
        }

        if (!isAvailableRemotely) {
          return Tooltip(
            message: localizations.audioNotYetAvailable,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_for_offline_outlined,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.audioNotYetAvailableShort,
                  style: textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return IconButton(
          onPressed: () => _enqueue(context),
          icon: Icon(Icons.download, color: accentGreen, size: 32),
        );
      },
    );
  }

  Future<void> _enqueue(BuildContext context) async {
    final result = await context.read<AudioDownloadQueueCubit>().enqueue(
      reciter.id,
      surahNumber,
    );
    if (!context.mounted) {
      return;
    }
    if (result == EnqueueAudioDownloadResult.alreadyQueued) {
      CustomSnackbar.showSnackbar(context, localizations.alreadyQueued);
      return;
    }
    if (result == EnqueueAudioDownloadResult.alreadyDownloaded) {
      onDownloadComplete();
      CustomSnackbar.showSnackbar(
        context,
        localizations.downloadedSuccessfully(getSurahDisplayName(surahNumber)),
        duration: 2,
      );
    }
  }

  Future<void> _retryFailed(BuildContext context) async {
    final retried = await context.read<AudioDownloadQueueCubit>().retryFailed(
      reciter.id,
      surahNumber,
    );
    if (!retried && context.mounted) {
      await _enqueue(context);
    }
  }
}
