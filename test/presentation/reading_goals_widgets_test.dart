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
import 'package:wolof_quran/presentation/views/reading_goals_page.dart';
import 'package:wolof_quran/presentation/widgets/reading_goals/home_reading_card.dart';

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

  final List<ReadingSession> sessions = [];

  @override
  Future<void> saveSession(ReadingSession session) async {
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
  }

  @override
  Future<List<ReadingSession>> getSessions(String goalId) async =>
      sessions.where((s) => s.goalId == goalId).toList();

  @override
  Future<String?> getActiveGoalId() async => activeGoalId;

  @override
  Future<void> setActiveGoalId(String? goalId) async => activeGoalId = goalId;
}

Widget _wrap(ReadingGoalsCubit cubit, Widget child) {
  return BlocProvider.value(
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
      home: child,
    ),
  );
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
    createdAt: now,
    updatedAt: now,
  );

  group('HomeReadingCard', () {
    testWidgets('invites to create a goal when none exists', (tester) async {
      final cubit = ReadingGoalsCubit(
        repository: _FakeRepository(),
        today: () => today,
        totalPages: 604,
      );
      addTearDown(cubit.close);
      await cubit.load();

      await tester.pumpWidget(
        _wrap(cubit, const Scaffold(body: HomeReadingCard())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Planifiez votre lecture du Coran'), findsOneWidget);
      expect(find.text('Créer un objectif'), findsOneWidget);
    });

    testWidgets('shows the followed goal with today\'s quota', (tester) async {
      final repository = _FakeRepository()
        ..goals['g1'] = goal('g1', 'Khatm Ramadan')
        ..pages['g1'] = {for (var p = 1; p <= 10; p++) p: now}
        ..activeGoalId = 'g1';
      final cubit = ReadingGoalsCubit(
        repository: repository,
        today: () => today,
        totalPages: 604,
      );
      addTearDown(cubit.close);
      await cubit.load();

      await tester.pumpWidget(
        _wrap(cubit, const Scaffold(body: HomeReadingCard())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khatm Ramadan'), findsOneWidget);
      expect(find.text('10/604 pages'), findsOneWidget);
      // Target 21, read 10 → 11 left.
      expect(
        find.text('Il reste 11 pages à lire aujourd\'hui'),
        findsOneWidget,
      );
      expect(find.text('Continuer la lecture'), findsOneWidget);
    });
  });

  group('ReadingGoalsPage', () {
    testWidgets('lists goals by phase with their status', (tester) async {
      final repository = _FakeRepository()
        ..goals['a'] = goal('a', 'Actif')
        ..goals['b'] = goal(
          'b',
          'Futur',
        ).copyWith(startDate: today.addDays(3), endDate: today.addDays(32))
        ..goals['c'] = goal(
          'c',
          'Fini',
        ).copyWith(status: ReadingGoalStatus.completed, completedAt: now)
        ..activeGoalId = 'a';
      final cubit = ReadingGoalsCubit(
        repository: repository,
        today: () => today,
        totalPages: 604,
      );
      addTearDown(cubit.close);
      await cubit.load();

      await tester.pumpWidget(_wrap(cubit, const ReadingGoalsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Actif'), findsWidgets);
      expect(find.text('Suivi dans le Mushaf'), findsOneWidget);
      expect(find.text('Futur'), findsNothing);
      expect(find.text('Reprendre à la page 1'), findsOneWidget);

      await tester.tap(find.text('Planifiés (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Futur'), findsOneWidget);
      expect(find.text('Planifié'), findsOneWidget);

      await tester.tap(find.text('Terminés (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Fini'), findsOneWidget);
      expect(find.text('Terminé'), findsOneWidget);
      expect(find.text('Nouvel objectif à partir de celui-ci'), findsOneWidget);
    });

    testWidgets('shows the empty state without goals', (tester) async {
      final cubit = ReadingGoalsCubit(
        repository: _FakeRepository(),
        today: () => today,
        totalPages: 604,
      );
      addTearDown(cubit.close);
      await cubit.load();

      await tester.pumpWidget(_wrap(cubit, const ReadingGoalsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Aucun objectif de lecture'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
