import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import '../../core/utils/toast_service.dart';
import '../../domain/repositories/download_repository.dart';
import '../cubits/reciter_cubit.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../../service_locator.dart';
import '../../l10n/generated/app_localizations.dart';
import '../utils/audio_error_formatter.dart';

class SurahAudioListPage extends StatelessWidget {
  static const String routeName = "/surah-audio-list";

  const SurahAudioListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => locator<ReciterCubit>()..loadReciters(),
        ),
        BlocProvider(
          create: (context) => locator<AudioManagementCubit>()..initialize(),
        ),
      ],
      child: const _SurahAudioListView(),
    );
  }
}

class _SurahAudioListView extends StatelessWidget {
  const _SurahAudioListView();

  // Helper method to safely check download status
  Future<bool> _checkDownloadStatus(String reciterId, int surahNumber) async {
    try {
      return await locator<DownloadRepository>().isSurahDownloaded(
        reciterId,
        surahNumber,
      );
    } catch (e) {
      print('Could not check download status from database: $e');
      return false; // Fallback to not downloaded
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentGreen = colorScheme.primary;
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surface,
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
            ? colorScheme.surfaceContainer.withValues(alpha: 0.7)
            : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 2,
      ),
      body: BlocListener<AudioManagementCubit, AudioManagementState>(
        listenWhen: (previous, current) =>
            current is AudioManagementError &&
            previous is! AudioManagementError,
        listener: (context, state) {
          if (state is AudioManagementError) {
            final friendly =
                formatAudioError(state.message, AppLocalizations.of(context)!);
            ToastService.showError(context, friendly);
          }
        },
        child: BlocBuilder<ReciterCubit, ReciterState>(
          builder: (context, reciterState) {
            if (reciterState is ReciterLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (reciterState is ReciterError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      reciterState.message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (reciterState is ReciterLoaded) {
              final selectedReciter = reciterState.selectedReciter;

              if (selectedReciter == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.noReciterSelected,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/quran-settings');
                        },
                        child: Text(localizations.selectReciter),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Selected reciter info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: colorScheme.brightness == Brightness.dark
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.surfaceContainer.withValues(
                                  alpha: 0.8,
                                ),
                                colorScheme.surfaceContainer.withValues(
                                  alpha: 0.9,
                                ),
                              ],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.1),
                                colorScheme.primaryContainer.withValues(
                                  alpha: 0.2,
                                ),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.record_voice_over,
                          color: accentGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedReciter.name,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                selectedReciter.arabicName,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontFamily: 'Hafs',
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/quran-settings');
                          },
                          child: Text(localizations.change),
                        ),
                      ],
                    ),
                  ),

                  // Surah list
                  Expanded(
                    child:
                        BlocBuilder<AudioManagementCubit, AudioManagementState>(
                          builder: (context, audioState) {
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: 114, // 114 surahs
                              itemBuilder: (context, index) {
                                final surahNumber = index + 1;
                                return _buildSurahCard(
                                  context,
                                  surahNumber,
                                  selectedReciter.id,
                                  audioState,
                                );
                              },
                            );
                          },
                        ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSurahCard(
    BuildContext context,
    int surahNumber,
    String reciterId,
    AudioManagementState audioState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentGreen = colorScheme.primary;
    final surahNameArabic = quran.getSurahNameArabic(surahNumber);
    final surahNameTranslated = QuranSettingsCubit.getSurahNameInTranslation(
      surahNumber,
      quran.Translation.frHamidullah, // TODO: Use user's selected translation
    );
    final versesCount = quran.getVerseCount(surahNumber);
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<bool>(
      future: _checkDownloadStatus(reciterId, surahNumber),
      builder: (context, downloadSnapshot) {
        // Get download status from database (with fallback)
        bool isDownloaded = downloadSnapshot.data ?? false;
        bool isDownloading = false;
        double downloadProgress = 0.0;

        // Check for current downloading state
        if (audioState is AudioDownloading &&
            audioState.reciterId == reciterId &&
            audioState.surahNumber == surahNumber) {
          isDownloading = true;
          downloadProgress = audioState.progress;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: colorScheme.brightness == Brightness.dark
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: Border.all(
              color: colorScheme.primary.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.1 : 0.15,
              ),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isDownloaded
                ? () {
                    // Navigate to surah detail page with audio playback
                    // TODO: Implement navigation to detail page
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Surah number circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentGreen.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  child: Center(
                    child: Text(
                      surahNumber.toString(),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accentGreen,
                      ),
                    ),
                  ),
                ),

                  const SizedBox(width: 16),

                  // Surah info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                surahNameTranslated,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              surahNameArabic,
                              style: textTheme.titleMedium?.copyWith(
                                fontFamily: 'Hafs',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: accentGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations.ayahCountLabel(versesCount),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Download/Play button
                  if (isDownloading)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: downloadProgress,
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${(downloadProgress * 100).round()}%',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        isDownloaded
                            ? Icons.play_circle_filled
                            : Icons.download,
                        color: isDownloaded
                            ? accentGreen
                            : colorScheme.onSurfaceVariant,
                        size: 32,
                      ),
                      onPressed: () {
                        if (isDownloaded) {
                          // Play surah
                          context
                              .read<AudioManagementCubit>()
                              .playSurahPlaylist(
                                reciterId,
                                surahNumber,
                                surahName: surahNameTranslated,
                              );
                        } else {
                          // Download surah
                          context
                              .read<AudioManagementCubit>()
                              .downloadSurahAudio(reciterId, surahNumber);
                        }
                      },
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
