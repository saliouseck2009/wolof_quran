import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/config/theme/app_color.dart';
import '../../../core/services/audio_download_queue_service.dart';
import '../../../domain/entities/reciter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/audio_download_queue_cubit.dart';
import '../../cubits/audio_management_cubit.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../../utils/download_network_guard.dart';
import '../snackbar.dart';

class ChapterCard extends StatelessWidget {
  final Reciter reciter;
  final int surahNumber;
  final quran.Translation? translation;
  final bool isDownloaded;
  final bool isAvailableRemotely;
  final String Function(int) getSurahDisplayName;
  final AppLocalizations localizations;
  final VoidCallback onDownloadComplete;

  const ChapterCard({
    super.key,
    required this.reciter,
    required this.surahNumber,
    required this.translation,
    required this.isDownloaded,
    required this.isAvailableRemotely,
    required this.getSurahDisplayName,
    required this.localizations,
    required this.onDownloadComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final accentColor = isDark ? AppColor.tertiary : colorScheme.primary;
    final bgColor = isDark
        ? colorScheme.surfaceContainerLow
        : colorScheme.onPrimary;

    final surahNameArabic = quran.getSurahNameArabic(surahNumber);
    final surahNameTranslated = translation != null
        ? QuranSettingsCubit.getSurahNameInTranslation(
            surahNumber,
            translation!,
          )
        : quran.getSurahNameEnglish(surahNumber);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: _ChapterNumberBadge(
                  number: surahNumber,
                  isDownloaded: isDownloaded,
                  accentColor: accentColor,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
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
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          surahNameArabic,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
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
                          localizations.ayahCountLabel(
                            quran.getVerseCount(surahNumber),
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _DownloadActions(
                reciter: reciter,
                surahNumber: surahNumber,
                isDownloaded: isDownloaded,
                isAvailableRemotely: isAvailableRemotely,
                localizations: localizations,
                getSurahDisplayName: getSurahDisplayName,
                onDownloadComplete: onDownloadComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterNumberBadge extends StatelessWidget {
  final int number;
  final bool isDownloaded;
  final Color accentColor;
  final ColorScheme colorScheme;

  const _ChapterNumberBadge({
    required this.number,
    required this.isDownloaded,
    required this.accentColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final bgColor = isDownloaded
        ? (isDark ? accentColor.withValues(alpha: 0.25) : colorScheme.primary)
        : colorScheme.onSurface.withValues(alpha: 0.07);
    final textColor = isDownloaded
        ? (isDark ? accentColor : colorScheme.onPrimary)
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

class _DownloadActions extends StatelessWidget {
  final Reciter reciter;
  final int surahNumber;
  final bool isDownloaded;
  final bool isAvailableRemotely;
  final AppLocalizations localizations;
  final String Function(int) getSurahDisplayName;
  final VoidCallback onDownloadComplete;

  const _DownloadActions({
    required this.reciter,
    required this.surahNumber,
    required this.isDownloaded,
    required this.isAvailableRemotely,
    required this.localizations,
    required this.getSurahDisplayName,
    required this.onDownloadComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final accentColor = isDark ? AppColor.tertiary : colorScheme.primary;

    return BlocBuilder<AudioDownloadQueueCubit, AudioDownloadQueueState>(
      builder: (context, queueState) {
        final task = queueState.taskFor(reciter.id, surahNumber);
        final isDownloading = task?.isDownloading == true;
        final isQueued = task?.isQueued == true;
        final isFailed = task?.isFailed == true;
        final downloadProgress = task?.progress ?? 0.0;
        final queuePosition = queueState.queuedPositionFor(
          reciter.id,
          surahNumber,
        );

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
          return IconButton(
            onPressed: () => _retryFailed(context),
            tooltip: localizations.retryDownload,
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: colorScheme.error,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.errorContainer.withValues(
                alpha: 0.45,
              ),
              minimumSize: const Size(40, 40),
              maximumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
          );
        }

        if (isDownloaded) {
          final btnBg = isDark
              ? colorScheme.error.withValues(alpha: 0.18)
              : colorScheme.errorContainer;
          final iconColor = isDark
              ? colorScheme.error
              : colorScheme.onErrorContainer;
          return IconButton(
            onPressed: () => _confirmDelete(context),
            tooltip: localizations.deleteAudioLabel,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: iconColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: btnBg,
              minimumSize: const Size(40, 40),
              maximumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
          );
        }

        if (!isAvailableRemotely) {
          return Tooltip(
            message: localizations.audioNotYetAvailable,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 20,
                color: colorScheme.onPrimary.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        return IconButton(
          onPressed: () => _enqueue(context),
          tooltip: localizations.downloadLabel,
          icon: Icon(
            Icons.download_rounded,
            size: 20,
            color: isDark ? accentColor : colorScheme.onPrimary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? accentColor.withValues(alpha: 0.15)
                : colorScheme.primary,
            minimumSize: const Size(40, 40),
            maximumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
            // shape: CircleBorder(
            //   side: BorderSide(
            //     color: accentColor.withValues(alpha: isDark ? 0.4 : 0.5),
            //     width: 1,
            //   ),
            // ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            localizations.confirmDeleteSurahAudioTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Text(
            localizations.confirmDeleteSurahAudioMessage(
              getSurahDisplayName(surahNumber),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                localizations.cancel,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                localizations.delete,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AudioManagementCubit>().deleteSurahAudio(
      reciter.id,
      surahNumber,
    );
    onDownloadComplete();
    if (context.mounted) {
      CustomSnackbar.showSnackbar(
        context,
        localizations.surahAudioDeleted(getSurahDisplayName(surahNumber)),
        duration: 2,
      );
    }
  }

  Future<void> _enqueue(BuildContext context) async {
    final canProceed = await DownloadNetworkGuard.confirmManualDownload(
      context,
    );
    if (!canProceed || !context.mounted) {
      return;
    }

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
