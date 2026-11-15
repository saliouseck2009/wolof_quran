import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/layout/adaptive_list.dart';
import 'package:wolof_quran/core/layout/breakpoints.dart';
import 'package:wolof_quran/core/layout/content_constraint.dart';

void main() {
  group('WindowSizeClass', () {
    test('follows the Material 3 width breakpoints', () {
      expect(WindowSizeClass.fromWidth(390), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(599.9), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(839.9), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1366), WindowSizeClass.expanded);
    });

    test('only compact is not wide', () {
      expect(WindowSizeClass.compact.isWide, isFalse);
      expect(WindowSizeClass.medium.isWide, isTrue);
      expect(WindowSizeClass.expanded.isWide, isTrue);
    });
  });

  group('pageMarginFor', () {
    test('keeps the phone margin on a compact window', () {
      expect(pageMarginFor(390), 24);
      expect(pageMarginFor(390, compact: 16), 16);
    });

    test('grows with the window and never shrinks a larger margin', () {
      expect(pageMarginFor(700, compact: 16), 32);
      expect(pageMarginFor(1100, compact: 16), 48);
      expect(pageMarginFor(700, compact: 40), 40);
    });
  });

  group('ContentConstraint', () {
    Future<Size> pumpAt(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ContentConstraint(
            maxWidth: 640,
            child: SizedBox(
              key: Key('content'),
              width: double.infinity,
              height: 100,
            ),
          ),
        ),
      );
      return tester.getSize(find.byKey(const Key('content')));
    }

    testWidgets('fills a phone window', (tester) async {
      expect((await pumpAt(tester, 390)).width, 390);
    });

    testWidgets('centres a capped column on a tablet', (tester) async {
      expect((await pumpAt(tester, 1180)).width, 640);
      final rect = tester.getRect(find.byKey(const Key('content')));
      expect(rect.left, (1180 - 640) / 2);
      expect(rect.top, 0);
    });
  });

  group('SliverContentConstraint', () {
    test('side padding keeps the page margin on narrow windows', () {
      expect(
        contentSidePadding(390, maxWidth: 1100, margin: 24),
        24,
      );
      expect(
        contentSidePadding(820, maxWidth: 1100, margin: 24),
        32,
      );
      expect(contentSidePadding(390, maxWidth: 1100), 0);
    });

    test('side padding centres the column on wide windows', () {
      expect(
        contentSidePadding(1366, maxWidth: 1100, margin: 24),
        133,
      );
    });

    testWidgets('lays its sliver out at the capped width', (tester) async {
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: [
              SliverContentConstraint(
                margin: 24,
                sliver: SliverToBoxAdapter(
                  child: SizedBox(key: Key('content'), height: 100),
                ),
              ),
            ],
          ),
        ),
      );
      final rect = tester.getRect(find.byKey(const Key('content')));
      expect(rect.width, 1100);
      expect(rect.left, 133);
    });
  });

  group('AdaptiveColumns', () {
    test('fits as many columns as the minimum item width allows', () {
      expect(AdaptiveColumns.count(358), 1);
      expect(AdaptiveColumns.count(691), 1);
      expect(AdaptiveColumns.count(692), 2);
      expect(AdaptiveColumns.count(756), 2);
      expect(AdaptiveColumns.count(1084), 3);
      expect(AdaptiveColumns.count(2000), 3);
      expect(AdaptiveColumns.count(2000, maxColumns: 2), 2);
    });

    test('counts the rows, the last one possibly incomplete', () {
      expect(AdaptiveColumns.rowCount(114, 1), 114);
      expect(AdaptiveColumns.rowCount(114, 2), 57);
      expect(AdaptiveColumns.rowCount(114, 3), 38);
      expect(AdaptiveColumns.rowCount(7, 3), 3);
      expect(AdaptiveColumns.rowCount(0, 3), 0);
    });
  });

  group('AdaptiveListView', () {
    Future<void> pumpList(
      WidgetTester tester,
      double width, {
      int maxColumns = 3,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AdaptiveListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            maxColumns: maxColumns,
            itemCount: 5,
            itemBuilder: (context, index) =>
                SizedBox(key: Key('item$index'), height: 50),
          ),
        ),
      );
    }

    Rect item(WidgetTester tester, int index) =>
        tester.getRect(find.byKey(Key('item$index')));

    testWidgets('is a plain one-column list on a phone', (tester) async {
      await pumpList(tester, 390);
      expect(item(tester, 0), const Rect.fromLTWH(16, 8, 358, 50));
      expect(item(tester, 1), const Rect.fromLTWH(16, 58, 358, 50));
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('fills rows in reading order on a tablet', (tester) async {
      await pumpList(tester, 820);
      // 32 of margin on a medium window, two columns 12 apart.
      expect(item(tester, 0), const Rect.fromLTWH(32, 8, 372, 50));
      expect(item(tester, 1), const Rect.fromLTWH(416, 8, 372, 50));
      expect(item(tester, 2), const Rect.fromLTWH(32, 58, 372, 50));
      expect(item(tester, 4).left, 32);
    });

    testWidgets('caps and centres its content on a very wide window', (
      tester,
    ) async {
      await pumpList(tester, 1366);
      expect(item(tester, 0).left, 133);
      expect(item(tester, 2).right, 1366 - 133);
      expect(item(tester, 3).top, 58);
    });

    testWidgets('stays one column when asked to', (tester) async {
      await pumpList(tester, 1366, maxColumns: 1);
      expect(item(tester, 0).width, 1100);
      expect(item(tester, 1).top, 58);
    });
  });
}
