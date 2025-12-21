import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../domain/entities/reciter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../blocs/reciter_chapters_bloc.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../../utils/audio_error_formatter.dart';
import 'chapter_card.dart';
import 'reciter_chapters_summary.dart';

class ReciterChaptersContent extends StatelessWidget {
  final Reciter reciter;
  final Color accentGreen;
  final Color darkSurfaceHigh;
  final Color darkSurface;

  const ReciterChaptersContent({
    super.key,
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
        ReciterChaptersSummary(
          downloadedCount: state.downloadedSurahNumbers.length,
          accentColor: accentGreen,
          isDark: isDark,
        ),
        ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 48),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 114,
          itemBuilder: (context, index) {
            final surahNumber = index + 1;
            final isDownloaded = state.isSurahDownloaded(surahNumber);

            return ChapterCard(
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
