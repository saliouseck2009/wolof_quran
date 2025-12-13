import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/generated/app_localizations.dart';

enum AppThemeMode { light, dark, system }

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'selected_theme_mode';

  ThemeCubit() : super(ThemeMode.system) {
    _loadThemeFromPrefs();
  }

  /// Load theme from SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeKey);

      if (themeModeIndex != null) {
        final themeMode = ThemeMode.values[themeModeIndex];
        emit(themeMode);
      }
    } catch (e) {
      // If loading fails, keep the default system theme
      emit(ThemeMode.system);
    }
  }

  /// Save theme to SharedPreferences
  Future<void> _saveThemeToPrefs(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
    } catch (e) {
      // Handle save error if needed
      debugPrint('Failed to save theme preference: $e');
    }
  }

  /// Change theme and persist it
  Future<void> changeTheme(ThemeMode themeMode) async {
    emit(themeMode);
    await _saveThemeToPrefs(themeMode);
  }

  /// Get the currently saved theme from SharedPreferences
  /// This is useful for getting the theme without emitting state changes
  static Future<ThemeMode> getSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeKey);

      if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
        return ThemeMode.values[themeModeIndex];
      }
    } catch (e) {
      debugPrint('Failed to load saved theme: $e');
    }
    return ThemeMode.system; // Default fallback
  }

  String getThemeName(ThemeMode themeMode, AppLocalizations localizations) {
    switch (themeMode) {
      case ThemeMode.light:
        return localizations.light;
      case ThemeMode.dark:
        return localizations.dark;
      case ThemeMode.system:
        return localizations.system;
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
