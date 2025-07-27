import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/usecases/get_reciters_usecase.dart';
import '../../domain/repositories/reciter_repository.dart';
import '../../core/usecases/usecase.dart';

// States
abstract class ReciterState extends Equatable {
  const ReciterState();

  @override
  List<Object?> get props => [];
}

class ReciterInitial extends ReciterState {}

class ReciterLoading extends ReciterState {}

class ReciterLoaded extends ReciterState {
  final List<Reciter> reciters;
  final Reciter? selectedReciter;

  const ReciterLoaded({required this.reciters, this.selectedReciter});

  ReciterLoaded copyWith({List<Reciter>? reciters, Reciter? selectedReciter}) {
    return ReciterLoaded(
      reciters: reciters ?? this.reciters,
      selectedReciter: selectedReciter ?? this.selectedReciter,
    );
  }

  @override
  List<Object?> get props => [reciters, selectedReciter];
}

class ReciterError extends ReciterState {
  final String message;

  const ReciterError(this.message);

  @override
  List<Object> get props => [message];
}

// Events
abstract class ReciterEvent extends Equatable {
  const ReciterEvent();

  @override
  List<Object> get props => [];
}

class LoadReciters extends ReciterEvent {}

class SelectReciter extends ReciterEvent {
  final String reciterId;

  const SelectReciter(this.reciterId);

  @override
  List<Object> get props => [reciterId];
}

// Cubit
class ReciterCubit extends Cubit<ReciterState> {
  final GetRecitersUseCase getRecitersUseCase;
  final ReciterRepository reciterRepository;

  ReciterCubit({
    required this.getRecitersUseCase,
    required this.reciterRepository,
  }) : super(ReciterInitial());

  /// Load all available reciters and get the selected one
  Future<void> loadReciters() async {
    try {
      emit(ReciterLoading());

      final reciters = await getRecitersUseCase(params: const NoParams());
      final selectedReciter = await reciterRepository.getSelectedReciter();

      emit(ReciterLoaded(reciters: reciters, selectedReciter: selectedReciter));
    } catch (e) {
      emit(ReciterError('Failed to load reciters: ${e.toString()}'));
    }
  }

  /// Select a reciter
  Future<void> selectReciter(String reciterId) async {
    try {
      final currentState = state;
      if (currentState is ReciterLoaded) {
        await reciterRepository.setSelectedReciter(reciterId);

        final selectedReciter = currentState.reciters
            .where((reciter) => reciter.id == reciterId)
            .firstOrNull;

        emit(currentState.copyWith(selectedReciter: selectedReciter));
      }
    } catch (e) {
      emit(ReciterError('Failed to select reciter: ${e.toString()}'));
    }
  }

  /// Get the currently selected reciter
  Reciter? get selectedReciter {
    final currentState = state;
    if (currentState is ReciterLoaded) {
      return currentState.selectedReciter;
    }
    return null;
  }
}
