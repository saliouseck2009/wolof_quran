import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'local_date.dart';
import 'reading_order.dart';

/// Pure arithmetic of a reading plan for one calendar day. Everything is
/// derived from the validated pages and the dates, so figures stay consistent
/// after any correction.
class ReadingPlanMetrics extends Equatable {
  final int totalPages;
  final int validatedCount;
  final int continuousProgress;
  final int? firstUnvalidatedPage;
  final int remainingDays;
  final int todayTarget;
  final int readToday;

  /// Pages validated minus the pages the plan expected by the end of
  /// yesterday: positive when ahead, negative when behind.
  final int paceDelta;

  const ReadingPlanMetrics({
    required this.totalPages,
    required this.validatedCount,
    required this.continuousProgress,
    required this.firstUnvalidatedPage,
    required this.remainingDays,
    required this.todayTarget,
    required this.readToday,
    required this.paceDelta,
  });

  int get remainingPages => totalPages - validatedCount;

  double get fraction => totalPages == 0 ? 0 : validatedCount / totalPages;

  int get percent => (fraction * 100).floor();

  int get remainingForToday => math.max(0, todayTarget - readToday);

  bool get isTodayTargetReached => todayTarget == 0 || readToday >= todayTarget;

  bool get isComplete => validatedCount >= totalPages;

  @override
  List<Object?> get props => [
    totalPages,
    validatedCount,
    continuousProgress,
    firstUnvalidatedPage,
    remainingDays,
    todayTarget,
    readToday,
    paceDelta,
  ];
}

class ReadingPlanCalculator {
  const ReadingPlanCalculator._();

  /// Pages per day needed to read [totalPages] between [startDate] and
  /// [endDate] inclusive, as shown in the creation summary.
  static double averagePagesPerDay({
    required int totalPages,
    required LocalDate startDate,
    required LocalDate endDate,
  }) {
    final days = math.max(1, startDate.daysUntil(endDate) + 1);
    return totalPages / days;
  }

  /// Days left to read, today included, never below 1 so a quota always
  /// exists; an expired goal simply asks for everything that remains.
  static int remainingDays({
    required LocalDate today,
    required LocalDate startDate,
    required LocalDate endDate,
  }) {
    final from = today.isBefore(startDate) ? startDate : today;
    return math.max(1, from.daysUntil(endDate) + 1);
  }

  static ReadingPlanMetrics compute({
    required ReadingOrder order,
    required Map<int, DateTime> validatedAt,
    required LocalDate startDate,
    required LocalDate endDate,
    required LocalDate today,
  }) {
    final totalPages = order.totalPages;
    final validatedPages = validatedAt.keys.toSet();
    final validatedCount = validatedPages.length;

    var readToday = 0;
    for (final timestamp in validatedAt.values) {
      if (LocalDate.fromDateTime(timestamp) == today) {
        readToday++;
      }
    }
    final validatedBeforeToday = validatedCount - readToday;

    final days = remainingDays(
      today: today,
      startDate: startDate,
      endDate: endDate,
    );
    // The target is fixed for the day: it only depends on what was left
    // when the day began, so reading more does not shrink it live.
    final todayTarget = ((totalPages - validatedBeforeToday) / days).ceil();

    final totalDays = math.max(1, startDate.daysUntil(endDate) + 1);
    final elapsedDays = startDate.daysUntil(today).clamp(0, totalDays);
    final expectedByYesterday = (totalPages * elapsedDays / totalDays).round();

    return ReadingPlanMetrics(
      totalPages: totalPages,
      validatedCount: validatedCount,
      continuousProgress: order.continuousProgress(validatedPages),
      firstUnvalidatedPage: order.firstUnvalidatedPage(validatedPages),
      remainingDays: days,
      todayTarget: math.max(0, todayTarget),
      readToday: readToday,
      paceDelta: validatedCount - expectedByYesterday,
    );
  }

  /// Pages validated per local day, for history views.
  static Map<LocalDate, int> pagesPerDay(Map<int, DateTime> validatedAt) {
    final result = <LocalDate, int>{};
    for (final timestamp in validatedAt.values) {
      final day = LocalDate.fromDateTime(timestamp);
      result[day] = (result[day] ?? 0) + 1;
    }
    return result;
  }
}
