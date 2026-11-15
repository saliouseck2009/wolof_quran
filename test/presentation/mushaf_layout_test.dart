import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/presentation/widgets/mushaf/mushaf_page_view.dart';

void main() {
  group('MushafLayout', () {
    test('a phone in portrait shows one page filling the viewport', () {
      const viewport = Size(390, 700);
      final layout = MushafLayout.of(viewport);

      expect(layout, MushafLayout.single);
      expect(layout.pageSize(viewport), viewport);
    });

    test('a tablet in portrait shows one page that is not stretched', () {
      const viewport = Size(820, 1000);
      final layout = MushafLayout.of(viewport);

      expect(layout, MushafLayout.single);
      expect(layout.pageSize(viewport), const Size(720, 1000));
    });

    test('a phone in landscape keeps the scrolling page', () {
      const viewport = Size(844, 300);
      final layout = MushafLayout.of(viewport);

      expect(layout, MushafLayout.scrolling);
      expect(layout.pageSize(viewport), const Size(844, 844));
    });

    test('a tablet in landscape shows two facing pages', () {
      const viewport = Size(1180, 660);
      final layout = MushafLayout.of(viewport);
      final page = layout.pageSize(viewport);

      expect(layout, MushafLayout.spread);
      expect(page.height, 660);
      expect(page.width, closeTo(660 * 0.72, 0.001));
      expect(page.width * 2 + MushafPageView.spineWidth, lessThan(1180));
    });

    test('two pages never overflow a narrow landscape window', () {
      const viewport = Size(860, 800);
      final layout = MushafLayout.of(viewport);

      expect(layout, MushafLayout.spread);
      expect(layout.pageSize(viewport).width, (860 - 17) / 2);
    });

    test('maps pages to screens in each layout', () {
      expect(MushafLayout.single.indexOf(6), 5);
      expect(MushafLayout.single.pagesAt(5), [6]);

      expect(MushafLayout.spread.indexOf(1), 0);
      expect(MushafLayout.spread.indexOf(2), 0);
      expect(MushafLayout.spread.indexOf(5), 2);
      expect(MushafLayout.spread.indexOf(6), 2);
      expect(MushafLayout.spread.indexOf(604), 301);
      expect(MushafLayout.spread.pagesAt(2), [5, 6]);
      expect(MushafLayout.spread.pagesAt(301), [603, 604]);
    });
  });

  group('MushafPageView', () {
    Future<void> pumpAt(
      WidgetTester tester,
      Size size,
      MushafViewController controller,
      List<int> changes,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: MushafPageView(
            controller: controller,
            pageBackgroundColor: Colors.white,
            verseColor: Colors.black,
            accentColor: Colors.teal,
            isDark: false,
            isTajweed: false,
            onPageChanged: changes.add,
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('portrait shows the page being read alone', (tester) async {
      final controller = MushafViewController(initialPage: 6);
      addTearDown(controller.dispose);
      await pumpAt(tester, const Size(820, 1100), controller, []);

      expect(controller.page, 6);
      expect(controller.visiblePages, [6]);
      expect(controller.facingPages, isEmpty);
      expect(find.byKey(const ValueKey('mushaf_page_6')), findsOneWidget);
    });

    testWidgets('landscape puts the odd page on the right of its pair', (
      tester,
    ) async {
      final controller = MushafViewController(initialPage: 6);
      addTearDown(controller.dispose);
      await pumpAt(tester, const Size(1180, 700), controller, []);

      // The page being read stays the same; its neighbour joins it.
      expect(controller.page, 6);
      expect(controller.visiblePages, [5, 6]);
      expect(controller.facingPages, [5]);

      final right = tester.getRect(
        find.byKey(const ValueKey('mushaf_page_5')),
      );
      final left = tester.getRect(find.byKey(const ValueKey('mushaf_page_6')));
      expect(right.left, greaterThan(left.right));
      expect(right.width, left.width);
      // The pair is centred around the fold.
      expect(1180 - right.right, closeTo(left.left, 0.001));
    });

    testWidgets('rotating keeps the page being read', (tester) async {
      final controller = MushafViewController(initialPage: 8);
      addTearDown(controller.dispose);
      final changes = <int>[];
      await pumpAt(tester, const Size(820, 1100), controller, changes);
      expect(controller.visiblePages, [8]);

      await pumpAt(tester, const Size(1180, 700), controller, changes);
      expect(controller.page, 8);
      expect(controller.visiblePages, [7, 8]);

      await pumpAt(tester, const Size(820, 1100), controller, changes);
      expect(controller.page, 8);
      expect(controller.visiblePages, [8]);
      expect(find.byKey(const ValueKey('mushaf_page_8')), findsOneWidget);
      expect(changes, isEmpty);
    });

    testWidgets('a swipe turns two pages at once in landscape', (tester) async {
      final controller = MushafViewController(initialPage: 5);
      addTearDown(controller.dispose);
      final changes = <int>[];
      await pumpAt(tester, const Size(1180, 700), controller, changes);

      // Right to left reading: the next spread comes in from the left.
      await tester.fling(find.byType(PageView), const Offset(600, 0), 2000);
      await tester.pumpAndSettle();

      expect(controller.page, 7);
      expect(controller.visiblePages, [7, 8]);
      expect(changes, [7]);
    });

    testWidgets('jumping to a page opens its spread and keeps the target', (
      tester,
    ) async {
      final controller = MushafViewController(initialPage: 1);
      addTearDown(controller.dispose);
      final changes = <int>[];
      await pumpAt(tester, const Size(1180, 700), controller, changes);

      controller.jumpToPage(300);
      await tester.pump();

      expect(controller.page, 300);
      expect(controller.visiblePages, [299, 300]);
      expect(changes, [300]);

      // The facing page of the same spread: no swipe, the page still changes.
      controller.jumpToPage(299);
      await tester.pump();
      expect(controller.page, 299);
      expect(controller.visiblePages, [299, 300]);
    });
  });
}
