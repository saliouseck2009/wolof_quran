import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../settings/settings_menu_item.dart';

class QuranSettingsMenu extends StatelessWidget {
  final QuranSettingsState state;
  final AppLocalizations localizations;
  final VoidCallback onTranslationTap;
  final VoidCallback onFontSizeTap;
  final VoidCallback onRecitersTap;

  const QuranSettingsMenu({
    super.key,
    required this.state,
    required this.localizations,
    required this.onTranslationTap,
    required this.onFontSizeTap,
    required this.onRecitersTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentTranslationOption = QuranSettingsCubit.getTranslationOption(
      state.selectedTranslation,
    );
    final currentTranslationValue =
        currentTranslationOption?.displayName ?? localizations.unknown;

    return Column(
      children: [
        SettingsMenuItem(
          icon: Icons.translate,
          title: localizations.translationSettings,
          subtitle: localizations.currentTranslation,
          value: currentTranslationValue,
          onTap: onTranslationTap,
        ),
        const SizedBox(height: 16),
        SettingsMenuItem(
          icon: Icons.format_size,
          title: localizations.fontSettings,
          subtitle: localizations.ayahFontSize,
          value: '${state.ayahFontSize.toInt()}pt',
          onTap: onFontSizeTap,
        ),
        const SizedBox(height: 16),
        SettingsMenuItem(
          icon: Icons.volume_up,
          title: localizations.audioAndReciters,
          subtitle: localizations.manageRecitersAndDownloadAudio,
          value: localizations.viewAvailableReciters,
          onTap: onRecitersTap,
          showArrow: true,
        ),
      ],
    );
  }
}
