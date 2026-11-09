import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wolof_quran/core/navigation/surah_detail_arguments.dart';
import 'package:wolof_quran/domain/repositories/bookmark_repository.dart';
import 'package:wolof_quran/l10n/generated/app_localizations.dart';
import 'package:wolof_quran/presentation/cubits/bookmark_cubit.dart';
import 'package:wolof_quran/presentation/cubits/daily_inspiration_cubit.dart';
import 'package:wolof_quran/presentation/cubits/quran_settings_cubit.dart';
import 'package:wolof_quran/presentation/widgets/daily_inspiration_card.dart';

class _FixedVerseCubit extends DailyInspirationCubit {
  void show(DailyInspirationState state) => emit(state);
}

class _NoBookmarks extends Fake implements BookmarkRepository {}

void main() {
  final verse = DailyInspirationLoaded(
    surahNumber: 50,
    verseNumber: 27,
    arabicText: quran.getVerse(50, 27),
    translation: quran.getVerseTranslation(
      50,
      27,
      translation: quran.Translation.frHamidullah,
    ),
    surahName: quran.getSurahName(50),
    currentTranslation: quran.Translation.frHamidullah,
    isExpanded: false,
  );

  Future<_FixedVerseCubit> pumpCard(WidgetTester tester) async {
    final verseCubit = _FixedVerseCubit();
    final settingsCubit = QuranSettingsCubit();
    final bookmarkCubit = BookmarkCubit(_NoBookmarks());
    addTearDown(verseCubit.close);
    addTearDown(settingsCubit.close);
    addTearDown(bookmarkCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DailyInspirationCubit>.value(value: verseCubit),
          BlocProvider.value(value: settingsCubit),
          BlocProvider.value(value: bookmarkCubit),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routes: {
            '/surah-detail': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as SurahDetailArguments;
              return Scaffold(
                body: Text(
                  'surah ${args.surahNumber}:${args.initialAyahNumber}',
                ),
              );
            },
          },
          home: const Scaffold(
            body: SingleChildScrollView(child: DailyInspirationCard()),
          ),
        ),
      ),
    );
    return verseCubit;
  }

  testWidgets('shows the verse with its reference and actions', (
    tester,
  ) async {
    final cubit = await pumpCard(tester);
    cubit.show(verse);
    await tester.pumpAndSettle();

    expect(find.text('Verset du jour'), findsOneWidget);
    expect(find.text('${verse.surahName} · 27'), findsOneWidget);
    expect(find.text(verse.arabicText), findsOneWidget);
    expect(find.text(verse.translation), findsOneWidget);
    expect(find.text('Écouter'), findsOneWidget);
    expect(find.byTooltip('Autre verset'), findsOneWidget);
    expect(find.byTooltip('Marquer'), findsOneWidget);
    expect(find.byTooltip('Ouvrir la sourate'), findsOneWidget);
  });

  testWidgets('only the open icon leads to the surah, not the card', (
    tester,
  ) async {
    final cubit = await pumpCard(tester);
    cubit.show(verse);
    await tester.pumpAndSettle();

    await tester.tap(find.text(verse.translation));
    await tester.pumpAndSettle();
    expect(find.text('surah 50:27'), findsNothing);

    await tester.tap(find.byTooltip('Ouvrir la sourate'));
    await tester.pumpAndSettle();
    expect(find.text('surah 50:27'), findsOneWidget);
  });

  testWidgets('the footer fits with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final cubit = await pumpCard(tester);
    cubit.show(verse);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Ouvrir la sourate'), findsOneWidget);
  });

  testWidgets('the initial card draws a verse when tapped', (tester) async {
    final cubit = await pumpCard(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verset du jour'));
    await tester.pumpAndSettle();

    expect(cubit.state, isA<DailyInspirationLoaded>());
  });
}
