import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/config/seasonal_theme_config.dart';
import 'package:wolof_quran/core/config/theme/seasonal_theme.dart';
import 'package:wolof_quran/core/reading/local_date.dart';
import 'package:wolof_quran/core/seasonal/ramadan_calendar.dart';

void main() {
  // Ramadan 1448 as an example: first day of fasting on 8 February 2027.
  // Day 26 is 5 March, day 27 is 6 March.
  const firstDay = LocalDate(2027, 2, 8);

  group('night 27', () {
    const calendar = RamadanCalendar(firstDay: firstDay);

    test(
      'day 26 announces it, nightfall opens it, dawn turns it into day 27',
      () {
        final afternoon = calendar.momentAt(DateTime(2027, 3, 5, 15))!;
        expect(afternoon.day, 26);
        expect(afternoon.night, isNull);
        expect(afternoon.tonight, 27);

        final nightfall = calendar.momentAt(DateTime(2027, 3, 5, 19))!;
        expect(nightfall.night, 27);
        expect(nightfall.day, isNull);
        expect(nightfall.tonight, isNull);
        expect(nightfall.isOddLastTenNight, isTrue);

        final afterMidnight = calendar.momentAt(DateTime(2027, 3, 6, 2, 30))!;
        expect(afterMidnight.night, 27);

        final dawn = calendar.momentAt(DateTime(2027, 3, 6, 5))!;
        expect(dawn.day, 27);
        expect(dawn.night, isNull);
        expect(dawn.tonight, 28);
      },
    );

    test('night 27 and day 27 share their number', () {
      expect(calendar.momentAt(DateTime(2027, 3, 5, 22))!.dayOfMonth, 27);
      expect(calendar.momentAt(DateTime(2027, 3, 6, 12))!.dayOfMonth, 27);
    });
  });

  group('periods', () {
    const calendar = RamadanCalendar(
      firstDay: firstDay,
      lastDay: LocalDate(2027, 3, 9), // 30 days
      eidLastDay: LocalDate(2027, 3, 11),
    );

    test('nothing before the eve', () {
      expect(calendar.momentAt(DateTime(2027, 2, 6, 20)), isNull);
      expect(calendar.momentAt(DateTime(2027, 2, 7, 4, 59)), isNull);
    });

    test('the eve announces night 1, which starts at nightfall', () {
      final eve = calendar.momentAt(DateTime(2027, 2, 7, 10))!;
      expect(eve.period, RamadanPeriod.eve);
      expect(eve.day, isNull);
      expect(eve.tonight, 1);

      final firstNight = calendar.momentAt(DateTime(2027, 2, 7, 20))!;
      expect(firstNight.period, RamadanPeriod.ramadan);
      expect(firstNight.night, 1);

      final firstDayOfFasting = calendar.momentAt(DateTime(2027, 2, 8, 9))!;
      expect(firstDayOfFasting.day, 1);
      expect(firstDayOfFasting.tonight, 2);
    });

    test(
      'the last ten nights start with night 21, on the evening of day 20',
      () {
        final day20 = calendar.momentAt(DateTime(2027, 2, 27, 12))!;
        expect(day20.day, 20);
        expect(day20.period, RamadanPeriod.ramadan);
        expect(day20.tonight, 21);

        final night21 = calendar.momentAt(DateTime(2027, 2, 27, 21))!;
        expect(night21.night, 21);
        expect(night21.period, RamadanPeriod.lastTenNights);
        expect(night21.isOddLastTenNight, isTrue);

        final night22 = calendar.momentAt(DateTime(2027, 2, 28, 21))!;
        expect(night22.night, 22);
        expect(night22.isOddLastTenNight, isFalse);
      },
    );

    test(
      'the Korité starts on the evening of the last day and ends with eid_end',
      () {
        final lastDay = calendar.momentAt(DateTime(2027, 3, 9, 12))!;
        expect(lastDay.day, 30);
        expect(lastDay.tonight, isNull);

        final eidNight = calendar.momentAt(DateTime(2027, 3, 9, 20))!;
        expect(eidNight.period, RamadanPeriod.eid);
        expect(eidNight.night, isNull);

        expect(
          calendar.momentAt(DateTime(2027, 3, 10, 10))!.period,
          RamadanPeriod.eid,
        );
        expect(
          calendar.momentAt(DateTime(2027, 3, 11, 23))!.period,
          RamadanPeriod.eid,
        );
        expect(calendar.momentAt(DateTime(2027, 3, 12, 1)), isNull);
        expect(calendar.momentAt(DateTime(2027, 3, 12, 10)), isNull);
      },
    );
  });

  group('length of the month', () {
    test('a month of 29 days goes to the Korité after day 29', () {
      const calendar = RamadanCalendar(
        firstDay: firstDay,
        lastDay: LocalDate(2027, 3, 8),
        eidLastDay: LocalDate(2027, 3, 9),
      );

      final lastDay = calendar.momentAt(DateTime(2027, 3, 8, 12))!;
      expect(lastDay.day, 29);
      expect(lastDay.tonight, isNull);
      expect(
        calendar.momentAt(DateTime(2027, 3, 8, 20))!.period,
        RamadanPeriod.eid,
      );
      expect(
        calendar.momentAt(DateTime(2027, 3, 9, 12))!.period,
        RamadanPeriod.eid,
      );
    });

    test('an unknown end allows night 30 but never night 31', () {
      const calendar = RamadanCalendar(firstDay: firstDay);

      expect(calendar.momentAt(DateTime(2027, 3, 8, 20))!.night, 30);
      final day30 = calendar.momentAt(DateTime(2027, 3, 9, 12))!;
      expect(day30.day, 30);
      expect(day30.tonight, isNull);
      // Without an announced Korité the last day stays until midnight,
      // then the month simply ends.
      final lastEvening = calendar.momentAt(DateTime(2027, 3, 9, 20))!;
      expect(lastEvening.day, 30);
      expect(lastEvening.night, isNull);
      expect(calendar.momentAt(DateTime(2027, 3, 10, 1)), isNull);
      expect(calendar.momentAt(DateTime(2027, 3, 10, 12)), isNull);
    });

    test('an unknown end with an announced Korité assumes 30 days', () {
      const calendar = RamadanCalendar(
        firstDay: firstDay,
        eidLastDay: LocalDate(2027, 3, 10),
      );

      expect(
        calendar.momentAt(DateTime(2027, 3, 9, 20))!.period,
        RamadanPeriod.eid,
      );
      expect(calendar.momentAt(DateTime(2027, 3, 9, 20))!.night, isNull);
    });

    test('an end announced beyond 30 days is capped', () {
      const calendar = RamadanCalendar(
        firstDay: firstDay,
        lastDay: LocalDate(2027, 3, 12),
      );

      expect(calendar.length, 30);
      expect(calendar.momentAt(DateTime(2027, 3, 10, 12)), isNull);
    });
  });

  group('fromConfig', () {
    final config = SeasonalThemeConfig(
      theme: SeasonalTheme.ramadan,
      enabled: true,
      start: DateTime(2027, 2, 8),
      end: DateTime(2027, 3, 9),
      eidEnd: DateTime(2027, 3, 10),
    );

    test('reads the days of the config', () {
      final calendar = RamadanCalendar.fromConfig(config)!;

      expect(calendar.firstDay, firstDay);
      expect(calendar.lastDay, const LocalDate(2027, 3, 9));
      expect(calendar.eidLastDay, const LocalDate(2027, 3, 10));
    });

    test('a later start moves every day of the month', () {
      final calendar = RamadanCalendar.fromConfig(config, startOffset: 1)!;

      expect(calendar.firstDay, const LocalDate(2027, 2, 9));
      expect(calendar.lastDay, const LocalDate(2027, 3, 10));
      expect(calendar.eidLastDay, const LocalDate(2027, 3, 11));
      // Night 27 is one evening later than for the earliest community.
      expect(calendar.momentAt(DateTime(2027, 3, 5, 21))!.night, 26);
      expect(calendar.momentAt(DateTime(2027, 3, 6, 21))!.night, 27);
    });

    test('needs a dated Ramadan', () {
      expect(
        RamadanCalendar.fromConfig(
          const SeasonalThemeConfig(
            theme: SeasonalTheme.ramadan,
            enabled: true,
          ),
        ),
        isNull,
      );
      expect(RamadanCalendar.fromConfig(SeasonalThemeConfig.disabled), isNull);
    });
  });

  group('sky', () {
    test('follows the local hour', () {
      RamadanSky at(int hour, [int minute = 0]) =>
          RamadanCalendar.skyAt(DateTime(2027, 2, 20, hour, minute));

      expect(at(3, 59), RamadanSky.night);
      expect(at(4), RamadanSky.preDawn);
      expect(at(6, 59), RamadanSky.preDawn);
      expect(at(7), RamadanSky.day);
      expect(at(17, 59), RamadanSky.day);
      expect(at(18), RamadanSky.sunset);
      expect(at(19, 29), RamadanSky.sunset);
      expect(at(19, 30), RamadanSky.night);
      expect(at(23), RamadanSky.night);
    });

    test('is carried by the moment', () {
      const calendar = RamadanCalendar(firstDay: firstDay);

      expect(
        calendar.momentAt(DateTime(2027, 2, 20, 18, 45))!.sky,
        RamadanSky.sunset,
      );
    });
  });

  group('nextChangeAfter', () {
    DateTime next(int hour, int minute) =>
        RamadanCalendar.nextChangeAfter(DateTime(2027, 3, 5, hour, minute));

    test('goes from one change of the day to the next', () {
      expect(next(0, 0), DateTime(2027, 3, 5, 4));
      expect(next(4, 0), DateTime(2027, 3, 5, 5));
      expect(next(12, 0), DateTime(2027, 3, 5, 18));
      expect(next(18, 59), DateTime(2027, 3, 5, 19));
      expect(next(19, 0), DateTime(2027, 3, 5, 19, 30));
    });

    test('ends the day at midnight', () {
      expect(next(19, 30), DateTime(2027, 3, 6));
      expect(
        RamadanCalendar.nextChangeAfter(DateTime(2027, 2, 28, 23)),
        DateTime(2027, 3, 1),
      );
    });
  });
}
