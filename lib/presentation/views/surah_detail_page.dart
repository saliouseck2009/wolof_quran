import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';
import '../../core/helpers/revelation_place_enum.dart';
import '../../core/services/audio_player_service.dart';
import '../cubits/surah_detail_cubit.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../blocs/surah_download_status_bloc.dart';
import '../widgets/ayah_card.dart';
import '../widgets/ayah_play_button.dart';
import '../../service_locator.dart';
import '../../domain/usecases/get_downloaded_surahs_usecase.dart';

class SurahDetailPage extends StatelessWidget {
  static const String routeName = "/surah-detail";
  final int surahNumber;

  const SurahDetailPage({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SurahDetailCubit()..loadSurah(surahNumber),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColor.translationText),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColor.translationText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
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

    if (quranSettingsState is QuranSettingsLoaded &&
        quranSettingsState.selectedReciter != null) {
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
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final revelationType = quran.getPlaceOfRevelation(state.surahNumber);

    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      elevation: 2,
      title: Text(
        state.surahNameTranslated,
        style: GoogleFonts.amiri(
          fontWeight: FontWeight.w600,
          color: AppColor.pureWhite,
          fontSize: 18,
        ),
      ),
      actions: [
        // Display Mode Toggle Button
        PopupMenuButton<AyahDisplayMode>(
          icon: Icon(
            _getDisplayModeIcon(state.displayMode),
            color: AppColor.pureWhite,
          ),
          color: isDark ? AppColor.charcoal : AppColor.pureWhite,
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
                        ? AppColor.primaryGreen
                        : (isDark ? AppColor.pureWhite : AppColor.darkGray),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.arabicAndTranslation,
                    style: GoogleFonts.amiri(
                      color: state.displayMode == AyahDisplayMode.both
                          ? AppColor.primaryGreen
                          : (isDark ? AppColor.pureWhite : AppColor.darkGray),
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
                        ? AppColor.primaryGreen
                        : (isDark ? AppColor.pureWhite : AppColor.darkGray),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.arabicOnly,
                    style: GoogleFonts.amiri(
                      color: state.displayMode == AyahDisplayMode.arabicOnly
                          ? AppColor.primaryGreen
                          : (isDark ? AppColor.pureWhite : AppColor.darkGray),
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
                        ? AppColor.primaryGreen
                        : (isDark ? AppColor.pureWhite : AppColor.darkGray),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.translationOnly,
                    style: GoogleFonts.amiri(
                      color:
                          state.displayMode == AyahDisplayMode.translationOnly
                          ? AppColor.primaryGreen
                          : (isDark ? AppColor.pureWhite : AppColor.darkGray),
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
          icon: Icon(Icons.settings, color: AppColor.pureWhite),
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
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColor.charcoal, AppColor.darkGray],
                  )
                : AppColor.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SurahHeaderContent(
                state: state,
                localizations: localizations,
                revelationType: revelationType,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: isDark ? AppColor.charcoal : AppColor.primaryGreen,
      foregroundColor: AppColor.pureWhite,
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
          style: GoogleFonts.amiriQuran(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColor.pureWhite,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),

        const SizedBox(height: 8),

        // Translated name
        Text(
          state.surahNameTranslated,
          style: GoogleFonts.amiri(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColor.pureWhite.withValues(alpha: 0.9),
          ),
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
        color: AppColor.pureWhite.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColor.pureWhite),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.amiri(
              color: AppColor.pureWhite,
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
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColor.primaryGreen.withValues(alpha: 0.1),
              AppColor.gold.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColor.primaryGreen.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          quran.basmala,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiriQuran(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColor.primaryGreen,
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
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final ayah = ayahs[index];
        return AyahCard(
          verseNumber: ayah.verseNumber,
          arabicText: ayah.arabicText,
          translationSource: translationSource,
          translation: ayah.translation,
          displayMode: displayMode,
          actions: [
            AyahPlayButton(
              surahNumber: surahNumber,
              ayahNumber: ayah.verseNumber,
              surahName: quran.getSurahName(surahNumber),
            ),
            IconButton(
              icon: Icon(Icons.bookmark_border, color: AppColor.mediumGray),
              onPressed: () {
                // TODO: Implement bookmark functionality
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
    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      builder: (context, quranSettingsState) {
        if (quranSettingsState is! QuranSettingsLoaded ||
            quranSettingsState.selectedReciter == null) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error checking download status: ${downloadStatusState.message}',
                  ),
                  backgroundColor: AppColor.error,
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
                    color: AppColor.pureWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColor.pureWhite,
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
                    color: AppColor.pureWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColor.pureWhite.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Check failed',
                        style: GoogleFonts.amiri(
                          color: AppColor.pureWhite.withValues(alpha: 0.7),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.download_done,
                              color: AppColor.pureWhite,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$surahName downloaded successfully',
                                style: GoogleFonts.amiri(
                                  color: AppColor.pureWhite,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColor.success,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  } else if (currentState is AudioManagementError) {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColor.pureWhite,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Download failed: ${currentState.message}',
                                style: GoogleFonts.amiri(
                                  color: AppColor.pureWhite,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColor.error,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
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
                    // Show download progress
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.pureWhite.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: AppColor.pureWhite.withValues(alpha: 0.3),
                            width: 1,
                          ),
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
                                color: AppColor.pureWhite,
                                backgroundColor: AppColor.pureWhite.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Downloading... ${(currentState.progress * 100).toInt()}%',
                              style: GoogleFonts.amiri(
                                fontWeight: FontWeight.w600,
                                color: AppColor.pureWhite.withValues(
                                  alpha: 0.9,
                                ),
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
                        // Trigger download
                        context.read<AudioManagementCubit>().downloadSurahAudio(
                          selectedReciter.id,
                          surahNumber,
                        );
                      },
                      icon: Icon(
                        Icons.download_outlined,
                        color: AppColor.pureWhite.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      label: Text(
                        'Download to play',
                        style: GoogleFonts.amiri(
                          fontWeight: FontWeight.w600,
                          color: AppColor.pureWhite.withValues(alpha: 0.9),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.pureWhite.withValues(
                          alpha: 0.2,
                        ),
                        foregroundColor: AppColor.pureWhite.withValues(
                          alpha: 0.9,
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(
                            color: AppColor.pureWhite.withValues(alpha: 0.3),
                            width: 1,
                          ),
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
                                    ? AppColor.accent
                                    : AppColor.primaryGreen,
                                size: 20,
                              ),
                              label: Text(
                                isPlaying
                                    ? 'Pause Surah'
                                    : isPaused
                                    ? 'Resume Surah'
                                    : 'Play Surah',
                                style: GoogleFonts.amiri(
                                  fontWeight: FontWeight.w600,
                                  color: isThisSurahPlaying
                                      ? AppColor.accent
                                      : AppColor.primaryGreen,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.pureWhite,
                                foregroundColor: isThisSurahPlaying
                                    ? AppColor.accent
                                    : AppColor.primaryGreen,
                                elevation: isThisSurahPlaying ? 4 : 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  side: isThisSurahPlaying
                                      ? BorderSide(
                                          color: AppColor.accent,
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
