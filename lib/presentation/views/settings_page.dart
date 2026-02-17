import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/localization/localization_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/language_cubit.dart';
import '../cubits/theme_cubit.dart';
import '../widgets/settings/about_app_dialog.dart';
import '../widgets/settings/language_selector_sheet.dart';
import '../widgets/settings/settings_header.dart';
import '../widgets/settings/settings_menu_item.dart';
import '../widgets/settings/theme_selector_sheet.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = "/settings";

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.settings,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor:
            colorScheme.brightness == Brightness.dark
                ? colorScheme.surface
                : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsHeader(localizations: localizations),
            const SizedBox(height: 24),
            _SettingsMenu(
              localizations: localizations,
              onShowLanguage: () => _showLanguageSelector(
                context,
                localizations,
              ),
              onShowTheme: () => _showThemeSelector(
                context,
                localizations,
              ),
              onShowAbout: () => showAboutAppDialog(context),
            ),
            const SizedBox(height: 54),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageSelectorSheet(localizations: localizations),
    );
  }

  void _showThemeSelector(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThemeSelectorSheet(localizations: localizations),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  final AppLocalizations localizations;
  final VoidCallback onShowLanguage;
  final VoidCallback onShowTheme;
  final VoidCallback onShowAbout;

  const _SettingsMenu({
    required this.localizations,
    required this.onShowLanguage,
    required this.onShowTheme,
    required this.onShowAbout,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.watch<LanguageCubit>().state;
    final languageValue =
        LocalizationService.getLanguageName(currentLocale);

    return Column(
      children: [
        SettingsMenuItem(
          icon: Icons.language,
          title: localizations.language,
          subtitle: localizations.changeAppLanguage,
          value: languageValue,
          onTap: onShowLanguage,
        ),
        const SizedBox(height: 16),
        SettingsMenuItem(
          icon: Icons.palette,
          title: localizations.theme,
          subtitle: localizations.chooseAppTheme,
          value: _getCurrentThemeName(context, localizations),
          onTap: onShowTheme,
        ),
        const SizedBox(height: 16),
        SettingsMenuItem(
          icon: Icons.settings_applications,
          title: localizations.quranSettings,
          subtitle: localizations.manageRecitersAndDownloadAudio,
          value: localizations.managePreferences,
          onTap: () => Navigator.pushNamed(context, '/quran-settings'),
          showArrow: true,
        ),
        const SizedBox(height: 16),
        SettingsMenuItem(
          icon: Icons.info_outline,
          title: localizations.about,
          subtitle: localizations.aboutSubtitle,
          value: localizations.appVersion('1.0.0'),
          onTap: onShowAbout,
        ),
      ],
    );
  }

  String _getCurrentThemeName(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final themeCubit = context.read<ThemeCubit>();
    final currentTheme = themeCubit.state;
    return themeCubit.getThemeName(currentTheme, localizations);
  }
}
