import 'package:equatable/equatable.dart';

import '../../core/reading/local_date.dart';
import '../../core/reading/reading_order.dart';

/// Status chosen by the user. `planned` and `expired` are not stored: they
/// are derived from the dates, see [ReadingGoal.phase].
enum ReadingGoalStatus {
  active,
  paused,
  completed,
  abandoned;

  String get dbValue => name;

  static ReadingGoalStatus fromDb(String? value) {
    return ReadingGoalStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ReadingGoalStatus.active,
    );
  }
}

/// What the goal is doing today, combining [ReadingGoalStatus] and dates.
enum ReadingGoalPhase { planned, active, paused, completed, expired, abandoned }

class ReminderSettings extends Equatable {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  /// `HH:mm`, the storage format.
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static ReminderSettings fromDb({required bool enabled, String? time}) {
    final parts = time?.split(':');
    final hour = parts != null && parts.length == 2
        ? int.tryParse(parts[0])
        : null;
    final minute = parts != null && parts.length == 2
        ? int.tryParse(parts[1])
        : null;
    return ReminderSettings(
      enabled: enabled,
      hour: hour ?? 20,
      minute: minute ?? 0,
    );
  }

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  List<Object?> get props => [enabled, hour, minute];
}

/// A reading plan over the whole mushaf, with its own dates and progress.
class ReadingGoal extends Equatable {
  static const defaultMushafEdition = 'qcf_madani_604';

  final String id;
  final String name;
  final ReadingGoalStatus status;
  final int startPage;
  final int totalPages;
  final String mushafEdition;
  final LocalDate startDate;
  final LocalDate endDate;
  final LocalDate? pausedAt;
  final int? lastViewedPage;
  final ReminderSettings reminder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const ReadingGoal({
    required this.id,
    required this.name,
    required this.status,
    required this.startPage,
    required this.totalPages,
    this.mushafEdition = defaultMushafEdition,
    required this.startDate,
    required this.endDate,
    this.pausedAt,
    this.lastViewedPage,
    this.reminder = const ReminderSettings(),
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  ReadingOrder get order =>
      ReadingOrder(startPage: startPage, totalPages: totalPages);

  /// Number of days the plan spans, start and end included.
  int get durationDays => startDate.daysUntil(endDate) + 1;

  ReadingGoalPhase phase(LocalDate today) {
    switch (status) {
      case ReadingGoalStatus.completed:
        return ReadingGoalPhase.completed;
      case ReadingGoalStatus.abandoned:
        return ReadingGoalPhase.abandoned;
      case ReadingGoalStatus.paused:
        return ReadingGoalPhase.paused;
      case ReadingGoalStatus.active:
        if (today.isBefore(startDate)) {
          return ReadingGoalPhase.planned;
        }
        if (today.isAfter(endDate)) {
          return ReadingGoalPhase.expired;
        }
        return ReadingGoalPhase.active;
    }
  }

  /// Whether pages can still be validated in this goal.
  bool get acceptsProgress =>
      status == ReadingGoalStatus.active || status == ReadingGoalStatus.paused;

  ReadingGoal copyWith({
    String? name,
    ReadingGoalStatus? status,
    int? startPage,
    int? totalPages,
    String? mushafEdition,
    LocalDate? startDate,
    LocalDate? endDate,
    LocalDate? pausedAt,
    bool clearPausedAt = false,
    int? lastViewedPage,
    ReminderSettings? reminder,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ReadingGoal(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      startPage: startPage ?? this.startPage,
      totalPages: totalPages ?? this.totalPages,
      mushafEdition: mushafEdition ?? this.mushafEdition,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      lastViewedPage: lastViewedPage ?? this.lastViewedPage,
      reminder: reminder ?? this.reminder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    status,
    startPage,
    totalPages,
    mushafEdition,
    startDate,
    endDate,
    pausedAt,
    lastViewedPage,
    reminder,
    createdAt,
    updatedAt,
    completedAt,
  ];
}
