import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/reading_goal.dart';
import '../../domain/entities/reading_goal_progress.dart';
import '../reading/local_date.dart';

/// One notification to schedule.
class ScheduledReminder {
  final int id;
  final String title;
  final String body;
  final DateTime at;

  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
  });

  @override
  String toString() => 'ScheduledReminder($id, $at, $title)';
}

/// Localized texts of a reminder; built by the caller, which has the
/// localizations.
class ReminderCopy {
  final String title;
  final String Function(String goalName, int remainingPages) singleGoalBody;
  final String Function(int goalCount) multiGoalBody;

  const ReminderCopy({
    required this.title,
    required this.singleGoalBody,
    required this.multiGoalBody,
  });
}

/// Platform side of reminders, swapped for a fake in tests.
abstract class ReminderScheduler {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> cancelAll();

  Future<void> schedule(ScheduledReminder reminder);
}

/// Plans the reading reminders of every goal for the coming days.
///
/// One notification per distinct time per day, grouping the goals that
/// share that time. Today's reminder is skipped once every goal due at that
/// time has met its quota. Called after each change of the goals so the
/// plan always reflects the latest progress.
class ReadingReminderService {
  /// Days planned ahead; the plan is rebuilt on every change anyway, and
  /// iOS caps pending notifications at 64.
  static const daysAhead = 7;

  final ReminderScheduler _scheduler;
  final DateTime Function() _now;

  ReadingReminderService({
    required ReminderScheduler scheduler,
    DateTime Function()? now,
  }) : _scheduler = scheduler,
       _now = now ?? DateTime.now;

  Future<void> initialize() => _scheduler.initialize();

  Future<bool> requestPermission() => _scheduler.requestPermission();

  /// Reminders that [sync] would schedule, for inspection and tests.
  List<ScheduledReminder> plan({
    required List<ReadingGoalProgress> goals,
    required bool remindersEnabled,
    required ReminderCopy copy,
  }) {
    if (!remindersEnabled) {
      return const [];
    }
    final now = _now();
    final today = LocalDate.fromDateTime(now);
    final candidates = goals
        .where(
          (progress) =>
              progress.goal.reminder.enabled &&
              progress.goal.acceptsProgress &&
              progress.goal.status != ReadingGoalStatus.paused,
        )
        .toList();
    if (candidates.isEmpty) {
      return const [];
    }

    final reminders = <ScheduledReminder>[];
    for (var offset = 0; offset < daysAhead; offset++) {
      final day = today.addDays(offset);
      final byTime = <int, List<ReadingGoalProgress>>{};
      for (final progress in candidates) {
        final goal = progress.goal;
        if (day.isBefore(goal.startDate)) {
          continue;
        }
        // Today: nothing once the quota is met. Later days: the quota is
        // unknown yet, so every goal counts.
        if (offset == 0 && progress.metrics.isTodayTargetReached) {
          continue;
        }
        final minuteOfDay = goal.reminder.hour * 60 + goal.reminder.minute;
        byTime.putIfAbsent(minuteOfDay, () => []).add(progress);
      }
      for (final entry in byTime.entries) {
        final at = DateTime(
          day.year,
          day.month,
          day.day,
          entry.key ~/ 60,
          entry.key % 60,
        );
        if (!at.isAfter(now)) {
          continue;
        }
        final due = entry.value;
        final body = due.length == 1
            ? copy.singleGoalBody(
                due.single.goal.name,
                offset == 0
                    ? due.single.metrics.remainingForToday
                    : due.single.metrics.todayTarget,
              )
            : copy.multiGoalBody(due.length);
        reminders.add(
          ScheduledReminder(
            id: offset * 1440 + entry.key,
            title: copy.title,
            body: body,
            at: at,
          ),
        );
      }
    }
    return reminders;
  }

  Future<void> sync({
    required List<ReadingGoalProgress> goals,
    required bool remindersEnabled,
    required ReminderCopy copy,
  }) async {
    await _scheduler.cancelAll();
    for (final reminder in plan(
      goals: goals,
      remindersEnabled: remindersEnabled,
      copy: copy,
    )) {
      await _scheduler.schedule(reminder);
    }
  }
}

/// [ReminderScheduler] backed by flutter_local_notifications.
class LocalNotificationsReminderScheduler implements ReminderScheduler {
  static const _channelId = 'reading_reminders';
  static const _channelName = 'Reading reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  LocalNotificationsReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  @override
  Future<void> schedule(ScheduledReminder reminder) async {
    await initialize();
    // The reminder is an absolute instant, so the UTC location is exact
    // without knowing the device's zone name.
    final at = tz.TZDateTime.from(reminder.at, tz.UTC);
    await _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: at,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
