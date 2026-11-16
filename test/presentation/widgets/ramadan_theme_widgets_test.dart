import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/config/seasonal_theme_config.dart';
import 'package:wolof_quran/core/config/theme/seasonal_theme.dart';
import 'package:wolof_quran/core/config/theme/theme.dart';
import 'package:wolof_quran/l10n/generated/app_localizations.dart';
import 'package:wolof_quran/presentation/cubits/seasonal_theme_cubit.dart';
import 'package:wolof_quran/presentation/widgets/app_loader.dart';
import 'package:wolof_quran/presentation/widgets/seasonal/night_sky.dart';
import 'package:wolof_quran/presentation/widgets/seasonal/ramadan_loader.dart';
import 'package:wolof_quran/presentation/widgets/seasonal/ramadan_banner.dart';
import 'package:wolof_quran/presentation/widgets/settings/seasonal_theme_settings_item.dart';

import '../../support/fake_seasonal_theme_repository.dart';

/// An app whose theme follows [cubit], like the real one.
Widget _app({
  required SeasonalThemeCubit cubit,
  required Widget child,
  Locale locale = const Locale('fr'),
}) {
  return BlocProvider.value(
    value: cubit,
    child: BlocBuilder<SeasonalThemeCubit, SeasonalThemeState>(
      builder: (context, state) => MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: MaterialTheme(season: state.active).light(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  late FakeSeasonalThemeRepository repository;

  SeasonalThemeCubit createCubit({
    SeasonalThemeConfig config = FakeSeasonalThemeRepository.ramadanOn,
  }) {
    repository = FakeSeasonalThemeRepository(config: config);
    final cubit = SeasonalThemeCubit(repository: repository);
    addTearDown(cubit.close);
    return cubit;
  }

  group('RamadanBanner', () {
    testWidgets('greets during Ramadan', (tester) async {
      await tester.pumpWidget(
        _app(cubit: createCubit(), child: const RamadanBanner()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ramadan Moubarak'), findsOneWidget);
      expect(find.text('Le mois du Coran'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Ramadan Moubarak. Le mois du Coran'),
        findsOneWidget,
      );
    });

    testWidgets('takes no room out of season', (tester) async {
      await tester.pumpWidget(
        _app(
          cubit: createCubit(config: SeasonalThemeConfig.disabled),
          child: const RamadanBanner(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ramadan Moubarak'), findsNothing);
      expect(tester.getSize(find.byType(RamadanBanner)).height, 0);
    });

    testWidgets('appears and leaves with the remote switch', (tester) async {
      final cubit = createCubit(config: SeasonalThemeConfig.disabled);
      await tester.pumpWidget(_app(cubit: cubit, child: const RamadanBanner()));
      await tester.pumpAndSettle();
      expect(find.text('Ramadan Moubarak'), findsNothing);

      repository.push(FakeSeasonalThemeRepository.ramadanOn);
      await tester.pumpAndSettle();
      expect(find.text('Ramadan Moubarak'), findsOneWidget);

      repository.push(SeasonalThemeConfig.disabled);
      await tester.pumpAndSettle();
      expect(find.text('Ramadan Moubarak'), findsNothing);
    });

    testWidgets('fits a small phone with enlarged text, in Arabic too', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final locale in const [Locale('fr'), Locale('en'), Locale('ar')]) {
        await tester.pumpWidget(
          _app(
            cubit: createCubit(),
            locale: locale,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: RamadanBanner(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group('SeasonalThemeSettingsItem', () {
    testWidgets('is hidden out of season', (tester) async {
      await tester.pumpWidget(
        _app(
          cubit: createCubit(config: SeasonalThemeConfig.disabled),
          child: const SeasonalThemeSettingsItem(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thème Ramadan'), findsNothing);
      expect(tester.getSize(find.byType(SeasonalThemeSettingsItem)).height, 0);
    });

    testWidgets('lets the user leave and come back to the Ramadan look', (
      tester,
    ) async {
      final cubit = createCubit();
      await tester.pumpWidget(
        _app(cubit: cubit, child: const SeasonalThemeSettingsItem()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Activé'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(
        SeasonalTheme.of(tester.element(find.byType(Scaffold))),
        SeasonalTheme.ramadan,
      );

      await tester.tap(find.text('Thème Ramadan'));
      await tester.pumpAndSettle();

      expect(cubit.state.active, SeasonalTheme.none);
      expect(repository.disabledByUser, {SeasonalTheme.ramadan});
      // The standard theme is back, the switch stays to come back.
      expect(
        SeasonalTheme.of(tester.element(find.byType(Scaffold))),
        SeasonalTheme.none,
      );
      expect(find.text('Désactivé'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

      // A tap on the switch goes through it to the row, which toggles.
      await tester.tap(find.byType(Switch), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(cubit.state.active, SeasonalTheme.ramadan);
      expect(repository.disabledByUser, isEmpty);
    });
  });

  group('AppLoader', () {
    Widget themed(SeasonalTheme season, Widget child) => MaterialApp(
      theme: MaterialTheme(season: season).light(),
      home: Scaffold(body: Center(child: child)),
    );

    testWidgets('is the standard spinner out of season', (tester) async {
      await tester.pumpWidget(
        themed(
          SeasonalTheme.none,
          const AppLoader(size: 20, strokeWidth: 2, color: Colors.red),
        ),
      );

      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(spinner.strokeWidth, 2);
      expect(spinner.color, Colors.red);
      expect(tester.getSize(find.byType(CircularProgressIndicator)).width, 20);
      expect(find.byType(RamadanLoader), findsNothing);
    });

    testWidgets('becomes the crescent during Ramadan and keeps moving', (
      tester,
    ) async {
      await tester.pumpWidget(themed(SeasonalTheme.ramadan, const AppLoader()));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.getSize(find.byType(RamadanLoader)).width,
        RamadanLoader.defaultSize,
      );
      expect(tester.hasRunningAnimations, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a small loader stays large enough to be read', (tester) async {
      await tester.pumpWidget(
        themed(SeasonalTheme.ramadan, const AppLoader(size: 20)),
      );

      expect(tester.getSize(find.byType(RamadanLoader)).width, 28);
    });

    testWidgets('stays still when the system turns animations off', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: themed(SeasonalTheme.ramadan, const AppLoader()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(RamadanLoader), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('seasonal sky', () {
    Future<BuildContext> pumpBar(
      WidgetTester tester,
      SeasonalTheme season,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MaterialTheme(season: season).light(),
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Sourates'),
              flexibleSpace: const SeasonalSky(),
            ),
          ),
        ),
      );
      return tester.element(find.byType(SeasonalSky));
    }

    testWidgets('leaves the headers as they are out of season', (tester) async {
      final context = await pumpBar(tester, SeasonalTheme.none);
      const base = BoxDecoration(color: Colors.teal);

      expect(seasonalSky(context, base), same(base));
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
    });

    testWidgets('scatters stars behind the headers during Ramadan', (
      tester,
    ) async {
      final context = await pumpBar(tester, SeasonalTheme.ramadan);
      const base = BoxDecoration(color: Colors.indigo);

      final decoration = seasonalSky(context, base);
      expect(decoration, isA<NightSkyDecoration>());
      expect((decoration as NightSkyDecoration).base, same(base));
      // Same bar, the title stays in front of the sky.
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
      expect(find.text('Sourates'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
