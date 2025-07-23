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
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode == null) {
      return defaultLocale;
    }

    return Locale(languageCode);
  }

  // Save selected locale to SharedPreferences
  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }

  // Check if locale is supported
  static bool isSupported(Locale locale) {
    return supportedLocales.contains(locale);
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
}
