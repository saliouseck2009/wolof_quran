import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/generated/app_localizations.dart';

enum AppThemeMode { light, dark, system }

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void changeTheme(ThemeMode themeMode) async {
    // For now, just emit the new theme
    // Later we'll add SharedPreferences persistence
    emit(themeMode);
  }

  String getThemeName(ThemeMode themeMode, AppLocalizations localizations) {
    switch (themeMode) {
      case ThemeMode.light:
        return localizations.light;
      case ThemeMode.dark:
        return localizations.dark;
      case ThemeMode.system:
        return "Système";
    }
  }

  IconData getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_system_daydream;
    }
  }

  Color getThemeColor(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return const Color(0xFFDAA520); // Gold
      case ThemeMode.dark:
        return const Color(0xFF1B4332); // Primary Green
      case ThemeMode.system:
        return const Color(0xFF52B788); // Accent
    }
  }
}
