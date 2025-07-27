import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran/quran.dart' as quran;

// State classes
abstract class QuranSettingsState {}

class QuranSettingsInitial extends QuranSettingsState {}

class QuranSettingsLoaded extends QuranSettingsState {
  final quran.Translation selectedTranslation;

  QuranSettingsLoaded({required this.selectedTranslation});
}

// Available translations with their display names
class TranslationOption {
  final quran.Translation translation;
  final String displayName;
  final String language;

  const TranslationOption({
    required this.translation,
    required this.displayName,
    required this.language,
  });
}

// Cubit
class QuranSettingsCubit extends Cubit<QuranSettingsState> {
  static const String _translationKey = 'selected_quran_translation';

  QuranSettingsCubit() : super(QuranSettingsInitial());

  // Available translations based on the README
  static const List<TranslationOption> availableTranslations = [
    TranslationOption(
      translation: quran.Translation.frHamidullah,
      displayName: 'Français (Muhammad Hamidullah)',
      language: 'Français',
    ),
    TranslationOption(
      translation: quran.Translation.enSaheeh,
      displayName: 'English (Saheeh International)',
      language: 'English',
    ),
    TranslationOption(
      translation: quran.Translation.enClearQuran,
      displayName: 'English (Clear Quran)',
      language: 'English',
    ),
    TranslationOption(
      translation: quran.Translation.trSaheeh,
      displayName: 'Türkçe',
      language: 'Turkish',
    ),
    TranslationOption(
      translation: quran.Translation.mlAbdulHameed,
      displayName: 'മലയാളം (Malayalam)',
      language: 'Malayalam',
    ),
    TranslationOption(
      translation: quran.Translation.faHusseinDari,
      displayName: 'فارسی (Farsi)',
      language: 'Farsi',
    ),
    TranslationOption(
      translation: quran.Translation.portuguese,
      displayName: 'Português',
      language: 'Portuguese',
    ),
    TranslationOption(
      translation: quran.Translation.itPiccardo,
      displayName: 'Italiano',
      language: 'Italian',
    ),
    TranslationOption(
      translation: quran.Translation.nlSiregar,
      displayName: 'Nederlands',
      language: 'Dutch',
    ),
    TranslationOption(
      translation: quran.Translation.ruKuliev,
      displayName: 'Русский',
      language: 'Russian',
    ),
    TranslationOption(
      translation: quran.Translation.bengali,
      displayName: 'বাংলা (Bengali)',
      language: 'Bengali',
    ),
    TranslationOption(
      translation: quran.Translation.chinese,
      displayName: '中文 (Chinese)',
      language: 'Chinese',
    ),
    TranslationOption(
      translation: quran.Translation.spanish,
      displayName: 'Español',
      language: 'Spanish',
    ),
    TranslationOption(
      translation: quran.Translation.urdu,
      displayName: 'اردو (Urdu)',
      language: 'Urdu',
    ),
    TranslationOption(
      translation: quran.Translation.indonesian,
      displayName: 'Bahasa Indonesia',
      language: 'Indonesian',
    ),
  ];

  void loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final translationIndex = prefs.getInt(_translationKey);

      quran.Translation selectedTranslation;
      if (translationIndex != null &&
          translationIndex < availableTranslations.length) {
        selectedTranslation =
            availableTranslations[translationIndex].translation;
      } else {
        // Default to French for first-time users
        selectedTranslation = quran.Translation.frHamidullah;
      }

      emit(QuranSettingsLoaded(selectedTranslation: selectedTranslation));
    } catch (e) {
      // Fallback to French if there's an error
      emit(
        QuranSettingsLoaded(
          selectedTranslation: quran.Translation.frHamidullah,
        ),
      );
    }
  }

  void updateTranslation(quran.Translation translation) async {
    try {
      print('🔄 Updating translation to: $translation'); // Debug log

      final prefs = await SharedPreferences.getInstance();
      final index = availableTranslations.indexWhere(
        (option) => option.translation == translation,
      );

      print('📊 Translation index found: $index'); // Debug log

      if (index != -1) {
        await prefs.setInt(_translationKey, index);
        print(
          '💾 Saved translation index to SharedPreferences: $index',
        ); // Debug log

        emit(QuranSettingsLoaded(selectedTranslation: translation));
        print(
          '✅ Emitted new state with translation: $translation',
        ); // Debug log
      } else {
        print('❌ Translation not found in available translations'); // Debug log
      }
    } catch (e) {
      print('💥 Error updating translation: $e'); // Debug log
      // Handle error silently or emit error state if needed
    }
  }

  static TranslationOption? getTranslationOption(
    quran.Translation translation,
  ) {
    try {
      return availableTranslations.firstWhere(
        (option) => option.translation == translation,
      );
    } catch (e) {
      return null;
    }
  }

  // Static utility method to get Surah name in any translation
  static String getSurahNameInTranslation(
    int surahNumber,
    quran.Translation translation,
  ) {
    switch (translation) {
      case quran.Translation.frHamidullah:
        return quran.getSurahNameFrench(surahNumber);
      case quran.Translation.trSaheeh:
        return quran.getSurahNameTurkish(surahNumber);
      case quran.Translation.enSaheeh:
      case quran.Translation.enClearQuran:
      default:
        return quran.getSurahNameEnglish(surahNumber);
    }
  }

  // Static utility method to get currently selected translation from SharedPreferences
  static Future<quran.Translation> getCurrentTranslation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final translationIndex = prefs.getInt(_translationKey);

      if (translationIndex != null &&
          translationIndex < availableTranslations.length) {
        return availableTranslations[translationIndex].translation;
      } else {
        // Default to French for first-time users
        return quran.Translation.frHamidullah;
      }
    } catch (e) {
      // Fallback to French if there's an error
      return quran.Translation.frHamidullah;
    }
  }
}
