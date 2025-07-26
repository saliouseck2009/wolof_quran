import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

// State classes
abstract class SurahDetailState {}

class SurahDetailInitial extends SurahDetailState {}

class SurahDetailLoading extends SurahDetailState {}

class SurahDetailLoaded extends SurahDetailState {
  final int surahNumber;
  final String surahNameArabic;
  final String surahNameEnglish;
  final int versesCount;
  final List<AyahData> ayahs;

  SurahDetailLoaded({
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.versesCount,
    required this.ayahs,
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

      // Get Surah information
      final surahNameArabic = quran.getSurahNameArabic(surahNumber);
      final surahNameEnglish = quran.getSurahNameEnglish(surahNumber);
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
          translation: quran.Translation.enSaheeh,
        );

        ayahs.add(
          AyahData(
            verseNumber: i,
            arabicText: arabicText,
            translation: translation,
          ),
        );
      }

      emit(
        SurahDetailLoaded(
          surahNumber: surahNumber,
          surahNameArabic: surahNameArabic,
          surahNameEnglish: surahNameEnglish,
          versesCount: versesCount,
          ayahs: ayahs,
        ),
      );
    } catch (e) {
      emit(SurahDetailError('Failed to load Surah: ${e.toString()}'));
    }
  }
}
