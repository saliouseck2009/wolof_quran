import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/config/theme/theme.dart';
import 'package:wolof_quran/presentation/widgets/snackbar.dart';

Future<BuildContext> _pumpApp(WidgetTester tester, {bool dark = false}) async {
  late BuildContext pageContext;
  await tester.pumpWidget(
    MaterialApp(
      theme: const MaterialTheme().light(),
      darkTheme: const MaterialTheme().dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            pageContext = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return pageContext;
}

void main() {
  testWidgets('a toast shows up, then goes away after its duration', (
    tester,
  ) async {
    final context = await _pumpApp(tester);
    CustomSnackbar.showSnackbar(context, 'Signet ajouté', duration: 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Signet ajouté'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Signet ajouté'), findsNothing);
  });

  testWidgets('the action button runs the callback and closes the toast', (
    tester,
  ) async {
    final context = await _pumpApp(tester);
    var undone = false;
    CustomSnackbar.showSnackbarAction(
      context,
      '2 pages validées',
      () => undone = true,
      actionLabel: 'Annuler',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Annuler'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(undone, isTrue);
    expect(find.text('2 pages validées'), findsNothing);
  });

  testWidgets('a new toast replaces the one on screen', (tester) async {
    final context = await _pumpApp(tester);
    CustomSnackbar.showSnackbar(context, 'Premier');
    await tester.pump();
    CustomSnackbar.showErrorSnackbar(context, 'Second');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Premier'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('toasts use the theme colours', (tester) async {
    final context = await _pumpApp(tester, dark: true);
    CustomSnackbar.showErrorSnackbar(context, 'Téléchargement impossible');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final card = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('Téléchargement impossible'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = card.decoration as BoxDecoration;
    expect(
      decoration.color,
      const MaterialTheme().dark().colorScheme.surfaceContainerHighest,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
