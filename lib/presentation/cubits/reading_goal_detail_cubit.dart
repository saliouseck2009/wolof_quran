import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/reading_validation.dart';
import '../../domain/repositories/reading_goal_repository.dart';
import 'reading_goals_cubit.dart';

class ReadingGoalDetailState extends Equatable {
  final bool isLoading;

  /// Journal of the goal, most recent first.
  final List<ReadingValidation> validations;

  const ReadingGoalDetailState({
    this.isLoading = true,
    this.validations = const [],
  });

  ReadingGoalDetailState copyWith({
    bool? isLoading,
    List<ReadingValidation>? validations,
  }) {
    return ReadingGoalDetailState(
      isLoading: isLoading ?? this.isLoading,
      validations: validations ?? this.validations,
    );
  }

  @override
  List<Object?> get props => [isLoading, validations];
}

/// Journal of one goal. Progress itself comes from [ReadingGoalsCubit];
/// this cubit reloads the journal whenever that goal changes.
class ReadingGoalDetailCubit extends Cubit<ReadingGoalDetailState> {
  final String goalId;
  final ReadingGoalRepository _repository;
  final ReadingGoalsCubit _goalsCubit;
  late final StreamSubscription<ReadingGoalsState> _subscription;

  ReadingGoalDetailCubit({
    required this.goalId,
    required ReadingGoalRepository repository,
    required ReadingGoalsCubit goalsCubit,
  }) : _repository = repository,
       _goalsCubit = goalsCubit,
       super(const ReadingGoalDetailState()) {
    var last = goalsCubit.state.progressOf(goalId);
    _subscription = goalsCubit.stream.listen((goalsState) {
      final progress = goalsState.progressOf(goalId);
      if (progress != last) {
        last = progress;
        load();
      }
    });
  }

  Future<void> load() async {
    try {
      final validations = await _repository.getValidations(goalId);
      emit(state.copyWith(isLoading: false, validations: validations));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> undo(String validationId) async {
    await _goalsCubit.undoValidation(validationId);
    await load();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
