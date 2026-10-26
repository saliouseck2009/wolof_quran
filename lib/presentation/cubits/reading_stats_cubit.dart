import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/reading/local_date.dart';
import '../../core/reading/reading_stats_calculator.dart';
import '../../domain/repositories/reading_goal_repository.dart';

class ReadingStatsState extends Equatable {
  final bool isLoading;
  final ReadingStats? stats;
  final LocalDate today;

  const ReadingStatsState({
    this.isLoading = true,
    this.stats,
    required this.today,
  });

  ReadingStatsState copyWith({bool? isLoading, ReadingStats? stats}) {
    return ReadingStatsState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      today: today,
    );
  }

  @override
  List<Object?> get props => [isLoading, stats, today];
}

/// Cross-goal figures for the performance page.
class ReadingStatsCubit extends Cubit<ReadingStatsState> {
  final ReadingGoalRepository _repository;
  final LocalDate Function() _today;

  ReadingStatsCubit({
    required ReadingGoalRepository repository,
    LocalDate Function()? today,
  }) : _repository = repository,
       _today = today ?? LocalDate.today,
       super(ReadingStatsState(today: (today ?? LocalDate.today)()));

  Future<void> load() async {
    try {
      final goals = await _repository.getGoals();
      final validatedByGoal = await _repository.getAllValidatedPages();
      final sessions = await _repository.getAllSessions();
      emit(
        state.copyWith(
          isLoading: false,
          stats: ReadingStatsCalculator.compute(
            goals: goals,
            validatedByGoal: validatedByGoal,
            sessions: sessions,
            today: _today(),
          ),
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }
}
