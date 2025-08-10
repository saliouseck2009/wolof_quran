// Cubit for managing the Daily Inspiration state
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

class DailyInspirationCubit extends Cubit<DailyInspirationState> {
  DailyInspirationCubit() : super(DailyInspirationInitial());

  void generateRandomAyah(quran.Translation currentTranslation) {
    emit(DailyInspirationLoading());

    try {
      final random = Random();

      // Generate random surah (1-114)
      final surahNumber = random.nextInt(114) + 1;

      // Get verse count for the surah
      final verseCount = quran.getVerseCount(surahNumber);

      // Generate random verse (1 to verseCount)
      final verseNumber = random.nextInt(verseCount) + 1;

      // Get ayah data
      final arabicText = quran.getVerse(surahNumber, verseNumber);
      final surahName = quran.getSurahName(surahNumber);

      // Get translation based on current settings
      final translation = quran.getVerseTranslation(
        surahNumber,
        verseNumber,
        translation: currentTranslation,
      );

      emit(
        DailyInspirationLoaded(
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          arabicText: arabicText,
          translation: translation,
          surahName: surahName,
          currentTranslation: currentTranslation,
          isExpanded: false,
        ),
      );
    } catch (e) {
      emit(DailyInspirationError('Failed to load ayah: $e'));
    }
  }

  void toggleExpansion() {
    final currentState = state;
    if (currentState is DailyInspirationLoaded) {
      emit(currentState.copyWith(isExpanded: !currentState.isExpanded));
    }
  }

  void refreshAyah(quran.Translation currentTranslation) {
    generateRandomAyah(currentTranslation);
  }
}

// States for Daily Inspiration
abstract class DailyInspirationState {}

class DailyInspirationInitial extends DailyInspirationState {}

class DailyInspirationLoading extends DailyInspirationState {}

class DailyInspirationLoaded extends DailyInspirationState {
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String translation;
  final String surahName;
  final quran.Translation currentTranslation;
  final bool isExpanded;

  DailyInspirationLoaded({
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    required this.translation,
    required this.surahName,
    required this.currentTranslation,
    required this.isExpanded,
  });

  DailyInspirationLoaded copyWith({
    int? surahNumber,
    int? verseNumber,
    String? arabicText,
    String? translation,
    String? surahName,
    quran.Translation? currentTranslation,
    bool? isExpanded,
  }) {
    return DailyInspirationLoaded(
      surahNumber: surahNumber ?? this.surahNumber,
      verseNumber: verseNumber ?? this.verseNumber,
      arabicText: arabicText ?? this.arabicText,
      translation: translation ?? this.translation,
      surahName: surahName ?? this.surahName,
      currentTranslation: currentTranslation ?? this.currentTranslation,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class DailyInspirationError extends DailyInspirationState {
  final String message;
  DailyInspirationError(this.message);
}
