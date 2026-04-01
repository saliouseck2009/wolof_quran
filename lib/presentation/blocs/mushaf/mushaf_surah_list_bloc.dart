import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

sealed class MushafSurahListEvent extends Equatable {
  const MushafSurahListEvent();

  @override
  List<Object?> get props => [];
}

class MushafSurahListLoaded extends MushafSurahListEvent {
  const MushafSurahListLoaded();
}

class MushafSurahSearchChanged extends MushafSurahListEvent {
  final String query;

  const MushafSurahSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class MushafSurahListState extends Equatable {
  final List<MushafSurahItem> surahs;
  final List<MushafSurahItem> filteredSurahs;
  final String query;

  const MushafSurahListState({
    this.surahs = const [],
    this.filteredSurahs = const [],
    this.query = '',
  });

  MushafSurahListState copyWith({
    List<MushafSurahItem>? surahs,
    List<MushafSurahItem>? filteredSurahs,
    String? query,
  }) {
    return MushafSurahListState(
      surahs: surahs ?? this.surahs,
      filteredSurahs: filteredSurahs ?? this.filteredSurahs,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [surahs, filteredSurahs, query];
}

class MushafSurahItem extends Equatable {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final int verseCount;
  final String revelationType;

  const MushafSurahItem({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.verseCount,
    required this.revelationType,
  });

  @override
  List<Object?> get props => [
    number,
    nameArabic,
    nameEnglish,
    verseCount,
    revelationType,
  ];
}

class MushafSurahListBloc
    extends Bloc<MushafSurahListEvent, MushafSurahListState> {
  MushafSurahListBloc() : super(const MushafSurahListState()) {
    on<MushafSurahListLoaded>(_onLoaded);
    on<MushafSurahSearchChanged>(_onSearchChanged);
  }

  void _onLoaded(
    MushafSurahListLoaded event,
    Emitter<MushafSurahListState> emit,
  ) {
    final surahs = List.generate(quran.totalSurahCount, (index) {
      final surahNumber = index + 1;
      return MushafSurahItem(
        number: surahNumber,
        nameArabic: quran.getSurahNameArabic(surahNumber),
        nameEnglish: quran.getSurahNameEnglish(surahNumber),
        verseCount: quran.getVerseCount(surahNumber),
        revelationType: quran.getPlaceOfRevelation(surahNumber),
      );
    });

    emit(state.copyWith(surahs: surahs, filteredSurahs: surahs));
  }

  void _onSearchChanged(
    MushafSurahSearchChanged event,
    Emitter<MushafSurahListState> emit,
  ) {
    final query = event.query.toLowerCase().trim();
    if (query.isEmpty) {
      emit(state.copyWith(filteredSurahs: state.surahs, query: query));
      return;
    }

    final filtered = state.surahs.where((surah) {
      return surah.nameArabic.contains(query) ||
          surah.nameEnglish.toLowerCase().contains(query) ||
          surah.number.toString() == query;
    }).toList();

    emit(state.copyWith(filteredSurahs: filtered, query: query));
  }
}
