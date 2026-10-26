import 'package:equatable/equatable.dart';

/// A calendar day in the device's local time zone, without a time of day.
///
/// Daily quotas and goal dates are compared as calendar days, never as
/// durations, so clock or time zone changes cannot shift them.
class LocalDate extends Equatable implements Comparable<LocalDate> {
  final int year;
  final int month;
  final int day;

  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return LocalDate(local.year, local.month, local.day);
  }

  factory LocalDate.today() => LocalDate.fromDateTime(DateTime.now());

  /// Parses `YYYY-MM-DD`. Throws [FormatException] on malformed input.
  factory LocalDate.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('Invalid local date', value);
    }
    return LocalDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static LocalDate? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    try {
      return LocalDate.parse(value);
    } on FormatException {
      return null;
    }
  }

  /// Midnight of this day in local time.
  DateTime toDateTime() => DateTime(year, month, day);

  /// `YYYY-MM-DD`, the storage and sorting format.
  String toIso() {
    String pad(int value) => value.toString().padLeft(2, '0');
    return '$year-${pad(month)}-${pad(day)}';
  }

  LocalDate addDays(int days) {
    // DateTime handles month and year rollover; using UTC avoids DST gaps.
    final shifted = DateTime.utc(year, month, day).add(Duration(days: days));
    return LocalDate(shifted.year, shifted.month, shifted.day);
  }

  /// Number of days from this day to [other]; negative if [other] is earlier.
  int daysUntil(LocalDate other) {
    final from = DateTime.utc(year, month, day);
    final to = DateTime.utc(other.year, other.month, other.day);
    return to.difference(from).inDays;
  }

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  List<Object?> get props => [year, month, day];

  @override
  String toString() => toIso();
}
