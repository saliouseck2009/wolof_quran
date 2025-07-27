import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_settings_cubit.dart';

// State classes
abstract class SurahDetailState {}

class SurahDetailInitial extends SurahDetailState {}

class SurahDetailLoading extends SurahDetailState {}

class SurahDetailLoaded extends SurahDetailState {
  final int surahNumber;
  final String surahNameArabic;
  final String surahNameEnglish;
  final String surahNameTranslated;
  final int versesCount;
  final List<AyahData> ayahs;
  final String translationSource;

  SurahDetailLoaded({
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.surahNameTranslated,
    required this.versesCount,
    required this.ayahs,
    required this.translationSource,
  });
}

class SurahDetailError extends SurahDetailState {
  final String message;

  SurahDetailError(this.message);
}

// Data class for Ayah
class AyahData {
  final int verseNumber;
  final String arabicText;
  final String translation;

  AyahData({
    required this.verseNumber,
    required this.arabicText,
    required this.translation,
  });
}

// Cubit
class SurahDetailCubit extends Cubit<SurahDetailState> {
  SurahDetailCubit() : super(SurahDetailInitial());

  void loadSurah(int surahNumber) async {
    try {
      emit(SurahDetailLoading());

      // Get selected translation from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final translationIndex = prefs.getInt('selected_quran_translation');

      quran.Translation selectedTranslation;
      if (translationIndex != null &&
          translationIndex < QuranSettingsCubit.availableTranslations.length) {
        selectedTranslation = QuranSettingsCubit
            .availableTranslations[translationIndex]
            .translation;
      } else {
        // Default to French for first-time users
        selectedTranslation = quran.Translation.frHamidullah;
      }

      // Get Surah information
      final surahNameArabic = quran.getSurahNameArabic(surahNumber);
      final surahNameEnglish = quran.getSurahNameEnglish(surahNumber);
      final surahNameTranslated = QuranSettingsCubit.getSurahNameInTranslation(
        surahNumber,
        selectedTranslation,
      );
      final versesCount = quran.getVerseCount(surahNumber);

      // Load all verses
      final List<AyahData> ayahs = [];

      for (int i = 1; i <= versesCount; i++) {
        final arabicText = quran.getVerse(
          surahNumber,
          i,
          verseEndSymbol: false,
        );
        final translation = quran.getVerseTranslation(
          surahNumber,
          i,
          translation: selectedTranslation,
        );

        ayahs.add(
          AyahData(
            verseNumber: i,
            arabicText: arabicText,
            translation: translation,
          ),
        );
      }

      // Get translation option for display name
      final translationOption = QuranSettingsCubit.getTranslationOption(
        selectedTranslation,
      );
      final translationSource =
          translationOption?.displayName ?? 'Unknown Translation';

      emit(
        SurahDetailLoaded(
          surahNumber: surahNumber,
          surahNameArabic: surahNameArabic,
          surahNameEnglish: surahNameEnglish,
          surahNameTranslated: surahNameTranslated,
          versesCount: versesCount,
          ayahs: ayahs,
          translationSource: translationSource,
        ),
      );
    } catch (e) {
      emit(SurahDetailError('Failed to load Surah: ${e.toString()}'));
    }
  }
}
