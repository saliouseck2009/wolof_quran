import 'package:equatable/equatable.dart';

import '../config/seasonal_theme_config.dart';
import '../config/theme/seasonal_theme.dart';
import '../reading/local_date.dart';
import 'lunar_phase.dart';

/// Where the user stands in the month.
enum RamadanPeriod {
  /// The day before the first night: the month starts this evening.
  eve,

  /// Nights 1 to 20 and their days.
  ramadan,

  /// From the 21st night to the end of the month.
  lastTenNights,

  /// The Korité, from the evening of the last day of fasting to `eid_end`.
  eid,
}

/// The sky drawn on the Ramadan surfaces, from the clock of the device.
enum RamadanSky {
  /// Before dawn, the time of the suhur.
  preDawn,

  /// The day of fasting.
  day,

  /// Around the maghrib, when the fast is broken.
  sunset,

  /// The night of the tarawih.
  night,
}

/// What the Ramadan surfaces show at one instant.
class RamadanMoment extends Equatable {
  final RamadanPeriod period;

  /// Day of fasting, 1 to 30, during its daytime. Null at night, on the eve
  /// and during the Korité.
  final int? day;

  /// Night of the month, 1 to 30, between nightfall and dawn. The night
  /// comes before its day: night 27 starts on the evening of day 26.
  final int? night;

  /// The night that starts this evening, shown during the daytime ("tonight:
  /// night 27"). Null at night or when no night of the month follows.
  final int? tonight;

  final RamadanSky sky;

  /// Position of the real moon in its cycle, see [LunarPhase.fractionAt].
  final double moonPhase;

  const RamadanMoment({
    required this.period,
    required this.sky,
    required this.moonPhase,
    this.day,
    this.night,
    this.tonight,
  });

  bool get isNight => night != null;

  /// The number shared by a night and the day that follows it: night 27 and
  /// day 27 pick the same verse. Null on the eve and during the Korité.
  int? get dayOfMonth => night ?? day;

  /// The odd nights of the last ten, when Laylat al-Qadr is sought.
  bool get isOddLastTenNight {
    final night = this.night;
    return night != null &&
        night >= RamadanCalendar.firstLastTenNight &&
        night.isOdd;
  }

  @override
  List<Object?> get props => [period, day, night, tonight, sky, moonPhase];

  @override
  String toString() =>
      'RamadanMoment($period, day: $day, night: $night, tonight: $tonight, $sky)';
}

/// The month of one user: the days of the config, moved by the start the
/// user chose. Pure Dart, the clock is given to [momentAt].
///
/// Nights start at a fixed local hour ([nightfallHour]) and end at
/// [dawnHour]. The real maghrib in Senegal falls around 19:15 in February
/// and March; these labels are landmarks, never prayer times.
class RamadanCalendar {
  /// First day of fasting of this user.
  final LocalDate firstDay;

  /// Last day of fasting of this user, null until it is announced.
  final LocalDate? lastDay;

  /// Last day of the Korité, null when the config does not announce it.
  final LocalDate? eidLastDay;

  const RamadanCalendar({
    required this.firstDay,
    this.lastDay,
    this.eidLastDay,
  });

  /// The calendar of the Ramadan [config], with the start moved by
  /// [startOffset] days (the user started one day after the earliest
  /// community). Null when the config is not a dated Ramadan.
  static RamadanCalendar? fromConfig(
    SeasonalThemeConfig config, {
    int startOffset = 0,
  }) {
    final start = config.start;
    if (config.theme != SeasonalTheme.ramadan || start == null) {
      return null;
    }
    LocalDate? shifted(DateTime? day) =>
        day == null ? null : LocalDate.fromDateTime(day).addDays(startOffset);
    return RamadanCalendar(
      firstDay: shifted(start)!,
      lastDay: shifted(config.end),
      eidLastDay: shifted(config.eidEnd),
    );
  }

  static const int nightfallHour = 19;
  static const int dawnHour = 5;
  static const int firstLastTenNight = 21;

  /// A lunar month has 29 or 30 days: without an announced end, the
  /// calendar never goes past 30.
  static const int maxDays = 30;

  /// Number of days of fasting: announced, or at most [maxDays].
  int get length {
    final lastDay = this.lastDay;
    if (lastDay == null) {
      return maxDays;
    }
    return (firstDay.daysUntil(lastDay) + 1).clamp(1, maxDays);
  }

  /// First day of the Korité.
  LocalDate get eidDay => firstDay.addDays(length);

  /// What to show at [now], local time of the device. Null outside the eve,
  /// the month and the Korité.
  RamadanMoment? momentAt(DateTime now) {
    final today = LocalDate.fromDateTime(now);
    final hour = now.hour;
    final moonPhase = LunarPhase.fractionAt(now);
    final sky = skyAt(now);

    // Day number of a civil date: 1 on the first day of fasting.
    int dayOf(LocalDate date) => firstDay.daysUntil(date) + 1;

    RamadanMoment? night(int number) {
      if (number < 1) {
        return null;
      }
      if (number > length) {
        return _eid(today, sky, moonPhase);
      }
      return RamadanMoment(
        period: _periodOf(number),
        night: number,
        sky: sky,
        moonPhase: moonPhase,
      );
    }

    if (hour < dawnHour) {
      // After midnight: still the night that started yesterday evening.
      return night(dayOf(today));
    }
    if (hour >= nightfallHour) {
      return night(dayOf(today) + 1);
    }

    final day = dayOf(today);
    if (day == 0) {
      return RamadanMoment(
        period: RamadanPeriod.eve,
        tonight: 1,
        sky: sky,
        moonPhase: moonPhase,
      );
    }
    if (day < 1) {
      return null;
    }
    if (day > length) {
      return _eid(today, sky, moonPhase);
    }
    return RamadanMoment(
      period: _periodOf(day),
      day: day,
      tonight: day < length ? day + 1 : null,
      sky: sky,
      moonPhase: moonPhase,
    );
  }

  /// The Korité, from the evening of the last day of fasting to the end of
  /// [eidLastDay]; null when the config does not announce it or it is over.
  RamadanMoment? _eid(LocalDate today, RamadanSky sky, double moonPhase) {
    final eidLastDay = this.eidLastDay;
    if (eidLastDay == null || today.isAfter(eidLastDay)) {
      return null;
    }
    // The evening before the Korité belongs to it, provided it still falls
    // within the announced days.
    if (eidLastDay.isBefore(eidDay)) {
      return null;
    }
    return RamadanMoment(
      period: RamadanPeriod.eid,
      sky: sky,
      moonPhase: moonPhase,
    );
  }

  static RamadanPeriod _periodOf(int dayOfMonth) =>
      dayOfMonth >= firstLastTenNight
      ? RamadanPeriod.lastTenNights
      : RamadanPeriod.ramadan;

  /// Sky of the local hour of [now]. Close to Senegal in February and March:
  /// suhur from 4:00, sunrise around 7:00, maghrib around 19:15.
  static RamadanSky skyAt(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    if (minutes >= 4 * 60 && minutes < 7 * 60) {
      return RamadanSky.preDawn;
    }
    if (minutes >= 7 * 60 && minutes < 18 * 60) {
      return RamadanSky.day;
    }
    if (minutes >= 18 * 60 && minutes < 19 * 60 + 30) {
      return RamadanSky.sunset;
    }
    return RamadanSky.night;
  }
}
