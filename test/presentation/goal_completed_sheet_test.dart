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
import 'package:wolof_quran/presentation/widgets/reading_goals/goal_completed_sheet.dart';

class _Repository implements ReadingGoalRepository {
  final Map<String, ReadingGoal> goals = {};
  final Map<String, Map<int, DateTime>> pages = {};
  int ids = 0;

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
  }) async {
    final stored = this.pages.putIfAbsent(goalId, () => {});
    final added = pages.where((p) => !stored.containsKey(p)).toList();
    for (final page in added) {
      stored[page] = DateTime(2026, 3, 20);
    }
    return ReadingValidation(
      id: 'v${ids++}',
      goalId: goalId,
      createdAt: DateTime(2026, 3, 20),
      source: source,
      action: action,
      pages: added,
    );
  }

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
  Future<String?> getActiveGoalId() async => null;

  @override
  Future<void> setActiveGoalId(String? goalId) async {}
}

void main() {
  testWidgets('completing a goal shows the completion sheet once', (
    tester,
  ) async {
    final now = DateTime(2026, 3, 20, 9);
    final repository = _Repository()
      ..goals['g1'] = ReadingGoal(
        id: 'g1',
        name: 'Khatm Ramadan',
        status: ReadingGoalStatus.active,
        startPage: 1,
        totalPages: 604,
        startDate: const LocalDate(2026, 3, 1),
        endDate: const LocalDate(2026, 3, 30),
        createdAt: now,
        updatedAt: now,
      );
    final cubit = ReadingGoalsCubit(
      repository: repository,
      today: () => const LocalDate(2026, 3, 20),
      now: () => now,
      totalPages: 604,
    );
    addTearDown(cubit.close);
    await cubit.load();

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
          home: const ReadingGoalCompletionListener(
            child: Scaffold(body: SizedBox()),
          ),
        ),
      ),
    );

    await cubit.validateRange('g1', 1, 604);
    await tester.pumpAndSettle();

    expect(find.text('Alhamdulillah !'), findsOneWidget);
    expect(find.text('Khatm Ramadan'), findsOneWidget);
    expect(find.text('Durée réelle : 20 jours'), findsOneWidget);
    expect(find.text('Nouveau Khatm'), findsOneWidget);
    expect(cubit.state.lastCompletedGoalId, isNull);
  });
}
