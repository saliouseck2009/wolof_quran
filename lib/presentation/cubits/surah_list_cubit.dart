import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

// State classes
abstract class SurahListState {}

class SurahListInitial extends SurahListState {}

class SurahListLoaded extends SurahListState {
  final List<int> filteredSurahs;
  final bool isSearching;
  final String searchQuery;

  SurahListLoaded({
    required this.filteredSurahs,
    required this.isSearching,
    required this.searchQuery,
  });

  SurahListLoaded copyWith({
    List<int>? filteredSurahs,
    bool? isSearching,
    String? searchQuery,
  }) {
    return SurahListLoaded(
      filteredSurahs: filteredSurahs ?? this.filteredSurahs,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Cubit
class SurahListCubit extends Cubit<SurahListState> {
  SurahListCubit() : super(SurahListInitial());

  void initialize() {
    final allSurahs = List.generate(114, (index) => index + 1);
    emit(
      SurahListLoaded(
        filteredSurahs: allSurahs,
        isSearching: false,
        searchQuery: '',
      ),
    );
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
      final surahNumber = i.toString();

      if (surahName.contains(trimmedQuery) ||
          surahNameEn.contains(trimmedQuery) ||
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
}
