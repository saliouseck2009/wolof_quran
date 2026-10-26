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
import 'package:wolof_quran/presentation/views/reading_goal_detail_page.dart';
import 'package:wolof_quran/presentation/views/reading_stats_page.dart';
import 'package:wolof_quran/service_locator.dart';

class _FakeRepository implements ReadingGoalRepository {
  final Map<String, ReadingGoal> goals = {};
  final Map<String, Map<int, DateTime>> pages = {};
  final List<ReadingValidation> journal = [];
  final List<ReadingSession> sessions = [];
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
      Map.of(pages[goalId] ?? {});

  @override
  Future<Map<String, Map<int, DateTime>>> getAllValidatedPages() async => {
    for (final e in pages.entries) e.key: Map.of(e.value),
  };

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
  Future<List<ReadingValidation>> getValidations(String goalId) async =>
      journal.where((v) => v.goalId == goalId).toList();

  @override
  Future<void> undoValidation(String validationId) async {
    final index = journal.indexWhere((v) => v.id == validationId);
    if (index < 0) return;
    final validation = journal.removeAt(index);
    validation.pages.forEach(pages[validation.goalId]!.remove);
  }

  @override
  Future<void> saveSession(ReadingSession session) async =>
      sessions.add(session);

  @override
  Future<List<ReadingSession>> getSessions(String goalId) async => sessions;

  @override
  Future<List<ReadingSession>> getAllSessions() async => sessions;

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
  const today = LocalDate(2026, 3, 5);
  final now = DateTime(2026, 3, 5, 9);

  ReadingGoal goal(String id, String name) => ReadingGoal(
    id: id,
    name: name,
    status: ReadingGoalStatus.active,
    startPage: 1,
    totalPages: 604,
    startDate: const LocalDate(2026, 3, 1),
    endDate: const LocalDate(2026, 3, 30),
    createdAt: now,
    updatedAt: now,
  );

  late _FakeRepository repository;

  setUp(() {
    repository = _FakeRepository();
    if (locator.isRegistered<ReadingGoalRepository>()) {
      locator.unregister<ReadingGoalRepository>();
    }
    locator.registerLazySingleton<ReadingGoalRepository>(() => repository);
  });

  tearDown(() {
    locator.unregister<ReadingGoalRepository>();
  });

  group('ReadingGoalDetailPage', () {
    testWidgets('shows progress, gaps, history and journal with undo', (
      tester,
    ) async {
      repository
        ..goals['g1'] = goal('g1', 'Khatm Ramadan')
        ..pages['g1'] = {for (var p = 1; p <= 10; p++) p: now, 15: now}
        ..journal.add(
          ReadingValidation(
            id: 'v1',
            goalId: 'g1',
            createdAt: now,
            source: ReadingValidationSource.manual,
            action: ReadingValidationAction.page,
            fromPage: 15,
            toPage: 15,
            pages: const [15],
          ),
        );
      final cubit = ReadingGoalsCubit(
        repository: repository,
        today: () => today,
        totalPages: 604,
      );
      addTearDown(cubit.close);
      await cubit.load();

      // Tall viewport so every section of the lazy list is built.
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(cubit, const ReadingGoalDetailPage(goalId: 'g1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khatm Ramadan'), findsOneWidget);
      expect(find.text('11 pages lues sur 604'), findsOneWidget);
      expect(
        find.text('Progression continue jusqu\'à la page 10'),
        findsOneWidget,
      );
      expect(find.text('Pages 11–14'), findsOneWidget);
      expect(find.text('Historique de lecture'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(repository.journal, isEmpty);
      expect(cubit.state.progressOf('g1')!.metrics.validatedCount, 10);
      expect(find.text('Aucune validation pour le moment.'), findsOneWidget);
    });
  });

  group('ReadingStatsPage', () {
    testWidgets('shows an empty state without any page read', (tester) async {
      final cubit = ReadingGoalsCubit(
        repository: repository,
        today: () => today,
        totalPages: 604,
      );
      addTearDown(cubit.close);
      await cubit.load();

      await tester.pumpWidget(_wrap(cubit, const ReadingStatsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Mes performances'), findsOneWidget);
      expect(find.textContaining('vos performances'), findsOneWidget);
    });

    testWidgets('shows totals, streak and per-goal split', (tester) async {
      repository
        ..goals['g1'] = goal('g1', 'Khatm A')
        ..goals['g2'] = goal('g2', 'Khatm B')
        ..pages['g1'] = {
          for (var p = 1; p <= 20; p++) p: DateTime(2026, 3, 4, 10),
          for (var p = 21; p <= 30; p++) p: now,
        }
        ..pages['g2'] = {for (var p = 1; p <= 5; p++) p: now};
      final cubit = ReadingGoalsCubit(
        repository: repository,
        today: () => today,
        totalPages: 604,
      );
      addTearDown(cubit.close);
      await cubit.load();

      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(cubit, const ReadingStatsPage()));
      await tester.pumpAndSettle();

      expect(find.text('35'), findsOneWidget); // pages read
      expect(find.text('Pages lues'), findsOneWidget);
      expect(find.text('2 jours'), findsWidgets); // current and best streak

      expect(find.text('Khatm A'), findsOneWidget);
      expect(find.text('Khatm B'), findsOneWidget);
      expect(find.text('Pages par jour'), findsOneWidget);
    });
  });
}
