import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/reading/local_date.dart';
import 'package:wolof_quran/domain/entities/reading_goal.dart';
import 'package:wolof_quran/domain/entities/reading_session.dart';
import 'package:wolof_quran/domain/entities/reading_validation.dart';
import 'package:wolof_quran/domain/repositories/reading_goal_repository.dart';
import 'package:wolof_quran/presentation/cubits/reading_goals_cubit.dart';

/// In-memory repository mirroring the SQLite semantics: pages are a set per
/// goal, the journal lists only pages actually added or removed.
class _InMemoryReadingGoalRepository implements ReadingGoalRepository {
  final Map<String, ReadingGoal> goals = {};
  final Map<String, Map<int, DateTime>> pages = {};
  final List<ReadingValidation> journal = [];
  String? activeGoalId;
  int _ids = 0;
  DateTime now = DateTime(2026, 3, 1, 9);

  @override
  Future<List<ReadingGoal>> getGoals() async => goals.values.toList();

  @override
  Future<ReadingGoal?> getGoal(String id) async => goals[id];

  @override
  Future<void> saveGoal(ReadingGoal goal) async => goals[goal.id] = goal;

  @override
  Future<void> deleteGoal(String id) async {
    goals.remove(id);
    pages.remove(id);
    journal.removeWhere((entry) => entry.goalId == id);
    if (activeGoalId == id) activeGoalId = null;
  }

  @override
  Future<Map<int, DateTime>> getValidatedPages(String goalId) async =>
      Map.of(pages[goalId] ?? {});

  @override
  Future<Map<String, Map<int, DateTime>>> getAllValidatedPages() async => {
    for (final entry in pages.entries) entry.key: Map.of(entry.value),
  };

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
    if (added.isEmpty) return null;
    for (final page in added) {
      stored[page] = now;
    }
    final validation = ReadingValidation(
      id: 'v${_ids++}',
      goalId: goalId,
      createdAt: now,
      source: source,
      action: action,
      fromPage: fromPage,
      toPage: toPage,
      pages: added,
    );
    journal.add(validation);
    return validation;
  }

  @override
  Future<ReadingValidation?> unmarkPages({
    required String goalId,
    required List<int> pages,
  }) async {
    final stored = this.pages[goalId] ?? {};
    final removed = pages.where(stored.containsKey).toList();
    if (removed.isEmpty) return null;
    removed.forEach(stored.remove);
    final validation = ReadingValidation(
      id: 'v${_ids++}',
      goalId: goalId,
      createdAt: now,
      source: ReadingValidationSource.manual,
      action: ReadingValidationAction.unmark,
      pages: removed,
    );
    journal.add(validation);
    return validation;
  }

  @override
  Future<List<ReadingValidation>> getValidations(String goalId) async => journal
      .where((entry) => entry.goalId == goalId)
      .toList()
      .reversed
      .toList();

  @override
  Future<void> undoValidation(String validationId) async {
    final index = journal.indexWhere((entry) => entry.id == validationId);
    if (index < 0) return;
    final validation = journal.removeAt(index);
    final stored = pages.putIfAbsent(validation.goalId, () => {});
    if (validation.isUnmark) {
      for (final page in validation.pages) {
        stored[page] = validation.createdAt;
      }
    } else {
      validation.pages.forEach(stored.remove);
    }
  }

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
  Future<List<ReadingSession>> getAllSessions() async => sessions;

  @override
  Future<String?> getActiveGoalId() async => activeGoalId;

  @override
  Future<void> setActiveGoalId(String? goalId) async => activeGoalId = goalId;
}

void main() {
  group('ReadingGoalsCubit', () {
    late _InMemoryReadingGoalRepository repository;
    late ReadingGoalsCubit cubit;
    var today = const LocalDate(2026, 3, 1);

    setUp(() async {
      today = const LocalDate(2026, 3, 1);
      repository = _InMemoryReadingGoalRepository();
      cubit = ReadingGoalsCubit(
        repository: repository,
        today: () => today,
        now: () => repository.now,
        totalPages: 604,
      );
      await cubit.load();
    });

    Future<ReadingGoal> create({String name = 'Khatm', int startPage = 1}) {
      return cubit.createGoal(
        name: name,
        startPage: startPage,
        startDate: today,
        endDate: today.addDays(29),
      );
    }

    test('creating a goal persists it and makes it active', () async {
      final goal = await create(name: 'Khatm Ramadan');

      expect(repository.goals[goal.id], isNotNull);
      expect(cubit.state.activeGoalId, goal.id);
      expect(cubit.state.goals.single.metrics.todayTarget, 21);
      expect(cubit.state.goals.single.phase, ReadingGoalPhase.active);
    });

    test('a page is never counted twice in the same goal', () async {
      final goal = await create();

      final first = await cubit.validatePage(goal.id, 12);
      final second = await cubit.validatePage(goal.id, 12);

      expect(first?.pages, [12]);
      expect(second, isNull);
      expect(cubit.state.progressOf(goal.id)!.metrics.validatedCount, 1);
      expect(cubit.state.lastValidation, first);
    });

    test('validating in one goal leaves the others untouched', () async {
      final a = await create(name: 'A');
      final b = await create(name: 'B');

      await cubit.validateRange(a.id, 1, 10);

      expect(cubit.state.progressOf(a.id)!.metrics.validatedCount, 10);
      expect(cubit.state.progressOf(b.id)!.metrics.validatedCount, 0);
      expect(repository.pages[b.id] ?? {}, isEmpty);
    });

    test(
      'skipped pages are not validated and keep continuous progress',
      () async {
        final goal = await create();
        await cubit.validateRange(goal.id, 1, 100);

        await cubit.validatePage(goal.id, 105);

        final metrics = cubit.state.progressOf(goal.id)!.metrics;
        expect(metrics.validatedCount, 101);
        expect(metrics.continuousProgress, 100);
        expect(metrics.firstUnvalidatedPage, 101);
        expect(cubit.state.progressOf(goal.id)!.isValidated(103), isFalse);
      },
    );

    test(
      'read until here fills the gap without recounting read pages',
      () async {
        final goal = await create();
        await cubit.validateRange(goal.id, 1, 160);
        await cubit.validatePage(goal.id, 170);

        expect(cubit.pagesUntil(goal.id, 187).length, 26); // 161..187 minus 170
        final validation = await cubit.readUntil(goal.id, 187);

        expect(validation!.pages, isNot(contains(170)));
        expect(validation.pages.first, 161);
        expect(validation.pages.last, 187);
        expect(
          cubit.state.progressOf(goal.id)!.metrics.continuousProgress,
          187,
        );
        expect(cubit.pagesUntil(goal.id, 150), isEmpty);
      },
    );

    test('ranges follow the wrapped reading order', () async {
      final goal = await create(startPage: 600);

      await cubit.validateRange(goal.id, 603, 2);

      final progress = cubit.state.progressOf(goal.id)!;
      expect(progress.validatedPages, {603, 604, 1, 2});
      expect(progress.metrics.firstUnvalidatedPage, 600);
    });

    test('unmarking a page and undoing it recomputes progress', () async {
      final goal = await create();
      await cubit.validateRange(goal.id, 1, 5);

      final unmark = await cubit.unmarkPage(goal.id, 3);
      expect(cubit.state.progressOf(goal.id)!.metrics.continuousProgress, 2);
      expect(unmark!.isUnmark, isTrue);

      await cubit.undoValidation(unmark.id);
      expect(cubit.state.progressOf(goal.id)!.metrics.continuousProgress, 5);
      expect(cubit.state.lastValidation, isNull);
    });

    test('undoing a range removes only the pages it added', () async {
      final goal = await create();
      await cubit.validateRange(goal.id, 1, 3);
      final overlap = await cubit.validateRange(goal.id, 2, 6);

      await cubit.undoValidation(overlap!.id);

      expect(cubit.state.progressOf(goal.id)!.validatedPages, {1, 2, 3});
    });

    test('a goal completes once every page is validated', () async {
      final goal = await create();

      await cubit.validateRange(goal.id, 1, 604);

      final progress = cubit.state.progressOf(goal.id)!;
      expect(progress.goal.status, ReadingGoalStatus.completed);
      expect(progress.goal.completedAt, repository.now);
      expect(cubit.state.lastCompletedGoalId, goal.id);
      expect(await cubit.validatePage(goal.id, 1), isNull);

      cubit.clearLastCompleted();
      expect(cubit.state.lastCompletedGoalId, isNull);
    });

    test('deleting the active goal falls back to free reading', () async {
      final goal = await create();
      await cubit.validatePage(goal.id, 1);

      await cubit.deleteGoal(goal.id);

      expect(cubit.state.goals, isEmpty);
      expect(cubit.state.activeGoalId, isNull);
      expect(cubit.state.lastValidation, isNull);
      expect(repository.activeGoalId, isNull);
    });

    test(
      'switching goals transfers no progress and only tracks the active one',
      () async {
        final a = await create(name: 'A');
        final b = await create(name: 'B');
        await cubit.validateRange(b.id, 1, 20);

        await cubit.setActiveGoal(a.id);
        await cubit.recordPageViewed(42);

        expect(cubit.state.progressOf(a.id)!.goal.lastViewedPage, 42);
        expect(cubit.state.progressOf(b.id)!.goal.lastViewedPage, isNull);
        expect(cubit.state.progressOf(a.id)!.metrics.validatedCount, 0);

        await cubit.setActiveGoal(null);
        await cubit.recordPageViewed(50);
        expect(cubit.state.progressOf(a.id)!.goal.lastViewedPage, 42);
      },
    );

    test(
      'pausing then resuming pushes the end date by the paused days',
      () async {
        final goal = await create();
        final originalEnd = goal.endDate;

        await cubit.pauseGoal(goal.id);
        expect(cubit.state.progressOf(goal.id)!.phase, ReadingGoalPhase.paused);

        today = today.addDays(3);
        await cubit.resumeGoal(goal.id);

        final resumed = cubit.state.progressOf(goal.id)!.goal;
        expect(resumed.status, ReadingGoalStatus.active);
        expect(resumed.endDate, originalEnd.addDays(3));
        expect(resumed.pausedAt, isNull);
      },
    );

    test('an expired goal keeps its progress and can be extended', () async {
      final goal = await create();
      await cubit.validateRange(goal.id, 1, 50);

      today = today.addDays(40);
      cubit.refreshToday();
      expect(cubit.state.progressOf(goal.id)!.phase, ReadingGoalPhase.expired);
      expect(cubit.state.progressOf(goal.id)!.metrics.validatedCount, 50);

      await cubit.updateDates(goal.id, endDate: today.addDays(10));
      expect(cubit.state.progressOf(goal.id)!.phase, ReadingGoalPhase.active);
      expect(cubit.state.progressOf(goal.id)!.metrics.remainingDays, 11);
    });

    test('a goal starting later is planned and lists apart', () async {
      final goal = await cubit.createGoal(
        name: 'Later',
        startPage: 1,
        startDate: today.addDays(5),
        endDate: today.addDays(34),
      );

      expect(cubit.state.progressOf(goal.id)!.phase, ReadingGoalPhase.planned);
      expect(cubit.state.planned.length, 1);
      expect(cubit.state.ongoing, isEmpty);
    });

    test('sessions record the time and pages of a reading stretch', () async {
      final goal = await create();

      final session = await cubit.startSession(goal.id);
      await cubit.endSession(
        session,
        activeDuration: const Duration(minutes: 12),
        pagesViewed: [5, 3, 4],
      );

      final stored = repository.sessions.single;
      expect(stored.id, session.id);
      expect(stored.goalId, goal.id);
      expect(stored.endedAt, repository.now);
      expect(stored.activeDuration, const Duration(minutes: 12));
      expect(stored.pagesViewed, [3, 4, 5]);
    });

    test('load drops an active goal id that no longer exists', () async {
      repository.activeGoalId = 'ghost';
      await cubit.load();
      expect(cubit.state.activeGoalId, isNull);
    });
  });
}
