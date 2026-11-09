import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/mushaf/quran_page_data.dart';
import 'package:wolof_quran/core/reading/quran_sections.dart';
import 'package:wolof_quran/core/reading/reading_order.dart';

void main() {
  group('QuranSections', () {
    test('juz pages match the known start pages and cover the mushaf', () {
      final juz = QuranSections.of(QuranSectionType.juz);
      expect(juz.length, 30);
      for (var n = 1; n <= 30; n++) {
        expect(juz[n - 1].firstPage, juzStartPages[n - 1], reason: 'juz $n');
      }
      expect(juz.first.firstPage, 1);
      expect(juz.last.lastPage, 604);
      for (var n = 1; n < 30; n++) {
        final gapOrOverlap = juz[n].firstPage - juz[n - 1].lastPage;
        expect(gapOrOverlap, anyOf(0, 1), reason: 'juz $n → ${n + 1}');
      }
    });

    test('hizb sections tile the mushaf in order', () {
      final hizb = QuranSections.of(QuranSectionType.hizb);
      expect(hizb.length, 60);
      expect(hizb.first.firstPage, 1);
      expect(hizb.last.lastPage, 604);
      for (var n = 1; n < 60; n++) {
        expect(hizb[n].firstPage, greaterThanOrEqualTo(hizb[n - 1].lastPage));
      }
      // Each juz is exactly its two hizb.
      final juz = QuranSections.of(QuranSectionType.juz);
      for (var n = 1; n <= 30; n++) {
        expect(hizb[(n - 1) * 2].firstPage, juz[n - 1].firstPage);
        expect(hizb[(n - 1) * 2 + 1].lastPage, juz[n - 1].lastPage);
      }
    });

    test('surah sections flag pages shared with their neighbours', () {
      final surahs = QuranSections.of(QuranSectionType.surah);
      expect(surahs.length, 114);
      expect(surahs.first.firstPage, 1);
      expect(surahs.first.sharesFirstPage, isFalse);
      expect(surahs.last.lastPage, 604);
      // Consecutive surahs share a page exactly when both flag it.
      for (var i = 0; i < surahs.length - 1; i++) {
        final current = surahs[i];
        final next = surahs[i + 1];
        final shared = current.lastPage == next.firstPage;
        expect(current.sharesLastPage, shared, reason: 'surah ${i + 1}');
        expect(next.sharesFirstPage, shared, reason: 'surah ${i + 2}');
        expect(next.firstPage - current.lastPage, anyOf(0, 1));
      }
      // Short surahs at the end of the mushaf sit several to a page.
      final nas = QuranSections.get(QuranSectionType.surah, 114);
      final falaq = QuranSections.get(QuranSectionType.surah, 113);
      expect(nas.firstPage, 604);
      expect(nas.sharesFirstPage, isTrue);
      expect(falaq.sharesLastPage, isTrue);
    });

    test('shared pages can be left out', () {
      final nas = QuranSections.get(QuranSectionType.surah, 114);
      final all = nas.pagesIncluding(sharedFirst: true, sharedLast: true);
      final withoutFirst = nas.pagesIncluding(
        sharedFirst: false,
        sharedLast: true,
      );
      expect(all, [604]);
      expect(withoutFirst, isEmpty);

      final fatiha = QuranSections.get(QuranSectionType.surah, 1);
      expect(fatiha.pagesIncluding(sharedFirst: false, sharedLast: false), [1]);
    });
  });

  group('QuranSections.nextEndAfter', () {
    const mushafOrder = ReadingOrder(startPage: 1, totalPages: 604);
    const wrappedOrder = ReadingOrder(startPage: 300, totalPages: 604);

    test('jumps to the end of the current section', () {
      final juz1 = QuranSections.get(QuranSectionType.juz, 1);
      expect(
        QuranSections.nextEndAfter(QuranSectionType.juz, 5, mushafOrder),
        juz1.lastPage,
      );
    });

    test('from a section end, jumps to the next section end', () {
      final juz1 = QuranSections.get(QuranSectionType.juz, 1);
      final juz2 = QuranSections.get(QuranSectionType.juz, 2);
      expect(
        QuranSections.nextEndAfter(
          QuranSectionType.juz,
          juz1.lastPage,
          mushafOrder,
        ),
        juz2.lastPage,
      );
    });

    test('stays on the last page of the order when nothing follows', () {
      expect(
        QuranSections.nextEndAfter(QuranSectionType.juz, 604, mushafOrder),
        604,
      );
      expect(
        QuranSections.nextEndAfter(QuranSectionType.surah, 604, mushafOrder),
        604,
      );
    });

    test('follows the wrap of a goal starting mid-mushaf', () {
      final juz1 = QuranSections.get(QuranSectionType.juz, 1);
      final hizb1 = QuranSections.get(QuranSectionType.hizb, 1);
      final fatiha = QuranSections.get(QuranSectionType.surah, 1);
      expect(
        QuranSections.nextEndAfter(QuranSectionType.juz, 604, wrappedOrder),
        juz1.lastPage,
      );
      expect(
        QuranSections.nextEndAfter(QuranSectionType.hizb, 604, wrappedOrder),
        hizb1.lastPage,
      );
      expect(
        QuranSections.nextEndAfter(QuranSectionType.surah, 604, wrappedOrder),
        fatiha.lastPage,
      );
      // The page before the start is the last of the order.
      expect(
        QuranSections.nextEndAfter(QuranSectionType.juz, 299, wrappedOrder),
        299,
      );
    });
  });
}
