import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../../utils/home_card_colors.dart';
import '../settings/settings_sheet.dart';

/// Lets the user pick the size of the verses, with a live preview. Each
/// move of the slider is applied right away.
Future<void> showFontSizeSettingsSheet(BuildContext context) {
  final localizations = AppLocalizations.of(context)!;
  return showSettingsSheet<void>(
    context: context,
    title: localizations.fontSettings,
    subtitle: localizations.fontSizeDescription,
    builder: (_) => const _FontSizeSettings(),
  );
}

class _FontSizeSettings extends StatelessWidget {
  const _FontSizeSettings();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = homeAccentColor(colorScheme);
    final muted = colorScheme.onSurface.withValues(alpha: 0.65);

    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      buildWhen: (previous, current) =>
          previous.ayahFontSize != current.ayahFontSize,
      builder: (context, state) {
        final fontSize = state.ayahFontSize;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSheetCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Hafs',
                  fontSize: fontSize,
                  height: 1.8,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingsSheetCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        localizations.small,
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                      Expanded(
                        child: Text(
                          '${fontSize.toInt()}pt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: homeAccentInk(colorScheme),
                          ),
                        ),
                      ),
                      Text(
                        localizations.large,
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                    ],
                  ),
                  Slider(
                    value: fontSize,
                    min: QuranSettingsCubit.minFontSize,
                    max: QuranSettingsCubit.maxFontSize,
                    divisions:
                        ((QuranSettingsCubit.maxFontSize -
                                    QuranSettingsCubit.minFontSize) /
                                2)
                            .round(),
                    activeColor: accent,
                    inactiveColor: accent.withValues(alpha: 0.18),
                    onChanged: context
                        .read<QuranSettingsCubit>()
                        .updateAyahFontSize,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(localizations.close),
            ),
          ],
        );
      },
    );
  }
}
