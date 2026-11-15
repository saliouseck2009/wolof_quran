import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/l10n/generated/app_localizations.dart';
import 'package:wolof_quran/presentation/widgets/home_actions_grid.dart';

void main() {
  Future<void> pumpGrid(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: SingleChildScrollView(child: HomeActionsGrid(ongoingGoals: 2)),
        ),
      ),
    );
  }

  Rect tile(WidgetTester tester, String title) => tester.getRect(
    find.ancestor(of: find.text(title), matching: find.byType(InkWell)),
  );

  testWidgets('a phone width keeps the two-column mosaic', (tester) async {
    await pumpGrid(tester, 342);

    final surahs = tile(tester, 'Sourates');
    final mushaf = tile(tester, 'Mushaf');
    final recitation = tile(tester, 'Lecteur audio');
    final goals = tile(tester, 'Mes objectifs');
    final bookmarks = tile(tester, 'Signets');

    expect(surahs.width, 165);
    expect(surahs.height, 220);
    // Two tiles stacked beside the featured one, the rest two per row.
    expect(mushaf.left, surahs.right + 12);
    expect(recitation.top, mushaf.bottom + 12);
    expect(recitation.bottom, surahs.bottom);
    expect(goals.top, surahs.bottom + 12);
    expect(goals.left, 0);
    expect(bookmarks.top, goals.top);
    expect(bookmarks.right, 342);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tablet width shows three columns of equal tiles', (
    tester,
  ) async {
    await pumpGrid(tester, 756);

    final surahs = tile(tester, 'Sourates');
    final mushaf = tile(tester, 'Mushaf');
    final recitation = tile(tester, 'Lecteur audio');
    final goals = tile(tester, 'Mes objectifs');
    final bookmarks = tile(tester, 'Signets');

    expect(surahs.width, 244);
    expect(surahs.height, 220);
    // The four other entries form a 2 × 2 block beside the featured tile.
    for (final rect in [mushaf, recitation, goals, bookmarks]) {
      expect(rect.width, 244);
      expect(rect.height, 104);
    }
    expect(mushaf.left, surahs.right + 12);
    expect(recitation.left, mushaf.right + 12);
    expect(recitation.top, mushaf.top);
    expect(goals.left, mushaf.left);
    expect(goals.top, mushaf.bottom + 12);
    expect(bookmarks.left, recitation.left);
    expect(bookmarks.bottom, surahs.bottom);
    expect(tester.takeException(), isNull);
  });
}
