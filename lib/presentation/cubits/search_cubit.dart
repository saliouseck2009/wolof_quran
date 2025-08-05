import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:quran/quran.dart' as quran;
import './quran_settings_cubit.dart';

// Search States
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<SearchResult> results;
  final int totalOccurrences;
  final String searchQuery;
  final String translationSource;

  const SearchLoaded({
    required this.results,
    required this.totalOccurrences,
    required this.searchQuery,
    required this.translationSource,
  });

  @override
  List<Object?> get props => [
    results,
    totalOccurrences,
    searchQuery,
    translationSource,
  ];
}

class SearchError extends SearchState {
  final String message;

  const SearchError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Search Result Model
class SearchResult extends Equatable {
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String translation;
  final String surahName;

  const SearchResult({
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    required this.translation,
    required this.surahName,
  });

  @override
  List<Object?> get props => [
    surahNumber,
    verseNumber,
    arabicText,
    translation,
    surahName,
  ];
}

// Search Cubit
class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  void searchWords(String query) async {
    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      final words = query
          .trim()
          .split(' ')
          .where((word) => word.isNotEmpty)
          .toList();

      // Get current translation from settings
      final currentTranslation =
          await QuranSettingsCubit.getCurrentTranslation();
      final translationOption = QuranSettingsCubit.getTranslationOption(
        currentTranslation,
      );
      final translationSource =
          translationOption?.language.toLowerCase() ?? 'french';

      List<SearchResult> results = [];
      int totalOccurrences = 0;

      // Search in translation using searchWordsInTranslation
      final searchResults = quran.searchWordsInTranslation(
        words,
        translation: currentTranslation,
      );

      if (searchResults.containsKey('result')) {
        final resultList = searchResults['result'] as List;
        totalOccurrences = searchResults['occurences'] as int? ?? 0;

        for (var result in resultList) {
          final surahNumber = result['surah'] as int;
          final verseNumber = result['verse'] as int;
          final arabicText = quran.getVerse(surahNumber, verseNumber);
          final surahName = quran.getSurahName(surahNumber);

          // Get translation for display
          String translation = '';
          try {
            translation = quran.getVerseTranslation(
              surahNumber,
              verseNumber,
              translation: currentTranslation,
            );
          } catch (e) {
            translation = ''; // Fallback to empty if translation fails
          }

          results.add(
            SearchResult(
              surahNumber: surahNumber,
              verseNumber: verseNumber,
              arabicText: arabicText,
              translation: translation,
              surahName: surahName,
            ),
          );
        }
      }

      emit(
        SearchLoaded(
          results: results,
          totalOccurrences: totalOccurrences,
          searchQuery: query,
          translationSource: translationSource,
        ),
      );
    } catch (e) {
      emit(SearchError(message: 'Failed to search: ${e.toString()}'));
    }
  }

  void clearSearch() {
    emit(SearchInitial());
  }
}
