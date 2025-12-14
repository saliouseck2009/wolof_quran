import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolof_quran/presentation/widgets/snackbar.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:quran/quran.dart' as quran;

import '../../domain/entities/reciter.dart';
import '../blocs/reciter_chapters_bloc.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../../service_locator.dart';
import '../../domain/usecases/get_downloaded_surahs_usecase.dart';
import '../utils/audio_error_formatter.dart';

class ReciterChaptersDownloadPage extends StatelessWidget {
  final Reciter reciter;

  const ReciterChaptersDownloadPage({super.key, required this.reciter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentGreen = isDark
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    return BlocProvider(
      create: (context) => ReciterChaptersBloc(
        getDownloadedSurahsUseCase: locator<GetDownloadedSurahsUseCase>(),
      )..add(LoadReciterChapters(reciter)),
      child: Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 150,
              floating: false,
              pinned: true,
              backgroundColor: isDark
                  ? Theme.of(context).colorScheme.surfaceContainer
                  : accentGreen,
              iconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              surfaceTintColor: Colors.transparent,
              shadowColor: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : accentGreen.withValues(alpha: 0.3),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  reciter.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 16,
                  bottom: 12,
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Theme.of(context).colorScheme.surfaceContainer,
                              Theme.of(context).colorScheme.surface,
                            ]
                          : [accentGreen.withValues(alpha: 0.85), accentGreen],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ReciterChaptersContent(
                reciter: reciter,
                accentGreen: accentGreen,
                darkSurfaceHigh: Theme.of(context).colorScheme.surfaceContainer,
                darkSurface: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReciterChaptersContent extends StatelessWidget {
  final Reciter reciter;
  final Color accentGreen;
  final Color darkSurfaceHigh;
  final Color darkSurface;

  const _ReciterChaptersContent({
    required this.reciter,
    required this.accentGreen,
    required this.darkSurfaceHigh,
    required this.darkSurface,
  });

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ReciterChaptersBloc, ReciterChaptersState>(
      builder: (context, state) {
        final textTheme = Theme.of(context).textTheme;
        if (state is ReciterChaptersLoading) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(child: CircularProgressIndicator(color: accentGreen)),
          );
        }

        if (state is ReciterChaptersError) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    formatAudioError(state.message, localizations),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
            color: accentGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentGreen.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.download_done, color: accentGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.surahsDownloaded(
                  state.downloadedSurahNumbers.length,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: accentGreen,
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
              accentGreen: accentGreen,
              darkSurfaceHigh: darkSurfaceHigh,
              getSurahDisplayName: (number) =>
                  _getSurahDisplayName(number, translation),
              localizations: localizations,
              onDownloadComplete: () {
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
  final Color accentGreen;
  final Color darkSurfaceHigh;
  final String Function(int) getSurahDisplayName;
  final AppLocalizations localizations;
  final VoidCallback onDownloadComplete;

  const _ChapterCard({
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
        color: isDark ? darkSurfaceHigh : Theme.of(context).colorScheme.surface,
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
        border: Border.all(
          color: accentGreen.withValues(alpha: isDark ? 0.12 : 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Chapter number
            ChapterNumberWidget(
              accentGreen: accentGreen,
              surahNumber: surahNumber,
              textTheme: textTheme,
            ),

            const SizedBox(width: 16),

            // Chapter info
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

            // Action button and listener
            BlocConsumer<AudioManagementCubit, AudioManagementState>(
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localizations.surahAudioDeleted(
                                getSurahDisplayName(surahNumber),
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
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

                // if (isOtherDownloading) {
                //   return IconButton(
                //     onPressed: () {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(
                //           content: Text(localizations.downloadInProgress),
                //           duration: const Duration(seconds: 2),
                //         ),
                //       );
                //     },
                //     icon: Icon(
                //       Icons.downloading,
                //       color: Theme.of(context).colorScheme.onSurfaceVariant,
                //       size: 28,
                //     ),
                //     tooltip: localizations.downloadInProgress,
                //   );
                // }

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
            ),
          ],
        ),
      ),
    );
  }
}

class ChapterNumberWidget extends StatelessWidget {
  const ChapterNumberWidget({
    super.key,
    required this.accentGreen,
    required this.surahNumber,
    required this.textTheme,
  });

  final Color accentGreen;
  final int surahNumber;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accentGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$surahNumber',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: accentGreen,
          ),
        ),
      ),
    );
  }
}
