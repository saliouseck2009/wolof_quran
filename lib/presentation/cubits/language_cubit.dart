import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/localization/localization_service.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(LocalizationService.defaultLocale) {
    _loadSavedLanguage();
  }

  /// Load saved language from SharedPreferences on initialization
  Future<void> _loadSavedLanguage() async {
    try {
      final savedLocale = await LocalizationService.getCurrentLocale();
      emit(savedLocale);
    } catch (e) {
      // If loading fails, keep the default locale
      emit(LocalizationService.defaultLocale);
    }
  }

  void changeLanguage(Locale newLocale) async {
    if (LocalizationService.isSupported(newLocale)) {
      await LocalizationService.setLocale(newLocale);
      emit(newLocale);
    }
  }

  void changeLanguageByCode(String languageCode) {
    final locale = LocalizationService.getLocaleFromLanguageCode(languageCode);
    changeLanguage(locale);
  }

  /// Manually load and set the saved language (useful for refresh)
  Future<void> loadSavedLanguage() async {
    await _loadSavedLanguage();
  }
}
