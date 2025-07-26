import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';
import '../../core/helpers/revelation_place_enum.dart';
import '../cubits/surah_detail_cubit.dart';
import '../widgets/ayah_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Modern App Bar with Surah Info
        SurahDetailAppBar(state: state),

        // Basmala (except for Surah At-Tawbah)
        if (surahNumber != 9) const SurahBasmalaWidget(),

        // List of Ayahs
        SurahAyahsList(ayahs: state.ayahs),

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
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 2,
      title: Text(
        state.surahNameEnglish,
        style: GoogleFonts.amiri(
          fontWeight: FontWeight.w600,
          color: AppColor.pureWhite,
          fontSize: 18,
        ),
      ),
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

        // English name
        Text(
          state.surahNameEnglish,
          style: GoogleFonts.amiri(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColor.pureWhite.withValues(alpha: 0.9),
          ),
        ),

        const SizedBox(height: 16),

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
  final List<AyahData> ayahs;

  const SurahAyahsList({super.key, required this.ayahs});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final ayah = ayahs[index];
        return AyahCard(
          verseNumber: ayah.verseNumber,
          arabicText: ayah.arabicText,
          translationSource: "Sahih International",
          translation: ayah.translation,
          actions: [
            IconButton(
              icon: Icon(Icons.play_arrow, color: AppColor.primaryGreen),
              onPressed: () {
                // TODO: Implement audio playback
              },
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
