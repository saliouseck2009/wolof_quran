import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../domain/entities/reading_goal.dart';
import '../../domain/entities/reading_session.dart';
import 'local_date.dart';

/// Pages validated in one goal, for the per-goal breakdown.
class GoalPagesStat extends Equatable {
  final ReadingGoal goal;
  final int validatedCount;

  const GoalPagesStat({required this.goal, required this.validatedCount});

  double get fraction =>
      goal.totalPages == 0 ? 0 : validatedCount / goal.totalPages;

  @override
  List<Object?> get props => [goal, validatedCount];
}

/// Figures shown on the performance page, across every goal.
class ReadingStats extends Equatable {
  /// Pages validated across all goals; a page read in two goals counts in
  /// each.
  final int totalPagesValidated;
  final int completedKhatmCount;

  /// Consecutive days with at least one validated page, ending today or
  /// yesterday.
  final int currentStreak;
  final int bestStreak;
  final double averagePerDayLast30;
  final LocalDate? bestDay;
  final int bestDayPages;
  final Duration activeReadingTime;

  /// Pages validated per local day, all goals summed.
  final Map<LocalDate, int> pagesPerDay;
  final List<GoalPagesStat> perGoal;
  final List<ReadingGoal> completedGoals;

  const ReadingStats({
    required this.totalPagesValidated,
    required this.completedKhatmCount,
    required this.currentStreak,
    required this.bestStreak,
    required this.averagePerDayLast30,
    required this.bestDay,
    required this.bestDayPages,
    required this.activeReadingTime,
    required this.pagesPerDay,
    required this.perGoal,
    required this.completedGoals,
  });

  bool get isEmpty => totalPagesValidated == 0;

  /// Pages per day for the last [days] days ending [today], oldest first,
  /// with zeros for silent days.
  List<(LocalDate, int)> lastDays(LocalDate today, int days) {
    return [
      for (var i = days - 1; i >= 0; i--)
        (today.addDays(-i), pagesPerDay[today.addDays(-i)] ?? 0),
    ];
  }

  @override
  List<Object?> get props => [
    totalPagesValidated,
    completedKhatmCount,
    currentStreak,
    bestStreak,
    averagePerDayLast30,
    bestDay,
    bestDayPages,
    activeReadingTime,
    pagesPerDay,
    perGoal,
    completedGoals,
  ];
}

class ReadingStatsCalculator {
  const ReadingStatsCalculator._();

  static ReadingStats compute({
    required List<ReadingGoal> goals,
    required Map<String, Map<int, DateTime>> validatedByGoal,
    required List<ReadingSession> sessions,
    required LocalDate today,
  }) {
    final pagesPerDay = <LocalDate, int>{};
    var total = 0;
    final perGoal = <GoalPagesStat>[];
    for (final goal in goals) {
      final validated = validatedByGoal[goal.id] ?? const {};
      total += validated.length;
      perGoal.add(GoalPagesStat(goal: goal, validatedCount: validated.length));
      for (final timestamp in validated.values) {
        final day = LocalDate.fromDateTime(timestamp);
        pagesPerDay[day] = (pagesPerDay[day] ?? 0) + 1;
      }
    }
    perGoal.sort((a, b) => b.validatedCount.compareTo(a.validatedCount));

    final completedGoals =
        goals
            .where((goal) => goal.status == ReadingGoalStatus.completed)
            .toList()
          ..sort((a, b) {
            final aDate = a.completedAt ?? a.updatedAt;
            final bDate = b.completedAt ?? b.updatedAt;
            return bDate.compareTo(aDate);
          });

    LocalDate? bestDay;
    var bestDayPages = 0;
    for (final entry in pagesPerDay.entries) {
      if (entry.value > bestDayPages ||
          (entry.value == bestDayPages &&
              bestDay != null &&
              entry.key.isAfter(bestDay))) {
        bestDay = entry.key;
        bestDayPages = entry.value;
      }
    }

    var last30 = 0;
    for (var i = 0; i < 30; i++) {
      last30 += pagesPerDay[today.addDays(-i)] ?? 0;
    }

    var activeTime = Duration.zero;
    for (final session in sessions) {
      activeTime += session.activeDuration;
    }

    return ReadingStats(
      totalPagesValidated: total,
      completedKhatmCount: completedGoals.length,
      currentStreak: _currentStreak(pagesPerDay, today),
      bestStreak: _bestStreak(pagesPerDay),
      averagePerDayLast30: last30 / 30,
      bestDay: bestDay,
      bestDayPages: bestDayPages,
      activeReadingTime: activeTime,
      pagesPerDay: pagesPerDay,
      perGoal: perGoal,
      completedGoals: completedGoals,
    );
  }

  /// Days read in a row up to today; a day without reading yet today does
  /// not break a streak that ran until yesterday.
  static int _currentStreak(Map<LocalDate, int> pagesPerDay, LocalDate today) {
    var day = (pagesPerDay[today] ?? 0) > 0 ? today : today.addDays(-1);
    var streak = 0;
    while ((pagesPerDay[day] ?? 0) > 0) {
      streak++;
      day = day.addDays(-1);
    }
    return streak;
  }

  static int _bestStreak(Map<LocalDate, int> pagesPerDay) {
    final days =
        pagesPerDay.entries
            .where((entry) => entry.value > 0)
            .map((entry) => entry.key)
            .toList()
          ..sort();
    var best = 0;
    var run = 0;
    LocalDate? previous;
    for (final day in days) {
      run = previous != null && previous.daysUntil(day) == 1 ? run + 1 : 1;
      best = math.max(best, run);
      previous = day;
    }
    return best;
  }
}
