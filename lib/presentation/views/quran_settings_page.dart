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
import '../widgets/quran_settings/translation_selector_sheet.dart';

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
                  onTranslationTap: () =>
                      _showTranslationSelector(context, state, localizations),
                  onFontSizeTap: () =>
                      _showFontSizeSelector(context, state, localizations),
                  onRecitersTap: () {
                    Navigator.pushNamed(context, '/reciter-list');
                  },
                ),
                const SizedBox(height: 24),

                // Future settings sections can be added here
                // Example: Audio settings, font size, etc.
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTranslationSelector(
    BuildContext context,
    QuranSettingsState state,
    AppLocalizations localizations,
  ) async {
    final result = await showModalBottomSheet<TranslationOption?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => TranslationSelectorSheet(
        currentTranslation: state.selectedTranslation,
        localizations: localizations,
        onTranslationSelected: (translation) {
          log('🎯 Translation selected in modal: $translation');
          context.read<QuranSettingsCubit>().updateTranslation(translation);
        },
      ),
    );

    // If translation was changed, show feedback and return true to parent
    if (result != null && context.mounted) {
      CustomSnackbar.showSnackbar(
        context,
        localizations.translationUpdated(result.language),
        duration: 2,
      );
      Navigator.pop(context, true);
    }
  }

  void _showFontSizeSelector(
    BuildContext context,
    QuranSettingsState state,
    AppLocalizations localizations,
  ) async {
    final result = await showModalBottomSheet<double?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => FontSizeSelectorSheet(
        currentFontSize: state.ayahFontSize,
        localizations: localizations,
        onFontSizeChanged: (fontSize) {
          context.read<QuranSettingsCubit>().updateAyahFontSize(fontSize);
        },
      ),
    );

    // If font size was changed, return true to parent
    if (result != null && context.mounted) {
      Navigator.pop(context, true);
    }
  }
}
