import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/reading/reading_order.dart';

void main() {
  group('ReadingOrder', () {
    const fromStart = ReadingOrder(startPage: 1, totalPages: 604);
    const wrapped = ReadingOrder(startPage: 300, totalPages: 604);

    test('maps pages to positions from the start page', () {
      expect(fromStart.indexOf(1), 0);
      expect(fromStart.indexOf(604), 603);
      expect(wrapped.indexOf(300), 0);
      expect(wrapped.indexOf(604), 304);
      expect(wrapped.indexOf(1), 305);
      expect(wrapped.indexOf(299), 603);
      for (var page = 1; page <= 604; page++) {
        expect(wrapped.pageAt(wrapped.indexOf(page)), page);
      }
    });

    test('pagesBetween follows the wrapped order', () {
      expect(fromStart.pagesBetween(5, 7), [5, 6, 7]);
      expect(fromStart.pagesBetween(7, 5), isEmpty);
      expect(wrapped.pagesBetween(603, 2), [603, 604, 1, 2]);
      expect(wrapped.pagesBetween(2, 603), isEmpty);
      expect(wrapped.isBefore(604, 1), isTrue);
    });

    test('continuous progress stops at the first gap', () {
      final pages = {1, 2, 3, 5, 6};
      expect(fromStart.continuousProgress(pages), 3);
      expect(fromStart.firstUnvalidatedPage(pages), 4);
      expect(fromStart.pagesReadAhead(pages), [5, 6]);
      expect(fromStart.skippedPages(pages), [4]);
    });

    test('a fully validated goal has no next page', () {
      final all = {for (var p = 1; p <= 604; p++) p};
      expect(fromStart.continuousProgress(all), 604);
      expect(fromStart.firstUnvalidatedPage(all), isNull);
      expect(wrapped.skippedPages(const {}), isEmpty);
    });

    test('wrapped goal continues past the last page', () {
      final pages = {for (var p = 300; p <= 604; p++) p, 1, 2};
      expect(wrapped.continuousProgress(pages), 307);
      expect(wrapped.firstUnvalidatedPage(pages), 3);
    });
  });
}
