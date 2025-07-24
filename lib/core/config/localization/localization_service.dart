import 'package:flutter/material.dart';

class LocalizationService {
  static const String _languageKey = 'app_language';

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'), // French (default)
    Locale('en', 'US'), // English
    Locale('ar', 'SA'), // Arabic
  ];

  static const Locale defaultLocale = Locale('fr', 'FR');

  // Get current locale (synchronous for simplicity)
  static Locale getCurrentLocale() {
    // In a real app, you'd load this from SharedPreferences
    // For now, return the default locale
    return defaultLocale;
  }

  // Save selected locale (async but simplified)
  static Future<void> setLocale(Locale locale) async {
    // In a real app, you'd save this to SharedPreferences
    // For now, we'll implement this when SharedPreferences is working
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
}
