import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/config/theme/app_color.dart';
import '../../../core/helpers/revelation_place_enum.dart';
import '../../../domain/usecases/get_downloaded_surahs_usecase.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../service_locator.dart';
import '../../blocs/surah_download_status_bloc.dart';
import '../../cubits/surah_detail_cubit.dart';
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

    return BlocProvider(
      create: (context) => SurahDownloadStatusBloc(
        getDownloadedSurahsUseCase: locator<GetDownloadedSurahsUseCase>(),
      ),
      child: SliverAppBar(
        expandedHeight: 150,
        floating: false,
        pinned: true,
        centerTitle: false,
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? AppColor.surfaceDark
            : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Text(
          '${state.surahNumber} - ${state.surahNameTranslated}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 15,
          ),
        ),
        actions: [
          SurahPlayButton(
            surahNumber: state.surahNumber,
            surahName: state.surahNameTranslated,
            variant: SurahPlayButtonVariant.icon,
          ),
          PopupMenuButton<AyahDisplayMode>(
            tooltip: localizations.arabicAndTranslation,
            icon: Icon(Icons.g_translate, color: colorScheme.onPrimary),
            color: colorScheme.surfaceContainer,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (mode) {
              context.read<SurahDetailCubit>().changeDisplayMode(mode);
            },
            itemBuilder: (context) => [
              _buildModeItem(
                context: context,
                mode: AyahDisplayMode.both,
                icon: Icons.view_headline,
                label: localizations.arabicAndTranslation,
                currentMode: state.displayMode,
              ),
              _buildModeItem(
                context: context,
                mode: AyahDisplayMode.arabicOnly,
                icon: Icons.format_textdirection_r_to_l,
                label: localizations.arabicOnly,
                currentMode: state.displayMode,
              ),
              _buildModeItem(
                context: context,
                mode: AyahDisplayMode.translationOnly,
                icon: Icons.translate,
                label: localizations.translationOnly,
                currentMode: state.displayMode,
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.tune, color: colorScheme.onPrimary),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SurahHeaderContent(
                  state: state,
                  localizations: localizations,
                  revelationType: revelationType,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<AyahDisplayMode> _buildModeItem({
    required BuildContext context,
    required AyahDisplayMode mode,
    required IconData icon,
    required String label,
    required AyahDisplayMode currentMode,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final isSelected = currentMode == mode;
    final backgroundColor = isDark
        ? colorScheme.surface
        : colorScheme.primary.withValues(alpha: 0.1);
    return PopupMenuItem<AyahDisplayMode>(
      value: mode,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? backgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(
              width: 20,
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    )
                  : null,
            ),
          ],
        ),
      ),
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
        Text(
          state.surahNameArabic,
          style: const TextStyle(
            fontFamily: 'Hafs',
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 10),
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
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final color = isDark
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
