import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran/quran.dart' as quran;
import '../../domain/entities/reciter.dart';

// State classes
abstract class QuranSettingsState {}

class QuranSettingsInitial extends QuranSettingsState {}

class QuranSettingsLoaded extends QuranSettingsState {
  final quran.Translation selectedTranslation;
  final Reciter? selectedReciter;

  QuranSettingsLoaded({
    required this.selectedTranslation,
    this.selectedReciter,
  });

  QuranSettingsLoaded copyWith({
    quran.Translation? selectedTranslation,
    Reciter? selectedReciter,
  }) {
    return QuranSettingsLoaded(
      selectedTranslation: selectedTranslation ?? this.selectedTranslation,
      selectedReciter: selectedReciter ?? this.selectedReciter,
    );
  }
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
  static const String _reciterKey = 'selected_reciter_id';

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

      // We'll emit without reciter first, then update when reciter is loaded
      emit(
        QuranSettingsLoaded(
          selectedTranslation: selectedTranslation,
          selectedReciter: null,
        ),
      );

      // If we have a saved reciter ID, we'll need to load it from ReciterCubit
      // This will be handled by the UI when ReciterCubit loads
    } catch (e) {
      // Fallback to French if there's an error
      emit(
        QuranSettingsLoaded(
          selectedTranslation: quran.Translation.frHamidullah,
        ),
      );
    }
  }

  void updateReciter(Reciter reciter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reciterKey, reciter.id);

      final currentState = state;
      if (currentState is QuranSettingsLoaded) {
        emit(currentState.copyWith(selectedReciter: reciter));
      }
    } catch (e) {
      // Handle error silently or emit error state if needed
    }
  }

  void loadReciterFromPrefs(List<Reciter> availableReciters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedReciterId = prefs.getString(_reciterKey);

      if (selectedReciterId != null) {
        final selectedReciter = availableReciters.firstWhere(
          (reciter) => reciter.id == selectedReciterId,
          orElse: () => availableReciters.isNotEmpty
              ? availableReciters.first
              : throw Exception('No reciters available'),
        );

        final currentState = state;
        if (currentState is QuranSettingsLoaded) {
          emit(currentState.copyWith(selectedReciter: selectedReciter));
        }
      } else if (availableReciters.isNotEmpty) {
        // Set imamsarr as default if available, otherwise first reciter
        final defaultReciter = availableReciters.firstWhere(
          (reciter) => reciter.id == 'imamsarr',
          orElse: () => availableReciters.first,
        );
        updateReciter(defaultReciter);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void updateTranslation(quran.Translation translation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = availableTranslations.indexWhere(
        (option) => option.translation == translation,
      );
      if (index != -1) {
        await prefs.setInt(_translationKey, index);

        final currentState = state;
        if (currentState is QuranSettingsLoaded) {
          emit(currentState.copyWith(selectedTranslation: translation));
        } else {
          emit(QuranSettingsLoaded(selectedTranslation: translation));
        }
      }
    } catch (e) {
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

  // Static utility method to get currently selected reciter ID from SharedPreferences
  static Future<String?> getSelectedReciterId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_reciterKey);
    } catch (e) {
      return null;
    }
  }
}
