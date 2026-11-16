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
            translation: surah == 0 ? 'Sans sourate' : _french(surah, verse),
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

  Future<void> openTool(WidgetTester tester, String tool) async {
    final tray = find.byKey(ValueKey('share-tray-$tool'));
    if (tray.evaluate().isNotEmpty) return;
    await tester.tap(find.byKey(ValueKey('share-tool-$tool')));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String dropdown, int verse) async {
    await openTool(tester, 'verses');
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
    expect(find.text('Verset 2'), findsOneWidget);
    await openTool(tester, 'verses');
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
    expect(find.textContaining('· 1:3'), findsOneWidget);
    expect(find.text('Verset 3'), findsOneWidget);
    expect(find.text('2–4'), findsOneWidget);
    expect(find.bySemanticsLabel('Versets 2–4'), findsOneWidget);
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
    expect(find.byKey(const ValueKey('share-tool-verses')), findsNothing);
    expect(find.byKey(const ValueKey('share-range-first')), findsNothing);
    expect(find.text('Sans sourate'), findsOneWidget);
  });

  testWidgets('the share buttons are in reach as soon as the sheet opens', (
    tester,
  ) async {
    await pumpSheet(tester, surah: 1, verse: 2);

    final sheet = tester.getRect(find.byType(DailyInspirationShareModal));
    for (final label in ['Image', 'Vidéo']) {
      final button = tester.getRect(find.text(label));
      expect(sheet.contains(button.topLeft), isTrue, reason: label);
      expect(sheet.contains(button.bottomRight), isTrue, reason: label);
    }
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('a tool opens its options and closes them again', (tester) async {
    await pumpSheet(tester, surah: 1, verse: 2);
    expect(find.byKey(const ValueKey('share-tray-text')), findsNothing);

    await openTool(tester, 'text');
    expect(find.byKey(const ValueKey('share-tray-text')), findsOneWidget);

    // Another tool takes its place.
    await openTool(tester, 'background');
    expect(find.byKey(const ValueKey('share-tray-text')), findsNothing);
    expect(find.byKey(const ValueKey('share-tray-background')), findsOneWidget);

    // The same tool again closes it.
    await tester.tap(find.byKey(const ValueKey('share-tool-background')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('share-tray-background')), findsNothing);
  });

  testWidgets('the text tool picks what the card shows', (tester) async {
    await pumpSheet(tester, surah: 1, verse: 2);
    expect(find.text(_arabic(1, 2)), findsOneWidget);
    expect(find.text(_french(1, 2)), findsOneWidget);

    await openTool(tester, 'text');
    await tester.tap(find.byKey(const ValueKey('share-mode-arabicOnly')));
    await tester.pumpAndSettle();
    expect(find.text(_arabic(1, 2)), findsOneWidget);
    expect(find.text(_french(1, 2)), findsNothing);

    await tester.tap(find.byKey(const ValueKey('share-mode-translationOnly')));
    await tester.pumpAndSettle();
    expect(find.text(_arabic(1, 2)), findsNothing);
    expect(find.text(_french(1, 2)), findsOneWidget);
  });

  testWidgets('the background tool names the background it sets', (
    tester,
  ) async {
    await pumpSheet(tester, surah: 1, verse: 2);
    await openTool(tester, 'background');
    expect(find.text('Fond · Ivoire'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('share-background-5')));
    await tester.pumpAndSettle();

    expect(find.text('Fond · Vert profond'), findsOneWidget);
    final card = tester.widget<Container>(
      find.byKey(const ValueKey('share-card')),
    );
    expect(card.color, const Color(0xFF004A41));
  });

  testWidgets('the card keeps the size of the shared image on any screen', (
    tester,
  ) async {
    for (final size in const [Size(390, 844), Size(1024, 1366)]) {
      await pumpSheet(tester, surah: 1, verse: 2, size: size);
      final card = tester.renderObject<RenderBox>(
        find.descendant(
          of: find.byType(FittedBox),
          matching: find.byType(RepaintBoundary),
        ),
      );
      expect(card.size, const Size(360, 640), reason: '$size');
    }
  });

  testWidgets('fits a tablet without overflowing', (tester) async {
    await pumpSheet(tester, surah: 1, verse: 2, size: const Size(1024, 1366));
    await pick(tester, 'share-range-last', 4);

    expect(tester.takeException(), isNull);
    expect(find.text('1 / 3'), findsOneWidget);
  });
}
