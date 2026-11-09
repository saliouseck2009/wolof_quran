import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolof_quran/l10n/generated/app_localizations.dart';
import 'package:wolof_quran/presentation/cubits/quran_settings_cubit.dart';
import 'package:wolof_quran/presentation/widgets/quran_settings/font_size_selector_sheet.dart';
import 'package:wolof_quran/presentation/widgets/quran_settings/reading_tracking_settings_sheet.dart';
import 'package:wolof_quran/presentation/widgets/settings/settings_sheet.dart';

void main() {
  Future<QuranSettingsCubit> pumpOpener(
    WidgetTester tester,
    Future<void> Function(BuildContext) open,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = QuranSettingsCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => open(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('the font size sheet applies the slider right away', (
    tester,
  ) async {
    final cubit = await pumpOpener(tester, showFontSizeSettingsSheet);
    final before = cubit.state.ayahFontSize;

    expect(find.byType(SettingsSheetCard), findsNWidgets(2));
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(cubit.state.ayahFontSize, greaterThan(before));
    expect(find.text('${cubit.state.ayahFontSize.toInt()}pt'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('the reading tracking sheet has no close cross', (
    tester,
  ) async {
    final cubit = await pumpOpener(tester, showReadingTrackingSettingsSheet);

    expect(find.byType(SettingsSheetCard), findsNWidgets(2));
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(cubit.state.autoTrackingEnabled, isFalse);
  });
}
