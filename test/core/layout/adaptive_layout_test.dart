import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        SliverContentConstraint.sidePadding(390, maxWidth: 1100, margin: 24),
        24,
      );
      expect(
        SliverContentConstraint.sidePadding(820, maxWidth: 1100, margin: 24),
        32,
      );
      expect(SliverContentConstraint.sidePadding(390, maxWidth: 1100), 0);
    });

    test('side padding centres the column on wide windows', () {
      expect(
        SliverContentConstraint.sidePadding(1366, maxWidth: 1100, margin: 24),
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
}
