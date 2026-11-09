import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/reciter_cubit.dart';
import '../../service_locator.dart';
import '../widgets/snackbar.dart';
import '../widgets/quran_settings/font_size_selector_sheet.dart';
import '../widgets/quran_settings/quran_settings_header.dart';
import '../widgets/quran_settings/quran_settings_menu.dart';
import '../widgets/quran_settings/reading_tracking_settings_sheet.dart';
import '../widgets/settings/settings_menu_item.dart';
import 'support_page.dart';

class QuranSettingsPage extends StatelessWidget {
  static const String routeName = "/quran-settings";

  const QuranSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => locator<ReciterCubit>()..loadReciters(),
        ),
      ],
      child: const _QuranSettingsView(),
    );
  }
}

class _QuranSettingsView extends StatelessWidget {
  const _QuranSettingsView();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.quranSettings,
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
      body: BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuranSettingsHeader(localizations: localizations),
                const SizedBox(height: 24),
                QuranSettingsMenu(
                  state: state,
                  localizations: localizations,
                  onTranslationSelected: (option) =>
                      _selectTranslation(context, option, localizations),
                  onFontSizeTap: () => showFontSizeSettingsSheet(context),
                  onRecitersTap: () {
                    Navigator.pushNamed(context, '/reciter-list');
                  },
                  onReadingTrackingTap: () =>
                      showReadingTrackingSettingsSheet(context),
                ),
                if (SupportPage.isAvailable) ...[
                  const SizedBox(height: 24),
                  SettingsMenuItem(
                    icon: Icons.favorite_outline,
                    title: localizations.supportProject,
                    subtitle: localizations.supportSubtitle,
                    value: localizations.supportValue,
                    onTap: () =>
                        Navigator.pushNamed(context, SupportPage.routeName),
                    showArrow: true,
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectTranslation(
    BuildContext context,
    TranslationOption option,
    AppLocalizations localizations,
  ) {
    log('🎯 Translation selected: ${option.translation}');
    context.read<QuranSettingsCubit>().updateTranslation(option.translation);
    CustomSnackbar.showSnackbar(
      context,
      localizations.translationUpdated(option.language),
      duration: 2,
    );
    // Tells the page that opened the settings to reload its translation.
    Navigator.pop(context, true);
  }
}
