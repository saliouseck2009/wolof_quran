import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../domain/entities/reciter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/audio_management_cubit.dart';
import '../snackbar.dart';
import '../reciter_chapters/chapter_number_widget.dart';
import '../../utils/audio_error_formatter.dart';

class ChapterCard extends StatelessWidget {
  final Reciter reciter;
  final int surahNumber;
  final quran.Translation? translation;
  final bool isDark;
  final bool isDownloaded;
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
  final Color accentGreen;
  final AppLocalizations localizations;
  final String Function(int) getSurahDisplayName;
  final VoidCallback onDownloadComplete;

  const _DownloadActions({
    required this.reciter,
    required this.surahNumber,
    required this.isDownloaded,
    required this.accentGreen,
    required this.localizations,
    required this.getSurahDisplayName,
    required this.onDownloadComplete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocConsumer<AudioManagementCubit, AudioManagementState>(
      listenWhen: (previous, current) {
        if (previous is AudioDownloading &&
            previous.reciterId == reciter.id &&
            previous.surahNumber == surahNumber) {
          return current is AudioManagementLoaded ||
              current is AudioManagementError;
        }
        return false;
      },
      listener: (context, currentState) {
        if (currentState is AudioManagementLoaded) {
          onDownloadComplete();
          CustomSnackbar.showSnackbar(
            context,
            localizations.downloadedSuccessfully(
              getSurahDisplayName(surahNumber),
            ),
            duration: 2,
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
        final isOtherDownloading =
            currentState is AudioDownloading &&
            (currentState.reciterId != reciter.id ||
                currentState.surahNumber != surahNumber);

        if (currentState is AudioDownloading &&
            currentState.reciterId == reciter.id &&
            currentState.surahNumber == surahNumber) {
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
                      color: accentGreen,
                      backgroundColor: accentGreen.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                  Text(
                    '${(currentState.progress * 100).toInt()}%',
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
                style: textTheme.labelSmall?.copyWith(
                  color: accentGreen,
                ),
              ),
            ],
          );
        }

        if (isDownloaded) {
          return IconButton(
            onPressed: () async {
              await context
                  .read<AudioManagementCubit>()
                  .deleteSurahAudio(reciter.id, surahNumber);
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

        return IconButton(
          onPressed: () {
            if (isOtherDownloading) {
              CustomSnackbar.showSnackbar(
                context,
                localizations.downloadInProgress,
              );
              return;
            }
            context.read<AudioManagementCubit>().downloadSurahAudio(
                  reciter.id,
                  surahNumber,
                );
          },
          icon: Icon(Icons.download, color: accentGreen, size: 32),
        );
      },
    );
  }
}
