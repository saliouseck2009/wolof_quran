import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecases/get_downloaded_surahs_usecase.dart';

// States
abstract class SurahDownloadStatusState extends Equatable {
  const SurahDownloadStatusState();

  @override
  List<Object?> get props => [];
}

class SurahDownloadStatusInitial extends SurahDownloadStatusState {}

class SurahDownloadStatusLoading extends SurahDownloadStatusState {}

class SurahDownloadStatusLoaded extends SurahDownloadStatusState {
  final bool isDownloaded;
  final String reciterId;
  final int surahNumber;

  const SurahDownloadStatusLoaded({
    required this.isDownloaded,
    required this.reciterId,
    required this.surahNumber,
  });

  @override
  List<Object?> get props => [isDownloaded, reciterId, surahNumber];
}

class SurahDownloadStatusError extends SurahDownloadStatusState {
  final String message;

  const SurahDownloadStatusError(this.message);

  @override
  List<Object?> get props => [message];
}

// Events
abstract class SurahDownloadStatusEvent extends Equatable {
  const SurahDownloadStatusEvent();

  @override
  List<Object?> get props => [];
}

class CheckSurahDownloadStatus extends SurahDownloadStatusEvent {
  final String reciterId;
  final int surahNumber;

  const CheckSurahDownloadStatus({
    required this.reciterId,
    required this.surahNumber,
  });

  @override
  List<Object?> get props => [reciterId, surahNumber];
}

class RefreshSurahDownloadStatus extends SurahDownloadStatusEvent {
  final String reciterId;
  final int surahNumber;

  const RefreshSurahDownloadStatus({
    required this.reciterId,
    required this.surahNumber,
  });

  @override
  List<Object?> get props => [reciterId, surahNumber];
}

class SurahDownloadCompleted extends SurahDownloadStatusEvent {
  final String reciterId;
  final int surahNumber;

  const SurahDownloadCompleted({
    required this.reciterId,
    required this.surahNumber,
  });

  @override
  List<Object?> get props => [reciterId, surahNumber];
}

// Bloc
class SurahDownloadStatusBloc
    extends Bloc<SurahDownloadStatusEvent, SurahDownloadStatusState> {
  final GetDownloadedSurahsUseCase getDownloadedSurahsUseCase;

  SurahDownloadStatusBloc({required this.getDownloadedSurahsUseCase})
    : super(SurahDownloadStatusInitial()) {
    on<CheckSurahDownloadStatus>(_onCheckSurahDownloadStatus);
    on<RefreshSurahDownloadStatus>(_onRefreshSurahDownloadStatus);
    on<SurahDownloadCompleted>(_onSurahDownloadCompleted);
  }

  Future<void> _onCheckSurahDownloadStatus(
    CheckSurahDownloadStatus event,
    Emitter<SurahDownloadStatusState> emit,
  ) async {
    emit(SurahDownloadStatusLoading());
    try {
      final downloadedSurahs = await getDownloadedSurahsUseCase.call(
        params: event.reciterId,
      );

      final isDownloaded = downloadedSurahs.any(
        (surah) => surah.surahNumber == event.surahNumber && surah.isComplete,
      );

      emit(
        SurahDownloadStatusLoaded(
          isDownloaded: isDownloaded,
          reciterId: event.reciterId,
          surahNumber: event.surahNumber,
        ),
      );
    } catch (e) {
      emit(SurahDownloadStatusError('Failed to check download status: $e'));
    }
  }

  Future<void> _onRefreshSurahDownloadStatus(
    RefreshSurahDownloadStatus event,
    Emitter<SurahDownloadStatusState> emit,
  ) async {
    // Don't emit loading state for refresh to avoid UI flicker
    try {
      final downloadedSurahs = await getDownloadedSurahsUseCase.call(
        params: event.reciterId,
      );

      final isDownloaded = downloadedSurahs.any(
        (surah) => surah.surahNumber == event.surahNumber && surah.isComplete,
      );

      emit(
        SurahDownloadStatusLoaded(
          isDownloaded: isDownloaded,
          reciterId: event.reciterId,
          surahNumber: event.surahNumber,
        ),
      );
    } catch (e) {
      emit(SurahDownloadStatusError('Failed to refresh download status: $e'));
    }
  }

  Future<void> _onSurahDownloadCompleted(
    SurahDownloadCompleted event,
    Emitter<SurahDownloadStatusState> emit,
  ) async {
    final currentState = state;
    if (currentState is SurahDownloadStatusLoaded &&
        currentState.reciterId == event.reciterId &&
        currentState.surahNumber == event.surahNumber) {
      emit(
        SurahDownloadStatusLoaded(
          isDownloaded: true,
          reciterId: event.reciterId,
          surahNumber: event.surahNumber,
        ),
      );
    }
  }
}
