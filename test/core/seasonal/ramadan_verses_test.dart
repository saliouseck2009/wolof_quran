import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wolof_quran/core/seasonal/ramadan_verses.dart';

void main() {
  test('one verse for each of the 30 days', () {
    expect(RamadanVerses.byDay, hasLength(30));
    expect(RamadanVerses.byDay.toSet(), hasLength(30));
  });

  test('every reference exists in the Quran', () {
    for (final (surah, verse) in [
      ...RamadanVerses.pool,
      RamadanVerses.eveAndEid,
    ]) {
      expect(surah, inInclusiveRange(1, 114));
      expect(
        verse,
        inInclusiveRange(1, quran.getVerseCount(surah)),
        reason: '$surah:$verse',
      );
    }
  });

  test('no verse starts in the middle of a sentence', () {
    for (final (surah, verse) in RamadanVerses.pool) {
      final text = quran.getVerseTranslation(
        surah,
        verse,
        translation: quran.Translation.frHamidullah,
      );
      final first = text.trimLeft()[0];
      expect(
        first == first.toLowerCase() && first != first.toUpperCase(),
        isFalse,
        reason: '$surah:$verse starts with "$first"',
      );
    }
  });

  test('the odd nights of the last ten carry Laylat al-Qadr', () {
    expect(RamadanVerses.ofDay(21), (44, 3));
    expect(RamadanVerses.ofDay(23), (97, 1));
    expect(RamadanVerses.ofDay(25), (97, 4));
    expect(RamadanVerses.ofDay(27), (97, 3));
    expect(RamadanVerses.ofDay(29), (97, 5));
  });

  test('the day is clamped to the month', () {
    expect(RamadanVerses.ofDay(0), RamadanVerses.byDay.first);
    expect(RamadanVerses.ofDay(31), RamadanVerses.byDay.last);
  });

  test('another verse differs from the current one', () {
    final random = Random(1);
    for (var i = 0; i < 50; i++) {
      expect(RamadanVerses.another((97, 3), random), isNot((97, 3)));
    }
  });
}
