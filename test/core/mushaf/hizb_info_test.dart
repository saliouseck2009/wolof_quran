import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/mushaf/quran_page_data.dart';

void main() {
  group('getHizbInfoForPage', () {
    test('the first page opens the first hizb', () {
      expect(
        getHizbInfoForPage(1),
        const HizbInfo(hizbNumber: 1, quarter: HizbQuarter.full),
      );
    });

    test('hizb 60 starts with Al-A\'la on page 591', () {
      expect(
        getHizbInfoForPage(591),
        const HizbInfo(hizbNumber: 60, quarter: HizbQuarter.full),
      );
    });

    test('follows the real quarters of the last juz, not equal shares', () {
      expect(
        getHizbInfoForPage(582),
        const HizbInfo(hizbNumber: 59, quarter: HizbQuarter.full),
      );
      // An-Naba (78), Abasa (80), Al-Infitar (82), Al-Inshiqaq (84).
      expect(
        getHizbInfoForPage(585),
        const HizbInfo(hizbNumber: 59, quarter: HizbQuarter.oneQuarter),
      );
      expect(
        getHizbInfoForPage(587),
        const HizbInfo(hizbNumber: 59, quarter: HizbQuarter.half),
      );
      expect(
        getHizbInfoForPage(589),
        const HizbInfo(hizbNumber: 59, quarter: HizbQuarter.threeQuarter),
      );
    });

    test('every juz opens an odd hizb', () {
      for (var juz = 1; juz <= 30; juz++) {
        expect(
          getHizbInfoForPage(juzStartPages[juz - 1]),
          HizbInfo(hizbNumber: juz * 2 - 1, quarter: HizbQuarter.full),
          reason: 'juz $juz',
        );
      }
    });

    test('a page where no quarter starts has no marker', () {
      expect(getHizbInfoForPage(3), isNull);
      expect(getHizbInfoForPage(604), isNull);
    });

    test('the 240 quarters fall on 240 different pages or fewer', () {
      final marked = [
        for (var page = 1; page <= 604; page++)
          if (getHizbInfoForPage(page) != null) page,
      ];
      expect(marked.length, lessThanOrEqualTo(240));
      expect(marked.length, greaterThan(230));
    });
  });
}
