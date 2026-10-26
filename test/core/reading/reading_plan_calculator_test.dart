import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/reading/local_date.dart';
import 'package:wolof_quran/core/reading/reading_order.dart';
import 'package:wolof_quran/core/reading/reading_plan_calculator.dart';

void main() {
  const order = ReadingOrder(startPage: 1, totalPages: 604);
  const start = LocalDate(2026, 3, 1);
  const end = LocalDate(2026, 3, 30); // 30 days

  Map<int, DateTime> readOn(Iterable<int> pages, DateTime when) => {
    for (final page in pages) page: when,
  };

  group('ReadingPlanCalculator', () {
    test('initial daily target is the ceiling of pages per day', () {
      final metrics = ReadingPlanCalculator.compute(
        order: order,
        validatedAt: const {},
        startDate: start,
        endDate: end,
        today: start,
      );
      expect(metrics.remainingDays, 30);
      expect(metrics.todayTarget, 21); // ceil(604 / 30)
      expect(metrics.readToday, 0);
      expect(metrics.remainingForToday, 21);
      expect(metrics.isTodayTargetReached, isFalse);
      expect(metrics.paceDelta, 0);
      expect(
        ReadingPlanCalculator.averagePagesPerDay(
          totalPages: 604,
          startDate: start,
          endDate: end,
        ),
        closeTo(20.13, 0.01),
      );
    });

    test('today target stays fixed while reading during the day', () {
      final today = DateTime(2026, 3, 1, 10);
      final metrics = ReadingPlanCalculator.compute(
        order: order,
        validatedAt: readOn([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], today),
        startDate: start,
        endDate: end,
        today: start,
      );
      expect(metrics.todayTarget, 21);
      expect(metrics.readToday, 10);
      expect(metrics.remainingForToday, 11);
    });

    test('reading ahead lowers the following days', () {
      // Day 1: 30 pages instead of 21. Day 2 target = ceil(574 / 29) = 20.
      final metrics = ReadingPlanCalculator.compute(
        order: order,
        validatedAt: readOn(
          List.generate(30, (i) => i + 1),
          DateTime(2026, 3, 1, 20),
        ),
        startDate: start,
        endDate: end,
        today: const LocalDate(2026, 3, 2),
      );
      expect(metrics.remainingDays, 29);
      expect(metrics.todayTarget, 20);
      expect(metrics.paceDelta, 30 - 20); // expected 20 by end of day 1
    });

    test('falling behind raises the following days', () {
      // Day 1: 10 pages. Day 2 target = ceil(594 / 29) = 21.
      final metrics = ReadingPlanCalculator.compute(
        order: order,
        validatedAt: readOn(
          List.generate(10, (i) => i + 1),
          DateTime(2026, 3, 1, 20),
        ),
        startDate: start,
        endDate: end,
        today: const LocalDate(2026, 3, 2),
      );
      expect(metrics.todayTarget, 21);
      expect(metrics.paceDelta, 10 - 20);
    });

    test('target is reached and overshoot is kept', () {
      final metrics = ReadingPlanCalculator.compute(
        order: order,
        validatedAt: readOn(
          List.generate(25, (i) => i + 1),
          DateTime(2026, 3, 1, 9),
        ),
        startDate: start,
        endDate: end,
        today: start,
      );
      expect(metrics.isTodayTargetReached, isTrue);
      expect(metrics.remainingForToday, 0);
      expect(metrics.readToday, 25);
    });

    test('an expired goal asks for everything that remains', () {
      final metrics = ReadingPlanCalculator.compute(
        order: order,
        validatedAt: readOn(
          List.generate(100, (i) => i + 1),
          DateTime(2026, 3, 10),
        ),
        startDate: start,
        endDate: end,
        today: const LocalDate(2026, 4, 15),
      );
      expect(metrics.remainingDays, 1);
      expect(metrics.todayTarget, 504);
      expect(metrics.paceDelta, 100 - 604);
    });

    test('a planned goal counts days from its start date', () {
      final metrics = ReadingPlanCalculator.compute(
        order: order,
        validatedAt: const {},
        startDate: start,
        endDate: end,
        today: const LocalDate(2026, 2, 20),
      );
      expect(metrics.remainingDays, 30);
      expect(metrics.paceDelta, 0);
    });

    test('completion and continuous progress are reported', () {
      final all = readOn(
        List.generate(604, (i) => i + 1),
        DateTime(2026, 3, 5),
      );
      final metrics = ReadingPlanCalculator.compute(
        order: order,
        validatedAt: all,
        startDate: start,
        endDate: end,
        today: const LocalDate(2026, 3, 6),
      );
      expect(metrics.isComplete, isTrue);
      expect(metrics.percent, 100);
      expect(metrics.firstUnvalidatedPage, isNull);
      expect(metrics.todayTarget, 0);
      expect(metrics.isTodayTargetReached, isTrue);
    });

    test('skipped pages do not advance continuous progress', () {
      final validated = readOn([
        ...List.generate(100, (i) => i + 1),
        105,
      ], DateTime(2026, 3, 3));
      final metrics = ReadingPlanCalculator.compute(
        order: order,
        validatedAt: validated,
        startDate: start,
        endDate: end,
        today: const LocalDate(2026, 3, 3),
      );
      expect(metrics.validatedCount, 101);
      expect(metrics.continuousProgress, 100);
      expect(metrics.firstUnvalidatedPage, 101);
    });

    test('pagesPerDay groups by local day', () {
      final perDay = ReadingPlanCalculator.pagesPerDay({
        1: DateTime(2026, 3, 1, 8),
        2: DateTime(2026, 3, 1, 23),
        3: DateTime(2026, 3, 2, 0, 5),
      });
      expect(perDay[const LocalDate(2026, 3, 1)], 2);
      expect(perDay[const LocalDate(2026, 3, 2)], 1);
    });
  });
}
