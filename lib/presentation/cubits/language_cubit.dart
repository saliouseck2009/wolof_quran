import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/localization/localization_service.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(LocalizationService.defaultLocale);

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
}
