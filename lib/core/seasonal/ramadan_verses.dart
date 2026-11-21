import 'dart:math';

/// A verse of the Quran: its surah and its number in the surah.
typedef VerseRef = (int surah, int verse);

/// The verses of the Ramadan "verse of the day", chosen with the editor of
/// the app. Each one reads on its own (no verse that starts in the middle
/// of a sentence).
abstract final class RamadanVerses {
  /// One verse per day of the month, 1 to 30: fasting, then the Quran and
  /// the remembrance of Allah, then giving and forgiveness, then the night
  /// prayer and Laylat al-Qadr. The odd nights of the last ten (21 to 29)
  /// carry Ad-Dukhan 3 and the surah Al-Qadr. A night and the day that
  /// follows it share their verse.
  static const List<VerseRef> byDay = [
    (2, 183), // 1 — fasting is prescribed
    (3, 102), // 2 — piety
    (2, 185), // 3 — the month of the Quran
    (2, 186), // 4 — Allah is near
    (2, 187), // 5 — the white thread of dawn
    (33, 35), // 6 — the men and women who fast
    (39, 10), // 7 — patience
    (2, 153), // 8 — patience and prayer
    (17, 9), // 9 — the Quran guides
    (73, 20), // 10 — recite what is easy
    (33, 41), // 11 — remember Allah often
    (2, 152), // 12 — remember Me
    (7, 205), // 13 — remembrance morning and evening
    (3, 190), // 14 — the signs of the creation
    (2, 261), // 15 — charity multiplied
    (2, 274), // 16 — giving by night and by day
    (3, 123), // 17 — Badr, on the 17th of Ramadan
    (3, 133), // 18 — hasten to forgiveness
    (39, 53), // 19 — do not despair of mercy
    (40, 60), // 20 — call upon Me
    (44, 3), // 21 — the blessed night
    (17, 79), // 22 — the night prayer
    (97, 1), // 23 — Laylat al-Qadr
    (32, 16), // 24 — leaving the bed to pray
    (97, 4), // 25 — the angels descend
    (71, 10), // 26 — ask forgiveness
    (97, 3), // 27 — better than a thousand months
    (73, 6), // 28 — the prayer of the night
    (97, 5), // 29 — peace until dawn
    (87, 14), // 30 — purification
  ];

  /// Invocations added to the draw of "another verse".
  static const List<VerseRef> invocations = [
    (2, 201),
    (2, 286),
    (3, 8),
    (14, 7),
    (25, 63),
  ];

  /// The eve and the Korité: the month of the Quran, which ends with
  /// "that you complete the number and proclaim the greatness of Allah".
  static const VerseRef eveAndEid = (2, 185);

  /// Everything "another verse" draws from.
  static const List<VerseRef> pool = [...byDay, ...invocations];

  /// The verse of [dayOfMonth] (1 to 30), clamped to the month.
  static VerseRef ofDay(int dayOfMonth) =>
      byDay[(dayOfMonth - 1).clamp(0, byDay.length - 1)];

  /// A verse of [pool] other than [current].
  static VerseRef another(VerseRef? current, [Random? random]) {
    final choices = [
      for (final verse in pool)
        if (verse != current) verse,
    ];
    return choices[(random ?? Random()).nextInt(choices.length)];
  }
}
