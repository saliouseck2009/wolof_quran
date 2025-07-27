import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/theme/app_color.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/entities/surah_audio_status.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';

class ReciterChaptersPage extends StatelessWidget {
  final Reciter reciter;

  const ReciterChaptersPage({super.key, required this.reciter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<quran.Translation>(
      future: _getCurrentTranslation(),
      builder: (context, snapshot) {
        final translation = snapshot.data;
        return _ReciterChaptersContent(
          reciter: reciter,
          translation: translation,
        );
      },
    );
  }

  Future<quran.Translation> _getCurrentTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    final translationIndex = prefs.getInt('selected_quran_translation');

    if (translationIndex != null &&
        translationIndex < QuranSettingsCubit.availableTranslations.length) {
      return QuranSettingsCubit
          .availableTranslations[translationIndex]
          .translation;
    } else {
      // Default to French for first-time users
      return quran.Translation.frHamidullah;
    }
  }
}

class _ReciterChaptersContent extends StatelessWidget {
  final Reciter reciter;
  final quran.Translation? translation;

  const _ReciterChaptersContent({required this.reciter, this.translation});

  void _loadChapterStatuses(BuildContext context) {
    // Initialize the cubit
    context.read<AudioManagementCubit>().initialize();
    // Load status for first 114 surahs (chapters)
    for (int i = 1; i <= 114; i++) {
      context.read<AudioManagementCubit>().refreshSurahStatus(reciter.id, i);
    }
  }

  String _getFormattedErrorMessage(String error) {
    if (error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('internet')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.toLowerCase().contains('404')) {
      return 'Surah not available yet. Please try again later.';
    } else if (error.toLowerCase().contains('server') ||
        error.toLowerCase().contains('500')) {
      return 'Server error. Please try again later.';
    } else if (error.toLowerCase().contains('storage') ||
        error.toLowerCase().contains('space')) {
      return 'Not enough storage space. Please free up some space and try again.';
    } else if (error.toLowerCase().contains('permission')) {
      return 'Storage permission required. Please grant permission and try again.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  String _getSurahDisplayName(int surahNumber) {
    final arabicName = quran.getSurahNameArabic(surahNumber);
    if (translation != null) {
      final translatedName = QuranSettingsCubit.getSurahNameInTranslation(
        surahNumber,
        translation!,
      );
      return '$arabicName - $translatedName';
    }
    return '$arabicName - ${quran.getSurahNameEnglish(surahNumber)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Initialize data when widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChapterStatuses(context);
    });

    return Scaffold(
      backgroundColor: isDark ? AppColor.charcoal : AppColor.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? AppColor.pureWhite : AppColor.charcoal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              reciter.name,
              style: GoogleFonts.amiri(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColor.pureWhite : AppColor.charcoal,
              ),
            ),
            Text(
              reciter.arabicName,
              style: GoogleFonts.amiri(
                fontSize: 14,
                color: AppColor.mediumGray,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<AudioManagementCubit, AudioManagementState>(
        builder: (context, state) {
          if (state is AudioManagementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AudioManagementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Chapters', // TODO: Add to localizations
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColor.pureWhite : AppColor.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFormattedErrorMessage(state.message),
                    style: GoogleFonts.amiri(
                      fontSize: 14,
                      color: AppColor.mediumGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _loadChapterStatuses(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryGreen,
                      foregroundColor: AppColor.pureWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Retry', // TODO: Add to localizations
                      style: GoogleFonts.amiri(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is AudioManagementLoaded || state is AudioDownloading) {
            // For downloading state, we need to get the latest loaded state
            // The AudioDownloading state doesn't contain the surah status map
            // So we'll need to handle this differently
            if (state is AudioDownloading) {
              // Show the list with current data, individual buttons will handle download state
              return _buildChaptersList(
                context,
                isDark,
                const AudioManagementLoaded(
                  surahStatusMap: {},
                  ayahAudiosMap: {},
                ),
              );
            }

            // Normal loaded state
            return _buildChaptersList(
              context,
              isDark,
              state as AudioManagementLoaded,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildChaptersList(
    BuildContext context,
    bool isDark,
    AudioManagementLoaded state,
  ) {
    // Create a list of all 114 surahs with their status
    final chapters = List.generate(114, (index) {
      final surahNumber = index + 1;
      final status = state.getSurahStatus(reciter.id, surahNumber);
      return {'surahNumber': surahNumber, 'status': status};
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final surahNumber = chapter['surahNumber'] as int;
        final status = chapter['status'] as SurahAudioStatus?;
        final isDownloaded = status?.isDownloaded ?? false;

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
                      style: GoogleFonts.amiri(
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
                        _getSurahDisplayName(surahNumber),
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColor.pureWhite
                              : AppColor.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<AudioManagementCubit, AudioManagementState>(
                        builder: (context, currentState) {
                          bool currentDownloadStatus = isDownloaded;
                          if (currentState is AudioManagementLoaded) {
                            final currentStatus = currentState.getSurahStatus(
                              reciter.id,
                              surahNumber,
                            );
                            currentDownloadStatus =
                                currentStatus?.isDownloaded ?? false;
                          }

                          String statusText = currentDownloadStatus
                              ? 'Downloaded'
                              : 'Not downloaded';
                          if (currentState is AudioDownloading &&
                              currentState.reciterId == reciter.id &&
                              currentState.surahNumber == surahNumber) {
                            statusText =
                                'Downloading ${(currentState.progress * 100).toInt()}%';
                          }

                          return Text(
                            statusText,
                            style: GoogleFonts.amiri(
                              fontSize: 14,
                              color: currentDownloadStatus
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

                // Action button
                BlocBuilder<AudioManagementCubit, AudioManagementState>(
                  builder: (context, currentState) {
                    // Always check the latest state for download status
                    bool isCurrentlyDownloaded = isDownloaded;
                    if (currentState is AudioManagementLoaded) {
                      final currentStatus = currentState.getSurahStatus(
                        reciter.id,
                        surahNumber,
                      );
                      isCurrentlyDownloaded =
                          currentStatus?.isDownloaded ?? false;
                    }

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
                                  backgroundColor: AppColor.primaryGreen
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              Text(
                                '${(currentState.progress * 100).toInt()}%',
                                style: GoogleFonts.amiri(
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
                            style: GoogleFonts.amiri(
                              fontSize: 10,
                              color: AppColor.primaryGreen,
                            ),
                          ),
                        ],
                      );
                    }

                    if (isCurrentlyDownloaded) {
                      // Play button
                      return IconButton(
                        onPressed: () {
                          // Load ayah audios and play surah playlist
                          context.read<AudioManagementCubit>().loadAyahAudios(
                            reciter.id,
                            surahNumber,
                          );
                          context
                              .read<AudioManagementCubit>()
                              .playSurahPlaylist(
                                reciter.id,
                                surahNumber,
                                surahName: _getSurahDisplayName(surahNumber),
                                startAyahIndex: 0,
                              );
                        },
                        icon: Icon(
                          Icons.play_circle_filled,
                          color: AppColor.primaryGreen,
                          size: 32,
                        ),
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

                // Separate listener for snackbars
                BlocListener<AudioManagementCubit, AudioManagementState>(
                  listenWhen: (previous, current) {
                    // Only listen when state changes from downloading to loaded/error
                    // for this specific surah
                    if (previous is AudioDownloading &&
                        previous.reciterId == reciter.id &&
                        previous.surahNumber == surahNumber) {
                      return current is AudioManagementLoaded ||
                          current is AudioManagementError;
                    }
                    return false;
                  },
                  listener: (context, currentState) {
                    // Handle download completion or error
                    if (currentState is AudioManagementLoaded) {
                      final currentStatus = currentState.getSurahStatus(
                        reciter.id,
                        surahNumber,
                      );
                      if (currentStatus?.isDownloaded == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${_getSurahDisplayName(surahNumber)} downloaded successfully',
                            ),
                            backgroundColor: AppColor.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } else if (currentState is AudioManagementError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _getFormattedErrorMessage(currentState.message),
                          ),
                          backgroundColor: AppColor.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
