import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_settings_cubit.dart';

// State classes
abstract class SurahListState {}

class SurahListInitial extends SurahListState {}

class SurahListLoaded extends SurahListState {
  final List<int> filteredSurahs;
  final bool isSearching;
  final String searchQuery;
  final quran.Translation selectedTranslation;

  SurahListLoaded({
    required this.filteredSurahs,
    required this.isSearching,
    required this.searchQuery,
    required this.selectedTranslation,
  });

  SurahListLoaded copyWith({
    List<int>? filteredSurahs,
    bool? isSearching,
    String? searchQuery,
    quran.Translation? selectedTranslation,
  }) {
    return SurahListLoaded(
      filteredSurahs: filteredSurahs ?? this.filteredSurahs,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTranslation: selectedTranslation ?? this.selectedTranslation,
    );
  }
}

// Cubit
class SurahListCubit extends Cubit<SurahListState> {
  SurahListCubit() : super(SurahListInitial());

  void initialize() async {
    try {
      // Load selected translation from SharedPreferences
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

      final allSurahs = List.generate(114, (index) => index + 1);
      emit(
        SurahListLoaded(
          filteredSurahs: allSurahs,
          isSearching: false,
          searchQuery: '',
          selectedTranslation: selectedTranslation,
        ),
      );
    } catch (e) {
      // Fallback with default translation
      final allSurahs = List.generate(114, (index) => index + 1);
      emit(
        SurahListLoaded(
          filteredSurahs: allSurahs,
          isSearching: false,
          searchQuery: '',
          selectedTranslation: quran.Translation.frHamidullah,
        ),
      );
    }
  }

  void searchSurahs(String query) {
    final currentState = state;
    if (currentState is! SurahListLoaded) return;

    final trimmedQuery = query.toLowerCase().trim();

    if (trimmedQuery.isEmpty) {
      final allSurahs = List.generate(114, (index) => index + 1);
      emit(
        currentState.copyWith(
          filteredSurahs: allSurahs,
          isSearching: false,
          searchQuery: '',
        ),
      );
      return;
    }

    final filteredSurahs = <int>[];

    for (int i = 1; i <= 114; i++) {
      final surahName = quran.getSurahName(i).toLowerCase();
      final surahNameEn = quran.getSurahNameEnglish(i).toLowerCase();
      final surahNameTranslated = QuranSettingsCubit.getSurahNameInTranslation(
        i,
        currentState.selectedTranslation,
      ).toLowerCase();
      final surahNumber = i.toString();

      if (surahName.contains(trimmedQuery) ||
          surahNameEn.contains(trimmedQuery) ||
          surahNameTranslated.contains(trimmedQuery) ||
          surahNumber.contains(trimmedQuery)) {
        filteredSurahs.add(i);
      }
    }

    emit(
      currentState.copyWith(
        filteredSurahs: filteredSurahs,
        isSearching: true,
        searchQuery: trimmedQuery,
      ),
    );
  }

  void clearSearch() {
    final allSurahs = List.generate(114, (index) => index + 1);
    final currentState = state;
    if (currentState is SurahListLoaded) {
      emit(
        currentState.copyWith(
          filteredSurahs: allSurahs,
          isSearching: false,
          searchQuery: '',
        ),
      );
    }
  }

  // Method to reload translation settings
  void reloadTranslationSettings() {
    initialize(); // Reload the translation from SharedPreferences
  }
}
