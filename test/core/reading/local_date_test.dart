import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/reading/local_date.dart';

void main() {
  group('LocalDate', () {
    test('parses and serialises YYYY-MM-DD', () {
      final date = LocalDate.parse('2026-03-05');
      expect(date, const LocalDate(2026, 3, 5));
      expect(date.toIso(), '2026-03-05');
      expect(LocalDate.tryParse('nope'), isNull);
      expect(LocalDate.tryParse(null), isNull);
    });

    test('counts days across month and year boundaries', () {
      expect(
        const LocalDate(2026, 12, 30).daysUntil(const LocalDate(2027, 1, 2)),
        3,
      );
      expect(
        const LocalDate(2026, 3, 5).daysUntil(const LocalDate(2026, 3, 1)),
        -4,
      );
    });

    test('addDays rolls over months and ignores DST', () {
      expect(
        const LocalDate(2026, 1, 31).addDays(1),
        const LocalDate(2026, 2, 1),
      );
      // Around the European DST switch, a day is still a day.
      expect(
        const LocalDate(2026, 3, 28).addDays(2),
        const LocalDate(2026, 3, 30),
      );
      expect(
        const LocalDate(2026, 3, 1).addDays(-1),
        const LocalDate(2026, 2, 28),
      );
    });

    test('compares by calendar order', () {
      expect(
        const LocalDate(2026, 1, 1).isBefore(const LocalDate(2026, 1, 2)),
        isTrue,
      );
      expect(
        const LocalDate(2026, 2, 1).isAfter(const LocalDate(2026, 1, 31)),
        isTrue,
      );
      expect(
        const LocalDate(2026, 2, 1) == const LocalDate(2026, 2, 1),
        isTrue,
      );
    });

    test('fromDateTime drops the time of day', () {
      expect(
        LocalDate.fromDateTime(DateTime(2026, 5, 6, 23, 59)),
        const LocalDate(2026, 5, 6),
      );
    });
  });
}
