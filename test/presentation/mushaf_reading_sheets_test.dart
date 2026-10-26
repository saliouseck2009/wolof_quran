import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/reading/local_date.dart';
import 'package:wolof_quran/domain/entities/reading_goal.dart';
import 'package:wolof_quran/domain/entities/reading_session.dart';
import 'package:wolof_quran/domain/entities/reading_validation.dart';
import 'package:wolof_quran/domain/repositories/reading_goal_repository.dart';
import 'package:wolof_quran/l10n/generated/app_localizations.dart';
import 'package:wolof_quran/presentation/cubits/reading_goals_cubit.dart';
import 'package:wolof_quran/presentation/widgets/mushaf/goal_switcher_sheet.dart';
import 'package:wolof_quran/presentation/widgets/mushaf/mushaf_reading_actions_sheet.dart';

class _FakeRepository implements ReadingGoalRepository {
  final Map<String, ReadingGoal> goals = {};
  final Map<String, Map<int, DateTime>> pages = {};
  String? activeGoalId;

  @override
  Future<List<ReadingGoal>> getGoals() async => goals.values.toList();

  @override
  Future<ReadingGoal?> getGoal(String id) async => goals[id];

  @override
  Future<void> saveGoal(ReadingGoal goal) async => goals[goal.id] = goal;

  @override
  Future<void> deleteGoal(String id) async => goals.remove(id);

  @override
  Future<Map<int, DateTime>> getValidatedPages(String goalId) async =>
      pages[goalId] ?? {};

  @override
  Future<Map<String, Map<int, DateTime>>> getAllValidatedPages() async => pages;

  @override
  Future<ReadingValidation?> validatePages({
    required String goalId,
    required List<int> pages,
    required ReadingValidationSource source,
    required ReadingValidationAction action,
    int? fromPage,
    int? toPage,
  }) async => null;

  @override
  Future<ReadingValidation?> unmarkPages({
    required String goalId,
    required List<int> pages,
  }) async => null;

  @override
  Future<List<ReadingValidation>> getValidations(String goalId) async => [];

  @override
  Future<void> undoValidation(String validationId) async {}

  @override
  Future<void> saveSession(ReadingSession session) async {}

  @override
  Future<List<ReadingSession>> getSessions(String goalId) async => [];

  @override
  Future<List<ReadingSession>> getAllSessions() async => [];

  @override
  Future<String?> getActiveGoalId() async => activeGoalId;

  @override
  Future<void> setActiveGoalId(String? goalId) async => activeGoalId = goalId;
}

void main() {
  const today = LocalDate(2026, 3, 1);
  final now = DateTime(2026, 3, 1, 9);

  ReadingGoal goal(String id, String name) => ReadingGoal(
    id: id,
    name: name,
    status: ReadingGoalStatus.active,
    startPage: 1,
    totalPages: 604,
    startDate: today,
    endDate: today.addDays(29),
    lastViewedPage: 42,
    createdAt: now,
    updatedAt: now,
  );

  Future<ReadingGoalsCubit> cubitWith(_FakeRepository repository) async {
    final cubit = ReadingGoalsCubit(
      repository: repository,
      today: () => today,
      totalPages: 604,
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  /// Pumps a page whose "open" button runs [open] and keeps its result.
  Future<_SheetResult<T>> pumpOpener<T>(
    WidgetTester tester,
    ReadingGoalsCubit cubit,
    Future<T?> Function(BuildContext context) open,
  ) async {
    final result = _SheetResult<T>();
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result.value = await open(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  group('MushafReadingActionsSheet', () {
    testWidgets('offers goal actions when a goal is followed', (tester) async {
      final repository = _FakeRepository()
        ..goals['g1'] = goal('g1', 'Khatm Ramadan')
        ..pages['g1'] = {10: now}
        ..activeGoalId = 'g1';
      final cubit = await cubitWith(repository);

      final result = await pumpOpener(
        tester,
        cubit,
        (context) => showMushafReadingActionsSheet(context, currentPage: 10),
      );

      expect(find.text('Khatm Ramadan'), findsOneWidget);
      expect(find.text('Retirer la validation de cette page'), findsOneWidget);
      expect(find.text("J'ai lu jusqu'ici"), findsOneWidget);
      expect(find.text('Passer en lecture libre'), findsOneWidget);
      expect(find.text('Suivre un objectif'), findsNothing);

      await tester.tap(find.text("J'ai lu jusqu'ici"));
      await tester.pumpAndSettle();
      expect(result.value, MushafReadingAction.readUntilHere);
    });

    testWidgets('offers ways to follow a goal in free reading', (tester) async {
      final repository = _FakeRepository()..goals['g1'] = goal('g1', 'Khatm');
      final cubit = await cubitWith(repository);

      final result = await pumpOpener(
        tester,
        cubit,
        (context) => showMushafReadingActionsSheet(context, currentPage: 10),
      );

      expect(find.text('Lecture libre'), findsOneWidget);
      expect(find.text('Suivre un objectif'), findsOneWidget);
      expect(find.text('Marquer cette page comme lue'), findsNothing);

      await tester.tap(find.text('Suivre un objectif'));
      await tester.pumpAndSettle();
      expect(result.value, MushafReadingAction.followGoal);
    });
  });

  group('GoalSwitcherSheet', () {
    testWidgets('returns the goal with its last viewed page', (tester) async {
      final repository = _FakeRepository()
        ..goals['g1'] = goal('g1', 'Khatm A')
        ..goals['g2'] = goal('g2', 'Khatm B');
      final cubit = await cubitWith(repository);

      final result = await pumpOpener(tester, cubit, showGoalSwitcherSheet);

      expect(find.text('Lecture libre'), findsOneWidget);
      await tester.tap(find.text('Khatm B'));
      await tester.pumpAndSettle();

      final choice = result.value;
      expect(choice!.goalId, 'g2');
      expect(choice.page, 42);
    });

    testWidgets('returns free reading', (tester) async {
      final repository = _FakeRepository()
        ..goals['g1'] = goal('g1', 'Khatm A')
        ..activeGoalId = 'g1';
      final cubit = await cubitWith(repository);

      final result = await pumpOpener(tester, cubit, showGoalSwitcherSheet);
      await tester.tap(find.text('Lecture libre'));
      await tester.pumpAndSettle();

      final choice = result.value;
      expect(choice!.isFreeReading, isTrue);
    });
  });
}

class _SheetResult<T> {
  T? value;
}
