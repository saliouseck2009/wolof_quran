import 'dart:math' as math;

/// Phase of the moon in the real sky, from the mean synodic month.
///
/// The mean cycle drifts from the true one by up to about half a day, far
/// below what a drawing of the moon can show. It is an illustration, never
/// the sighting that opens or closes a month.
abstract final class LunarPhase {
  /// Mean length of a lunation, in days.
  static const double synodicMonth = 29.530588853;

  /// A reference new moon: 6 January 2000, 18:14 UTC.
  static final DateTime _referenceNewMoon = DateTime.utc(2000, 1, 6, 18, 14);

  /// Position in the lunar cycle at [time], in `[0, 1)`: 0 is the new moon,
  /// 0.25 the first quarter, 0.5 the full moon, 0.75 the last quarter.
  static double fractionAt(DateTime time) {
    final days =
        time.toUtc().difference(_referenceNewMoon).inSeconds /
        Duration.secondsPerDay;
    final cycles = days / synodicMonth;
    return cycles - cycles.floorToDouble();
  }

  /// Age of the moon at [time], in days since the last new moon.
  static double ageAt(DateTime time) => fractionAt(time) * synodicMonth;

  /// Lit share of the disc for a cycle [fraction], from 0 (new) to 1 (full).
  static double illumination(double fraction) =>
      (1 - math.cos(2 * math.pi * fraction)) / 2;

  /// True while the moon grows, from the new moon to the full moon.
  static bool isWaxing(double fraction) => fraction < 0.5;
}
