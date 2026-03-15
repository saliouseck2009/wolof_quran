import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../domain/entities/reciter.dart';
import '../../domain/usecases/get_downloaded_surahs_usecase.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../service_locator.dart';
import '../blocs/reciter_chapters_bloc.dart';
import '../cubits/audio_availability_cubit.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/surah_mini_player_cubit.dart';
import '../utils/audio_error_formatter.dart';
import '../widgets/snackbar.dart';

class SurahAudioListPage extends StatelessWidget {
  static const String routeName = '/surah-audio-list';

  const SurahAudioListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.audioDownloads,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerLowest
            : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
        builder: (context, quranSettingsState) {
          final selectedReciter = quranSettingsState.selectedReciter;
          if (selectedReciter == null) {
            return _NoReciterSelectedState(localizations: localizations);
          }

          return KeyedSubtree(
            key: ValueKey<String>('surah-audio-list-${selectedReciter.id}'),
            child: BlocProvider(
              create: (context) => ReciterChaptersBloc(
                getDownloadedSurahsUseCase:
                    locator<GetDownloadedSurahsUseCase>(),
              )..add(LoadReciterChapters(selectedReciter)),
              child: _SurahAudioListBody(reciter: selectedReciter),
            ),
          );
        },
      ),
    );
  }
}

class _NoReciterSelectedState extends StatelessWidget {
  final AppLocalizations localizations;

  const _NoReciterSelectedState({required this.localizations});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.record_voice_over_outlined,
              size: 56,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noReciterSelected,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              localizations.selectReciter,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
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

class _SurahAudioListBody extends StatelessWidget {
  final Reciter reciter;

  const _SurahAudioListBody({required this.reciter});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final translation = context.watch<QuranSettingsCubit>().currentTranslation;

    return BlocListener<AudioManagementCubit, AudioManagementState>(
      listenWhen: (previous, current) {
        if (previous is AudioDownloading && previous.reciterId == reciter.id) {
          return current is AudioManagementLoaded ||
              current is AudioManagementError;
        }
        return false;
      },
      listener: (context, audioState) {
        if (audioState is AudioManagementLoaded) {
          context.read<ReciterChaptersBloc>().add(
            RefreshDownloadedSurahs(reciter.id),
          );
          context.read<SurahMiniPlayerCubit>().refreshQueueForReciter(
            reciter.id,
          );
        }

        if (audioState is AudioManagementError) {
          final formatted = formatAudioError(audioState.message, localizations);
          CustomSnackbar.showErrorSnackbar(context, formatted, duration: 3);
        }
      },
      child: BlocBuilder<ReciterChaptersBloc, ReciterChaptersState>(
        builder: (context, chaptersState) {
          if (chaptersState is ReciterChaptersLoading) {
            return const Center(child: CircularProgressIndicator());
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

          return BlocBuilder<AudioAvailabilityCubit, AudioAvailabilityState>(
            builder: (context, availabilityState) {
              final snapshot = availabilityState.snapshotForReciter(reciter.id);
              final remoteAvailableSet = snapshot?.availableSurahs.toSet();
              final hasAvailabilityData = snapshot != null;

              return BlocBuilder<AudioManagementCubit, AudioManagementState>(
                builder: (context, audioState) {
                  return ListView.builder(
                    key: const PageStorageKey<String>('surah-audio-list'),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    itemCount: 114,
                    itemBuilder: (context, index) {
                      final surahNumber = index + 1;
                      final isDownloaded = chaptersState.isSurahDownloaded(
                        surahNumber,
                      );
                      final isAvailableRemotely =
                          !hasAvailabilityData ||
                          (remoteAvailableSet?.contains(surahNumber) ?? false);

                      final isDownloading =
                          audioState is AudioDownloading &&
                          audioState.reciterId == reciter.id &&
                          audioState.surahNumber == surahNumber;
                      final currentDownloadProgress =
                          audioState is AudioDownloading &&
                              audioState.reciterId == reciter.id &&
                              audioState.surahNumber == surahNumber
                          ? audioState.progress
                          : 0.0;

                      final isOtherDownloading =
                          audioState is AudioDownloading &&
                          (audioState.reciterId != reciter.id ||
                              audioState.surahNumber != surahNumber);

                      final translatedName =
                          QuranSettingsCubit.getSurahNameInTranslation(
                            surahNumber,
                            translation,
                          );

                      return _SurahAudioItemCard(
                        surahNumber: surahNumber,
                        surahNameArabic: quran.getSurahNameArabic(surahNumber),
                        surahNameTranslated: translatedName,
                        versesCount: quran.getVerseCount(surahNumber),
                        isDownloaded: isDownloaded,
                        isDownloading: isDownloading,
                        downloadProgress: currentDownloadProgress,
                        isOtherDownloading: isOtherDownloading,
                        isAvailableRemotely: isAvailableRemotely,
                        reciterId: reciter.id,
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
}

class _SurahAudioItemCard extends StatelessWidget {
  final int surahNumber;
  final String surahNameArabic;
  final String surahNameTranslated;
  final int versesCount;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final bool isOtherDownloading;
  final bool isAvailableRemotely;
  final String reciterId;

  const _SurahAudioItemCard({
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameTranslated,
    required this.versesCount,
    required this.isDownloaded,
    required this.isDownloading,
    required this.downloadProgress,
    required this.isOtherDownloading,
    required this.isAvailableRemotely,
    required this.reciterId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$surahNumber',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$surahNameArabic - $surahNameTranslated',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    localizations.ayahCountLabel(versesCount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildAction(context, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isDownloading) {
      final progressPercent = (downloadProgress * 100).toInt();
      return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: downloadProgress,
              strokeWidth: 3,
              color: colorScheme.primary,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
            ),
            Text(
              '$progressPercent%',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    if (isDownloaded) {
      return IconButton(
        icon: Icon(
          Icons.play_circle_fill,
          size: 34,
          color: colorScheme.primary,
        ),
        tooltip: localizations.playSurah,
        onPressed: () async {
          final audioManagementCubit = context.read<AudioManagementCubit>();
          await audioManagementCubit.loadAyahAudios(reciterId, surahNumber);
          if (!context.mounted) {
            return;
          }

          await audioManagementCubit.playSurahPlaylist(
            reciterId,
            surahNumber,
            surahName: surahNameTranslated,
            startAyahIndex: 0,
          );

          if (!context.mounted) {
            return;
          }

          await context.read<SurahMiniPlayerCubit>().attachToCurrentPlayback(
            expanded: true,
          );
        },
      );
    }

    if (!isAvailableRemotely) {
      return Tooltip(
        message: localizations.audioNotYetAvailable,
        child: Icon(
          Icons.download_for_offline_outlined,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          size: 30,
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.download_rounded, size: 30, color: colorScheme.primary),
      tooltip: localizations.downloadLabel,
      onPressed: () {
        if (isOtherDownloading) {
          CustomSnackbar.showSnackbar(
            context,
            localizations.downloadInProgress,
            duration: 2,
          );
          return;
        }

        context.read<AudioManagementCubit>().downloadSurahAudio(
          reciterId,
          surahNumber,
        );
      },
    );
  }
}
