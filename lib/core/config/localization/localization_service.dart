import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageKey = 'app_language';

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'), // French (default)
    Locale('en', 'US'), // English
    Locale('ar', 'SA'), // Arabic
  ];

  static const Locale defaultLocale = Locale('fr', 'FR');

  // Get current locale from SharedPreferences
  static Future<Locale> getCurrentLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);

      if (languageCode != null) {
        final locale = getLocaleFromLanguageCode(languageCode);
        // Verify the locale is still supported
        if (isSupported(locale)) {
          return locale;
        }
      }
    } catch (e) {
      // If loading fails, return default
      debugPrint('Failed to load saved language: $e');
    }

    // Return default locale if no saved language or loading fails
    return defaultLocale;
  }

  // Save selected locale to SharedPreferences
  static Future<void> setLocale(Locale locale) async {
    try {
      if (isSupported(locale)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, locale.languageCode);
      }
    } catch (e) {
      debugPrint('Failed to save language preference: $e');
    }
  }

  // Get current locale synchronously (for backwards compatibility)
  // This should be avoided in favor of the async version
  static Locale getCurrentLocalSync() {
    // Return default locale for synchronous access
    // The async version should be used instead
    return defaultLocale;
  }

  // Check if locale is supported
  static bool isSupported(Locale locale) {
    return supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  // Get locale from language code
  static Locale getLocaleFromLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return const Locale('fr', 'FR');
      case 'en':
        return const Locale('en', 'US');
      case 'ar':
        return const Locale('ar', 'SA');
      default:
        return defaultLocale;
    }
  }

  // Get language name from locale
  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'Français';
    }
  }

  // Get saved language code directly from SharedPreferences
  static Future<String?> getSavedLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey);
    } catch (e) {
      debugPrint('Failed to get saved language code: $e');
      return null;
    }
  }

  // Clear saved language preference
  static Future<void> clearSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
    } catch (e) {
      debugPrint('Failed to clear saved language: $e');
    }
  }
}
