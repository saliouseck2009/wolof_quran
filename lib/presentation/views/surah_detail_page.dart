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
import '../widgets/ayah_card.dart';
import '../widgets/ayah_play_button.dart';

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

        // Basmala (except for Surah At-Tawbah)
        if (surahNumber != 9) const SurahBasmalaWidget(),

        // List of Ayahs
        SurahAyahsList(
          surahNumber: surahNumber,
          ayahs: state.ayahs,
          translationSource: state.translationSource,
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
        BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
          builder: (context, quranSettingsState) {
            if (quranSettingsState is QuranSettingsLoaded &&
                quranSettingsState.selectedReciter != null) {
              return BlocBuilder<AudioManagementCubit, AudioManagementState>(
                builder: (context, audioState) {
                  final isDownloaded = true;
                  // audioState is AudioManagementLoaded &&
                  //     audioState.getSurahStatus(
                  //       quranSettingsState.selectedReciter!.id,
                  //       state.surahNumber,
                  //     )?.isDownloaded == true;

                  if (isDownloaded) {
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
                                currentAudio.surahNumber == state.surahNumber &&
                                currentAudio.reciterId ==
                                    quranSettingsState.selectedReciter!.id &&
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
                                      quranSettingsState.selectedReciter!.id,
                                      state.surahNumber,
                                    );

                                    // Play the entire surah as playlist
                                    audioManagementCubit.playSurahPlaylist(
                                      quranSettingsState.selectedReciter!.id,
                                      state.surahNumber,
                                      surahName: state.surahNameTranslated,
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
                  } else {
                    // Show download prompt or disabled state
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.pureWhite.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download,
                              size: 16,
                              color: AppColor.pureWhite.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Download to play',
                              style: GoogleFonts.amiri(
                                color: AppColor.pureWhite.withValues(
                                  alpha: 0.7,
                                ),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              );
            }
            return const SizedBox.shrink();
          },
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

  const SurahAyahsList({
    super.key,
    required this.surahNumber,
    required this.ayahs,
    required this.translationSource,
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
