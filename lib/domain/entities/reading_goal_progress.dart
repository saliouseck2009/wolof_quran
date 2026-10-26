import 'package:equatable/equatable.dart';

import '../../core/reading/local_date.dart';
import '../../core/reading/reading_plan_calculator.dart';
import 'reading_goal.dart';

/// A goal together with its validated pages and the figures for [today].
class ReadingGoalProgress extends Equatable {
  final ReadingGoal goal;

  /// Validated page → when it was validated.
  final Map<int, DateTime> validatedAt;
  final LocalDate today;
  final ReadingPlanMetrics metrics;

  ReadingGoalProgress({
    required this.goal,
    required this.validatedAt,
    required this.today,
  }) : metrics = ReadingPlanCalculator.compute(
         order: goal.order,
         validatedAt: validatedAt,
         startDate: goal.startDate,
         endDate: goal.endDate,
         today: today,
       );

  Set<int> get validatedPages => validatedAt.keys.toSet();

  ReadingGoalPhase get phase => goal.phase(today);

  bool isValidated(int page) => validatedAt.containsKey(page);

  /// Page to open when resuming this goal: the first page not yet read, or
  /// the start page once everything is read.
  int get resumePage => metrics.firstUnvalidatedPage ?? goal.startPage;

  @override
  List<Object?> get props => [goal, validatedAt, today];
}
