import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/mushaf/mushaf_theme.dart';
import '../../../core/mushaf/quran_page_data.dart';
import '../../../data/repositories/mushaf_repository.dart';
import 'mushaf_event.dart';
import 'mushaf_state.dart';

class MushafBloc extends Bloc<MushafEvent, MushafState> {
  final MushafRepository _repository;

  MushafBloc(this._repository) : super(MushafState()) {
    on<MushafLoaded>(_onLoaded);
    on<MushafPageChanged>(_onPageChanged);
    on<MushafNavigateToSurah>(_onNavigateToSurah);
    on<MushafThemeChanged>(_onThemeChanged);
  }

  Future<void> _onLoaded(MushafLoaded event, Emitter<MushafState> emit) async {
    final lastPage = await _repository.getLastReadPage();
    final themeIndex = await _repository.getThemeIndex();

    emit(
      state.copyWith(
        currentPage: lastPage,
        pageInfo: getPageInfo(lastPage),
        isLoading: false,
        theme: MushafThemeData.fromIndex(themeIndex),
      ),
    );
  }

  Future<void> _onPageChanged(
    MushafPageChanged event,
    Emitter<MushafState> emit,
  ) async {
    await _repository.saveLastReadPage(event.page);
    emit(
      state.copyWith(
        currentPage: event.page,
        pageInfo: getPageInfo(event.page),
        navigateToPage: () => null,
      ),
    );
  }

  Future<void> _onNavigateToSurah(
    MushafNavigateToSurah event,
    Emitter<MushafState> emit,
  ) async {
    final page = getFirstPageOfSurah(event.surahNumber);
    await _repository.saveLastReadPage(page);
    emit(
      state.copyWith(
        currentPage: page,
        pageInfo: getPageInfo(page),
        navigateToPage: () => page,
      ),
    );
  }

  Future<void> _onThemeChanged(
    MushafThemeChanged event,
    Emitter<MushafState> emit,
  ) async {
    await _repository.saveThemeIndex(event.themeIndex);
    emit(state.copyWith(theme: MushafThemeData.fromIndex(event.themeIndex)));
  }
}
