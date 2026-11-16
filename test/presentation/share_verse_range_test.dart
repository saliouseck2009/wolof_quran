import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wolof_quran/l10n/generated/app_localizations.dart';
import 'package:wolof_quran/presentation/widgets/daily_inspiration_share_modal.dart';

const _translation = quran.Translation.frHamidullah;

String _arabic(int surah, int verse) =>
    quran.getVerse(surah, verse, verseEndSymbol: false);

String _french(int surah, int verse) =>
    quran.getVerseTranslation(surah, verse, translation: _translation);

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required int surah,
    required int verse,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
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
        home: Scaffold(
          body: DailyInspirationShareModal(
            verseNumber: verse,
            arabicText: surah == 0 ? 'نص' : _arabic(surah, verse),
            translation: surah == 0 ? 'Texte' : _french(surah, verse),
            translationSource: 'Hamidullah',
            surahName: surah == 0 ? '' : quran.getSurahName(surah),
            surahNumber: surah,
            translationId: _translation,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pick(WidgetTester tester, String dropdown, int verse) async {
    final finder = find.byKey(ValueKey(dropdown));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('$verse').last);
    await tester.pumpAndSettle();
  }

  String summary(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const ValueKey('share-range-summary')))
      .data!;

  testWidgets('opens on the single verse it was asked for', (tester) async {
    await pumpSheet(tester, surah: 1, verse: 2);

    expect(find.text('Versets'), findsOneWidget);
    expect(summary(tester), '1 verset');
    expect(find.byKey(const ValueKey('share-preview-next')), findsNothing);
    expect(find.text(_french(1, 2)), findsOneWidget);
  });

  testWidgets('a longer range gets one card per verse', (tester) async {
    await pumpSheet(tester, surah: 1, verse: 2);

    await pick(tester, 'share-range-last', 4);

    expect(summary(tester), '3 versets');
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text(_french(1, 2)), findsOneWidget);

    final next = find.byKey(const ValueKey('share-preview-next'));
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text(_french(1, 3)), findsOneWidget);
    expect(find.text(_arabic(1, 3)), findsOneWidget);
    expect(find.text(_french(1, 2)), findsNothing);
    expect(find.textContaining('(1): 3'), findsOneWidget);
  });

  testWidgets('the pager stops at both ends of the range', (tester) async {
    await pumpSheet(tester, surah: 1, verse: 2);
    await pick(tester, 'share-range-last', 3);

    IconButton button(String key) =>
        tester.widget<IconButton>(find.byKey(ValueKey(key)));

    expect(button('share-preview-previous').onPressed, isNull);
    expect(button('share-preview-next').onPressed, isNotNull);

    final next = find.byKey(const ValueKey('share-preview-next'));
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(button('share-preview-previous').onPressed, isNotNull);
    expect(button('share-preview-next').onPressed, isNull);
  });

  testWidgets('moving the start past the end drags the end along', (
    tester,
  ) async {
    await pumpSheet(tester, surah: 1, verse: 2);
    await pick(tester, 'share-range-last', 3);

    await pick(tester, 'share-range-first', 5);

    expect(summary(tester), '1 verset');
    expect(find.text(_french(1, 5)), findsOneWidget);
    expect(find.byKey(const ValueKey('share-preview-next')), findsNothing);
  });

  testWidgets('a range never holds more than twenty verses', (tester) async {
    await pumpSheet(tester, surah: 2, verse: 1);
    await pick(tester, 'share-range-last', 6);

    // The end offers the verses from the start up to the limit only.
    final last = tester.widget<DropdownButton<int>>(
      find.byKey(const ValueKey('share-range-last')),
    );
    expect(last.items!.first.value, 1);
    expect(last.items!.last.value, 20);
  });

  testWidgets('no range to pick without a real surah', (tester) async {
    await pumpSheet(tester, surah: 0, verse: 0);

    expect(find.text('Versets'), findsNothing);
    expect(find.byKey(const ValueKey('share-range-first')), findsNothing);
    expect(find.text('Texte'), findsOneWidget);
  });

  testWidgets('fits a tablet without overflowing', (tester) async {
    await pumpSheet(tester, surah: 1, verse: 2, size: const Size(1024, 1366));
    await pick(tester, 'share-range-last', 4);

    expect(tester.takeException(), isNull);
    expect(find.text('1 / 3'), findsOneWidget);
  });
}
