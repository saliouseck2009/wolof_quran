import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/localization/localization_service.dart';
import '../../core/services/app_info_service.dart';
import '../../l10n/generated/app_localizations.dart';
import 'about_page.dart';
import 'privacy_policy_page.dart';
import 'support_page.dart';
import '../cubits/language_cubit.dart';
import '../cubits/theme_cubit.dart';
import '../widgets/settings/settings_choice_menu_item.dart';
import '../widgets/settings/settings_header.dart';
import '../widgets/settings/settings_menu_item.dart';

class SettingsPage extends StatefulWidget {
  static const String routeName = "/settings";

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Future<String> _appVersionFuture;

  @override
  void initState() {
    super.initState();
    _appVersionFuture = AppInfoService.getAppVersionLabel();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;

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
        backgroundColor: colorScheme.brightness == Brightness.dark
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
            FutureBuilder<String>(
              future: _appVersionFuture,
              builder: (context, snapshot) {
                return _SettingsMenu(
                  localizations: localizations,
                  appVersion: snapshot.data ?? '--',
                  onShowAbout: () =>
                      Navigator.pushNamed(context, AboutPage.routeName),
                  onShowPrivacyPolicy: () =>
                      Navigator.pushNamed(context, PrivacyPolicyPage.routeName),
                  showSupport: !isIos,
                  onShowSupport: isIos
                      ? null
                      : () =>
                            Navigator.pushNamed(context, SupportPage.routeName),
                );
              },
            ),
            const SizedBox(height: 54),
          ],
        ),
      ),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  final AppLocalizations localizations;
  final String appVersion;
  final VoidCallback onShowAbout;
  final VoidCallback onShowPrivacyPolicy;
  final bool showSupport;
  final VoidCallback? onShowSupport;

  const _SettingsMenu({
    required this.localizations,
    required this.appVersion,
    required this.onShowAbout,
    required this.onShowPrivacyPolicy,
    required this.showSupport,
    required this.onShowSupport,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.watch<LanguageCubit>().state;
    final themeCubit = context.watch<ThemeCubit>();
    final currentTheme = themeCubit.state;

    return Column(
      children: [
        SettingsChoiceMenuItem<String>(
          icon: Icons.language,
          title: localizations.language,
          subtitle: localizations.changeAppLanguage,
          value: LocalizationService.getLanguageName(currentLocale),
          selected: currentLocale.languageCode,
          choices: [
            for (final locale in LocalizationService.supportedLocales)
              SettingsChoice(
                value: locale.languageCode,
                label: LocalizationService.getLanguageName(locale),
                // The name in the current language helps whoever cannot
                // read the native one.
                secondary: locale.languageCode == currentLocale.languageCode
                    ? null
                    : _languageNameInAppLanguage(locale),
              ),
          ],
          onSelected: (code) => context.read<LanguageCubit>().changeLanguage(
            LocalizationService.supportedLocales.firstWhere(
              (locale) => locale.languageCode == code,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SettingsChoiceMenuItem<ThemeMode>(
          icon: Icons.palette,
          title: localizations.theme,
          subtitle: localizations.chooseAppTheme,
          value: themeCubit.getThemeName(currentTheme, localizations),
          selected: currentTheme,
          choices: [
            for (final (mode, icon) in const [
              (ThemeMode.light, Icons.light_mode_outlined),
              (ThemeMode.dark, Icons.dark_mode_outlined),
              (ThemeMode.system, Icons.contrast_rounded),
            ])
              SettingsChoice(
                value: mode,
                label: themeCubit.getThemeName(mode, localizations),
                icon: icon,
              ),
          ],
          onSelected: themeCubit.changeTheme,
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
        if (showSupport) ...[
          SettingsMenuItem(
            icon: Icons.favorite_outline,
            title: localizations.supportProject,
            subtitle: localizations.supportSubtitle,
            value: localizations.supportValue,
            onTap: onShowSupport!,
            showArrow: true,
          ),
          const SizedBox(height: 16),
        ],
        SettingsMenuItem(
          icon: Icons.info_outline,
          title: localizations.about,
          subtitle: localizations.aboutSubtitle,
          value: localizations.appVersion(appVersion),
          onTap: onShowAbout,
          showArrow: true,
        ),
        const SizedBox(height: 16),
        SettingsMenuItem(
          icon: Icons.privacy_tip_outlined,
          title: localizations.privacyPolicy,
          subtitle: localizations.privacyPolicySubtitle,
          value: localizations.privacyPolicyValue,
          onTap: onShowPrivacyPolicy,
          showArrow: true,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _languageNameInAppLanguage(Locale locale) {
    return switch (locale.languageCode) {
      'en' => localizations.english,
      'ar' => localizations.arabic,
      _ => localizations.french,
    };
  }
}
