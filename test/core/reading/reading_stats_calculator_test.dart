import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/reading/local_date.dart';
import 'package:wolof_quran/core/reading/reading_stats_calculator.dart';
import 'package:wolof_quran/domain/entities/reading_goal.dart';
import 'package:wolof_quran/domain/entities/reading_session.dart';

void main() {
  const today = LocalDate(2026, 3, 10);
  final now = DateTime(2026, 3, 10, 9);

  ReadingGoal goal(
    String id, {
    ReadingGoalStatus status = ReadingGoalStatus.active,
  }) {
    return ReadingGoal(
      id: id,
      name: id,
      status: status,
      startPage: 1,
      totalPages: 604,
      startDate: const LocalDate(2026, 3, 1),
      endDate: const LocalDate(2026, 3, 30),
      createdAt: now,
      updatedAt: now,
      completedAt: status == ReadingGoalStatus.completed ? now : null,
    );
  }

  Map<int, DateTime> readOn(int firstPage, int count, LocalDate day) => {
    for (var p = firstPage; p < firstPage + count; p++)
      p: DateTime(day.year, day.month, day.day, 12),
  };

  group('ReadingStatsCalculator', () {
    test('sums pages across goals and counts completed khatm', () {
      final stats = ReadingStatsCalculator.compute(
        goals: [
          goal('a'),
          goal('b', status: ReadingGoalStatus.completed),
        ],
        validatedByGoal: {
          'a': readOn(1, 10, today),
          'b': readOn(1, 10, today.addDays(-1)),
        },
        sessions: const [],
        today: today,
      );

      expect(stats.totalPagesValidated, 20);
      expect(stats.completedKhatmCount, 1);
      expect(stats.perGoal.first.validatedCount, 10);
      expect(stats.pagesPerDay[today], 10);
      expect(stats.completedGoals.single.id, 'b');
    });

    test('streaks count consecutive reading days', () {
      final stats = ReadingStatsCalculator.compute(
        goals: [goal('a')],
        validatedByGoal: {
          'a': {
            ...readOn(1, 2, today.addDays(-6)),
            ...readOn(3, 2, today.addDays(-5)),
            ...readOn(5, 2, today.addDays(-4)),
            // gap on day -3
            ...readOn(7, 2, today.addDays(-2)),
            ...readOn(9, 2, today.addDays(-1)),
          },
        },
        sessions: const [],
        today: today,
      );

      // Nothing read yet today: the streak that ended yesterday still holds.
      expect(stats.currentStreak, 2);
      expect(stats.bestStreak, 3);
    });

    test('a streak broken two days ago is zero', () {
      final stats = ReadingStatsCalculator.compute(
        goals: [goal('a')],
        validatedByGoal: {'a': readOn(1, 5, today.addDays(-3))},
        sessions: const [],
        today: today,
      );
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 1);
    });

    test('best day, 30-day average and reading time', () {
      final stats = ReadingStatsCalculator.compute(
        goals: [goal('a')],
        validatedByGoal: {
          'a': {
            ...readOn(1, 30, today.addDays(-40)), // outside the window
            ...readOn(31, 12, today.addDays(-2)),
            ...readOn(43, 18, today),
          },
        },
        sessions: [
          ReadingSession(
            id: 's1',
            goalId: 'a',
            startedAt: now,
            activeDuration: const Duration(minutes: 25),
          ),
          ReadingSession(
            id: 's2',
            goalId: 'a',
            startedAt: now,
            activeDuration: const Duration(minutes: 5),
          ),
        ],
        today: today,
      );

      expect(stats.bestDay, today.addDays(-40));
      expect(stats.bestDayPages, 30);
      expect(stats.averagePerDayLast30, closeTo(1.0, 0.001));
      expect(stats.activeReadingTime, const Duration(minutes: 30));
      expect(stats.lastDays(today, 3).map((d) => d.$2), [12, 0, 18]);
    });

    test('empty input yields empty stats', () {
      final stats = ReadingStatsCalculator.compute(
        goals: const [],
        validatedByGoal: const {},
        sessions: const [],
        today: today,
      );
      expect(stats.isEmpty, isTrue);
      expect(stats.bestDay, isNull);
      expect(stats.currentStreak, 0);
    });
  });
}
