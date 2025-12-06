import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/downloaded_surah.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/usecases/get_downloaded_surahs_usecase.dart';

// States
abstract class ReciterChaptersState extends Equatable {
  const ReciterChaptersState();

  @override
  List<Object?> get props => [];
}

class ReciterChaptersInitial extends ReciterChaptersState {}

class ReciterChaptersLoading extends ReciterChaptersState {}

class ReciterChaptersLoaded extends ReciterChaptersState {
  final Reciter reciter;
  final Set<int> downloadedSurahNumbers;
  final Map<int, DownloadedSurah> downloadedSurahs;

  const ReciterChaptersLoaded({
    required this.reciter,
    required this.downloadedSurahNumbers,
    required this.downloadedSurahs,
  });

  @override
  List<Object?> get props => [
    reciter,
    downloadedSurahNumbers,
    downloadedSurahs,
  ];

  bool isSurahDownloaded(int surahNumber) {
    return downloadedSurahNumbers.contains(surahNumber);
  }

  DownloadedSurah? getDownloadedSurah(int surahNumber) {
    return downloadedSurahs[surahNumber];
  }

  ReciterChaptersLoaded copyWith({
    Reciter? reciter,
    Set<int>? downloadedSurahNumbers,
    Map<int, DownloadedSurah>? downloadedSurahs,
  }) {
    return ReciterChaptersLoaded(
      reciter: reciter ?? this.reciter,
      downloadedSurahNumbers:
          downloadedSurahNumbers ?? this.downloadedSurahNumbers,
      downloadedSurahs: downloadedSurahs ?? this.downloadedSurahs,
    );
  }
}

class ReciterChaptersError extends ReciterChaptersState {
  final String message;

  const ReciterChaptersError(this.message);

  @override
  List<Object?> get props => [message];
}

// Events
abstract class ReciterChaptersEvent extends Equatable {
  const ReciterChaptersEvent();

  @override
  List<Object?> get props => [];
}

class LoadReciterChapters extends ReciterChaptersEvent {
  final Reciter reciter;

  const LoadReciterChapters(this.reciter);

  @override
  List<Object?> get props => [reciter];
}

class RefreshDownloadedSurahs extends ReciterChaptersEvent {
  final String reciterId;

  const RefreshDownloadedSurahs(this.reciterId);

  @override
  List<Object?> get props => [reciterId];
}

class SurahDownloadCompleted extends ReciterChaptersEvent {
  final int surahNumber;
  final String filePath;

  const SurahDownloadCompleted(this.surahNumber, this.filePath);

  @override
  List<Object?> get props => [surahNumber, filePath];
}

class SurahDownloadRemoved extends ReciterChaptersEvent {
  final int surahNumber;

  const SurahDownloadRemoved(this.surahNumber);

  @override
  List<Object?> get props => [surahNumber];
}

// Bloc
class ReciterChaptersBloc
    extends Bloc<ReciterChaptersEvent, ReciterChaptersState> {
  final GetDownloadedSurahsUseCase getDownloadedSurahsUseCase;

  ReciterChaptersBloc({required this.getDownloadedSurahsUseCase})
    : super(ReciterChaptersInitial()) {
    on<LoadReciterChapters>(_onLoadReciterChapters);
    on<RefreshDownloadedSurahs>(_onRefreshDownloadedSurahs);
    on<SurahDownloadCompleted>(_onSurahDownloadCompleted);
    on<SurahDownloadRemoved>(_onSurahDownloadRemoved);
  }

  Future<void> _onLoadReciterChapters(
    LoadReciterChapters event,
    Emitter<ReciterChaptersState> emit,
  ) async {
    emit(ReciterChaptersLoading());
    try {
      final downloadedSurahs = await getDownloadedSurahsUseCase.call(
        params: event.reciter.id,
      );

      final downloadedSurahNumbers = downloadedSurahs
          .where((surah) => surah.isComplete)
          .map((surah) => surah.surahNumber)
          .toSet();

      final downloadedSurahsMap = {
        for (var surah in downloadedSurahs) surah.surahNumber: surah,
      };

      emit(
        ReciterChaptersLoaded(
          reciter: event.reciter,
          downloadedSurahNumbers: downloadedSurahNumbers,
          downloadedSurahs: downloadedSurahsMap,
        ),
      );
    } catch (e) {
      emit(ReciterChaptersError('Failed to load chapters: $e'));
    }
  }

  Future<void> _onRefreshDownloadedSurahs(
    RefreshDownloadedSurahs event,
    Emitter<ReciterChaptersState> emit,
  ) async {
    final currentState = state;
    if (currentState is ReciterChaptersLoaded) {
      try {
        final downloadedSurahs = await getDownloadedSurahsUseCase.call(
          params: event.reciterId,
        );

        final downloadedSurahNumbers = downloadedSurahs
            .where((surah) => surah.isComplete)
            .map((surah) => surah.surahNumber)
            .toSet();

        final downloadedSurahsMap = {
          for (var surah in downloadedSurahs) surah.surahNumber: surah,
        };

        emit(
          currentState.copyWith(
            downloadedSurahNumbers: downloadedSurahNumbers,
            downloadedSurahs: downloadedSurahsMap,
          ),
        );
      } catch (e) {
        // If refresh fails, keep current state but maybe log the error
        log('Failed to refresh downloaded surahs: $e');
      }
    }
  }

  Future<void> _onSurahDownloadCompleted(
    SurahDownloadCompleted event,
    Emitter<ReciterChaptersState> emit,
  ) async {
    final currentState = state;
    if (currentState is ReciterChaptersLoaded) {
      final updatedDownloadedNumbers = Set<int>.from(
        currentState.downloadedSurahNumbers,
      )..add(event.surahNumber);

      final updatedDownloadedSurahs = Map<int, DownloadedSurah>.from(
        currentState.downloadedSurahs,
      );
      updatedDownloadedSurahs[event.surahNumber] = DownloadedSurah(
        id: null,
        reciterId: currentState.reciter.id,
        surahNumber: event.surahNumber,
        filePath: event.filePath,
        isComplete: true,
      );

      emit(
        currentState.copyWith(
          downloadedSurahNumbers: updatedDownloadedNumbers,
          downloadedSurahs: updatedDownloadedSurahs,
        ),
      );
    }
  }

  Future<void> _onSurahDownloadRemoved(
    SurahDownloadRemoved event,
    Emitter<ReciterChaptersState> emit,
  ) async {
    final currentState = state;
    if (currentState is ReciterChaptersLoaded) {
      final updatedDownloadedNumbers = Set<int>.from(
        currentState.downloadedSurahNumbers,
      )..remove(event.surahNumber);

      final updatedDownloadedSurahs = Map<int, DownloadedSurah>.from(
        currentState.downloadedSurahs,
      )..remove(event.surahNumber);

      emit(
        currentState.copyWith(
          downloadedSurahNumbers: updatedDownloadedNumbers,
          downloadedSurahs: updatedDownloadedSurahs,
        ),
      );
    }
  }
}
