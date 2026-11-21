import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/seasonal/lunar_phase.dart';

void main() {
  // The mean cycle may drift from the true moon by up to about half a day.
  const tolerance = 1 / LunarPhase.synodicMonth;

  /// Distance between two positions of the cycle, which wraps around.
  double cycleDistance(double a, double b) {
    final d = (a - b).abs();
    return d > 0.5 ? 1 - d : d;
  }

  test('new moons of solar eclipses', () {
    // Total solar eclipses happen at the new moon.
    for (final newMoon in [
      DateTime.utc(2017, 8, 21, 18, 30),
      DateTime.utc(2024, 4, 8, 18, 21),
    ]) {
      expect(
        cycleDistance(LunarPhase.fractionAt(newMoon), 0),
        lessThan(tolerance),
        reason: '$newMoon',
      );
    }
  });

  test('full moons of lunar eclipses', () {
    // Lunar eclipses happen at the full moon.
    for (final fullMoon in [
      DateTime.utc(2022, 11, 8, 11, 2),
      DateTime.utc(2025, 3, 14, 6, 55),
    ]) {
      final fraction = LunarPhase.fractionAt(fullMoon);
      expect(
        cycleDistance(fraction, 0.5),
        lessThan(tolerance),
        reason: '$fullMoon',
      );
      expect(LunarPhase.illumination(fraction), greaterThan(0.98));
    }
  });

  test('the moon grows during the first half of the cycle', () {
    expect(LunarPhase.isWaxing(0.1), isTrue);
    expect(LunarPhase.isWaxing(0.6), isFalse);
    expect(LunarPhase.illumination(0), closeTo(0, 1e-9));
    expect(LunarPhase.illumination(0.25), closeTo(0.5, 1e-9));
  });

  test('a local time gives the same phase as its UTC instant', () {
    final utc = DateTime.utc(2027, 2, 20, 12);
    expect(LunarPhase.fractionAt(utc.toLocal()), LunarPhase.fractionAt(utc));
  });
}
