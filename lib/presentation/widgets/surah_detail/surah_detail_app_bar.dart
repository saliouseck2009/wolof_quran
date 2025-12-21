import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/config/theme/app_color.dart';
import '../../../core/helpers/revelation_place_enum.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/surah_detail_cubit.dart';
import '../../blocs/surah_download_status_bloc.dart';
import '../../../domain/usecases/get_downloaded_surahs_usecase.dart';
import '../../../service_locator.dart';
import 'surah_detail_play_button.dart';

class SurahDetailAppBar extends StatelessWidget {
  final SurahDetailLoaded state;

  const SurahDetailAppBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final revelationType = quran.getPlaceOfRevelation(state.surahNumber);

    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? AppColor.surfaceDark
          : colorScheme.primary,
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      title: Text(
        state.surahNameTranslated,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
          fontSize: 18,
        ),
      ),
      actions: [
        PopupMenuButton<AyahDisplayMode>(
          icon: Icon(
            _getDisplayModeIcon(state.displayMode),
            color: colorScheme.onPrimary,
          ),
          color: colorScheme.surface,
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
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.arabicAndTranslation,
                    style: TextStyle(
                      color: state.displayMode == AyahDisplayMode.both
                          ? colorScheme.primary
                          : colorScheme.onSurface,
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
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.arabicOnly,
                    style: TextStyle(
                      color: state.displayMode == AyahDisplayMode.arabicOnly
                          ? colorScheme.primary
                          : colorScheme.onSurface,
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
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    localizations.translationOnly,
                    style: TextStyle(
                      color: state.displayMode == AyahDisplayMode.translationOnly
                          ? colorScheme.primary
                          : colorScheme.onSurface,
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
          icon: Icon(Icons.settings, color: colorScheme.onPrimary),
          onPressed: () async {
            final result = await Navigator.pushNamed(
              context,
              '/quran-settings',
            );
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
            color: colorScheme.brightness == Brightness.dark
                ? AppColor.surfaceDark
                : colorScheme.primary,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SurahHeaderContent(
                state: state,
                localizations: localizations,
                revelationType: revelationType,
              ),
            ),
          ),
        ),
      ),
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
        Text(
          state.surahNameArabic,
          style: const TextStyle(
            fontFamily: 'Hafs',
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 16),
        BlocProvider(
          create: (context) => SurahDownloadStatusBloc(
            getDownloadedSurahsUseCase: locator<GetDownloadedSurahsUseCase>(),
          ),
          child: SurahPlayButton(
            surahNumber: state.surahNumber,
            surahName: state.surahNameTranslated,
          ),
        ),
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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
