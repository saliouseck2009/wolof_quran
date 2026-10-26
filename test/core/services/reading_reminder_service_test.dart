import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/reading/local_date.dart';
import 'package:wolof_quran/core/services/reading_reminder_service.dart';
import 'package:wolof_quran/domain/entities/reading_goal.dart';
import 'package:wolof_quran/domain/entities/reading_goal_progress.dart';

class _FakeScheduler implements ReminderScheduler {
  final List<ScheduledReminder> scheduled = [];
  int cancelAllCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  Future<void> schedule(ScheduledReminder reminder) async =>
      scheduled.add(reminder);
}

void main() {
  final now = DateTime(2026, 3, 10, 9); // 09:00
  final today = LocalDate.fromDateTime(now);
  final copy = ReminderCopy(
    title: 'Lecture',
    singleGoalBody: (goal, pages) => '$pages pages · $goal',
    multiGoalBody: (count) => '$count objectifs',
  );

  ReadingGoalProgress progress(
    String id, {
    int hour = 20,
    bool enabled = true,
    ReadingGoalStatus status = ReadingGoalStatus.active,
    Map<int, DateTime> validated = const {},
    LocalDate? startDate,
  }) {
    return ReadingGoalProgress(
      goal: ReadingGoal(
        id: id,
        name: id,
        status: status,
        startPage: 1,
        totalPages: 604,
        startDate: startDate ?? const LocalDate(2026, 3, 1),
        endDate: const LocalDate(2026, 3, 30),
        reminder: ReminderSettings(enabled: enabled, hour: hour, minute: 0),
        createdAt: now,
        updatedAt: now,
      ),
      validatedAt: validated,
      today: today,
    );
  }

  group('ReadingReminderService', () {
    late _FakeScheduler scheduler;
    late ReadingReminderService service;

    setUp(() {
      scheduler = _FakeScheduler();
      service = ReadingReminderService(scheduler: scheduler, now: () => now);
    });

    test('plans one reminder per day for a goal, today included', () {
      final plan = service.plan(
        goals: [progress('a')],
        remindersEnabled: true,
        copy: copy,
      );

      expect(plan.length, ReadingReminderService.daysAhead);
      expect(plan.first.at, DateTime(2026, 3, 10, 20));
      expect(plan.first.body, '29 pages · a'); // ceil(604 / 21 days)
      expect(plan.last.at, DateTime(2026, 3, 16, 20));
      expect(plan.map((r) => r.id).toSet().length, plan.length);
    });

    test('skips today once the quota is reached', () {
      final plan = service.plan(
        goals: [
          progress(
            'a',
            validated: {for (var p = 1; p <= 30; p++) p: now},
          ),
        ],
        remindersEnabled: true,
        copy: copy,
      );

      expect(plan.first.at, DateTime(2026, 3, 11, 20));
      expect(plan.length, ReadingReminderService.daysAhead - 1);
    });

    test('skips a time already passed today', () {
      final plan = service.plan(
        goals: [progress('a', hour: 8)],
        remindersEnabled: true,
        copy: copy,
      );
      expect(plan.first.at, DateTime(2026, 3, 11, 8));
    });

    test('groups goals sharing a time into one notification', () {
      final plan = service.plan(
        goals: [progress('a'), progress('b'), progress('c', hour: 7)],
        remindersEnabled: true,
        copy: copy,
      );

      final todayReminders = plan.where((r) => r.at.day == 10).toList();
      expect(todayReminders.length, 1);
      expect(todayReminders.single.body, '2 objectifs');
      final tomorrow = plan.where((r) => r.at.day == 11).toList();
      expect(tomorrow.length, 2);
    });

    test('ignores disabled, paused, finished and not yet started goals', () {
      final plan = service.plan(
        goals: [
          progress('off', enabled: false),
          progress('paused', status: ReadingGoalStatus.paused),
          progress('done', status: ReadingGoalStatus.completed),
          progress('later', startDate: today.addDays(30)),
        ],
        remindersEnabled: true,
        copy: copy,
      );
      expect(plan, isEmpty);
    });

    test('a planned goal is reminded from its start date', () {
      final plan = service.plan(
        goals: [progress('soon', startDate: today.addDays(2))],
        remindersEnabled: true,
        copy: copy,
      );
      expect(plan.first.at, DateTime(2026, 3, 12, 20));
    });

    test('global switch off cancels everything', () async {
      await service.sync(
        goals: [progress('a')],
        remindersEnabled: true,
        copy: copy,
      );
      expect(scheduler.scheduled, isNotEmpty);

      await service.sync(
        goals: [progress('a')],
        remindersEnabled: false,
        copy: copy,
      );
      expect(scheduler.cancelAllCalls, 2);
      expect(scheduler.scheduled, isEmpty);
    });
  });
}
