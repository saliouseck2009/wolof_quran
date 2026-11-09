import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolof_quran/l10n/generated/app_localizations.dart';
import 'package:wolof_quran/presentation/cubits/language_cubit.dart';
import 'package:wolof_quran/presentation/cubits/theme_cubit.dart';
import 'package:wolof_quran/presentation/views/settings_page.dart';
import 'package:wolof_quran/presentation/widgets/settings/settings_choice_menu_item.dart';
import 'package:wolof_quran/presentation/widgets/settings/settings_menu_item.dart';

void main() {
  group('SettingsChoiceMenuItem', () {
    Future<List<String>> pumpItem(
      WidgetTester tester, {
      TextDirection direction = TextDirection.ltr,
      bool fullWidthMenu = false,
    }) async {
      final picked = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SettingsChoiceMenuItem<String>(
                      icon: Icons.language,
                      title: 'Langue',
                      subtitle: "Changer la langue de l'application",
                      value: 'Français',
                      selected: 'fr',
                      choices: const [
                        SettingsChoice(value: 'fr', label: 'Français'),
                        SettingsChoice(
                          value: 'en',
                          label: 'English',
                          secondary: 'Anglais',
                        ),
                        SettingsChoice(
                          value: 'ar',
                          label: 'العربية',
                          secondary: 'Arabe',
                        ),
                      ],
                      onSelected: picked.add,
                      fullWidthMenu: fullWidthMenu,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return picked;
    }

    Rect menuRect(WidgetTester tester) {
      final items = find.byType(MenuItemButton);
      return tester
          .getRect(items.first)
          .expandToInclude(tester.getRect(items.last))
          .inflate(6); // the menu padding
    }

    testWidgets('opens under the row, aligned on its end edge', (
      tester,
    ) async {
      await pumpItem(tester);
      await tester.tap(find.text('Langue'));
      await tester.pumpAndSettle();

      final row = tester.getRect(find.byType(SettingsMenuItem));
      final menu = menuRect(tester);
      expect(find.byType(MenuItemButton), findsNWidgets(3));
      expect(menu.width, SettingsChoiceMenuItem.menuWidth);
      expect(menu.right, moreOrLessEquals(row.right));
      expect(menu.top, moreOrLessEquals(row.bottom - 12));
    });

    testWidgets('aligns on the left edge in right-to-left', (tester) async {
      await pumpItem(tester, direction: TextDirection.rtl);
      await tester.tap(find.text('Langue'));
      await tester.pumpAndSettle();

      final row = tester.getRect(find.byType(SettingsMenuItem));
      expect(menuRect(tester).left, moreOrLessEquals(row.left));
    });

    testWidgets('a full-width menu spans the row', (tester) async {
      await pumpItem(tester, fullWidthMenu: true);
      await tester.tap(find.text('Langue'));
      await tester.pumpAndSettle();

      final row = tester.getRect(find.byType(SettingsMenuItem));
      final menu = menuRect(tester);
      expect(menu.left, moreOrLessEquals(row.left));
      expect(menu.right, moreOrLessEquals(row.right));
    });

    testWidgets('checks the current choice and shows the others names', (
      tester,
    ) async {
      await pumpItem(tester);
      await tester.tap(find.text('Langue'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(MenuItemButton, 'Français'),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(find.text('Anglais'), findsOneWidget);
      expect(find.text('Arabe'), findsOneWidget);
    });

    testWidgets('picking a choice reports it and closes the menu', (
      tester,
    ) async {
      final picked = await pumpItem(tester);
      await tester.tap(find.text('Langue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(picked, ['en']);
      expect(find.byType(MenuItemButton), findsNothing);
    });
  });

  group('SettingsPage', () {
    Future<(LanguageCubit, ThemeCubit)> pumpPage(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final languageCubit = LanguageCubit();
      final themeCubit = ThemeCubit();
      addTearDown(languageCubit.close);
      addTearDown(themeCubit.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: languageCubit),
            BlocProvider.value(value: themeCubit),
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
            home: const SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (languageCubit, themeCubit);
    }

    testWidgets('the theme menu changes the theme', (tester) async {
      final (_, themeCubit) = await pumpPage(tester);

      await tester.tap(find.text('Thème'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      await tester.tap(find.widgetWithText(MenuItemButton, 'Sombre'));
      await tester.pumpAndSettle();

      expect(themeCubit.state, ThemeMode.dark);
      expect(find.byType(MenuItemButton), findsNothing);
      expect(find.text('Sombre'), findsOneWidget); // the row value
    });

    testWidgets('the language menu changes the language', (tester) async {
      final (languageCubit, _) = await pumpPage(tester);

      await tester.tap(find.text('Langue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(languageCubit.state.languageCode, 'en');
    });

    testWidgets('the menu fits with enlarged text', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpPage(tester);
      await tester.tap(find.text('Langue'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MenuItemButton), findsNWidgets(3));
    });
  });
}
