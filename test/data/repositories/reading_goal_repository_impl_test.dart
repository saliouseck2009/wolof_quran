import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:wolof_quran/core/reading/local_date.dart';
import 'package:wolof_quran/data/datasources/database_helper.dart';
import 'package:wolof_quran/data/datasources/reading_goal_local_data_source.dart';
import 'package:wolof_quran/data/datasources/reading_preferences_data_source.dart';
import 'package:wolof_quran/data/repositories/reading_goal_repository_impl.dart';
import 'package:wolof_quran/domain/entities/reading_goal.dart';
import 'package:wolof_quran/domain/entities/reading_validation.dart';

class _FakeLocalDataSource extends ReadingGoalLocalDataSource {
  _FakeLocalDataSource() : super(DatabaseHelper());

  final Map<String, ReadingGoal> goals = {};
  final Map<String, Map<int, DateTime>> pages = {};
  final Map<String, ReadingValidation> validations = {};
  final List<ReadingValidation> undone = [];

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
  }

  @override
  Future<Map<int, DateTime>> getValidatedPages(String goalId) async =>
      pages[goalId] ?? {};

  @override
  Future<Map<String, Map<int, DateTime>>> getAllValidatedPages() async => pages;

  @override
  Future<ReadingValidation?> insertValidation(
    ReadingValidation validation,
  ) async {
    final stored = pages.putIfAbsent(validation.goalId, () => {});
    final added = validation.pages
        .where((p) => !stored.containsKey(p))
        .toList();
    if (added.isEmpty) return null;
    for (final page in added) {
      stored[page] = validation.createdAt;
    }
    final entry = ReadingValidation(
      id: validation.id,
      goalId: validation.goalId,
      createdAt: validation.createdAt,
      source: validation.source,
      action: validation.action,
      fromPage: validation.fromPage,
      toPage: validation.toPage,
      pages: added,
    );
    validations[entry.id] = entry;
    return entry;
  }

  @override
  Future<ReadingValidation?> insertUnmark(ReadingValidation validation) async {
    final stored = pages[validation.goalId] ?? {};
    final removed = validation.pages.where(stored.containsKey).toList();
    if (removed.isEmpty) return null;
    removed.forEach(stored.remove);
    final entry = ReadingValidation(
      id: validation.id,
      goalId: validation.goalId,
      createdAt: validation.createdAt,
      source: validation.source,
      action: ReadingValidationAction.unmark,
      fromPage: validation.fromPage,
      toPage: validation.toPage,
      pages: removed,
    );
    validations[entry.id] = entry;
    return entry;
  }

  @override
  Future<ReadingValidation?> getValidation(String id) async => validations[id];

  @override
  Future<void> undoValidation(ReadingValidation validation) async {
    undone.add(validation);
    validations.remove(validation.id);
  }
}

class _FakePreferences extends ReadingPreferencesDataSource {
  String? activeGoalId;

  @override
  Future<String?> getActiveGoalId() async => activeGoalId;

  @override
  Future<void> setActiveGoalId(String? goalId) async => activeGoalId = goalId;
}

void main() {
  group('ReadingGoalRepositoryImpl', () {
    late _FakeLocalDataSource dataSource;
    late _FakePreferences preferences;
    late ReadingGoalRepositoryImpl repository;
    final now = DateTime(2026, 3, 1, 12);

    setUp(() {
      dataSource = _FakeLocalDataSource();
      preferences = _FakePreferences();
      repository = ReadingGoalRepositoryImpl(
        localDataSource: dataSource,
        preferences: preferences,
        now: () => now,
        uuid: const Uuid(),
      );
    });

    test('validatePages deduplicates input and stamps the entry', () async {
      final validation = await repository.validatePages(
        goalId: 'g1',
        pages: [3, 1, 2, 2, 3],
        source: ReadingValidationSource.manual,
        action: ReadingValidationAction.range,
        fromPage: 1,
        toPage: 3,
      );

      expect(validation!.pages, unorderedEquals([1, 2, 3]));
      expect(validation.createdAt, now);
      expect(validation.id, isNotEmpty);
      expect(
        await repository.validatePages(
          goalId: 'g1',
          pages: [],
          source: ReadingValidationSource.auto,
          action: ReadingValidationAction.page,
        ),
        isNull,
      );
    });

    test('unmarkPages journals an unmark entry for the stored pages', () async {
      await repository.validatePages(
        goalId: 'g1',
        pages: [1, 2],
        source: ReadingValidationSource.manual,
        action: ReadingValidationAction.range,
      );

      final unmark = await repository.unmarkPages(goalId: 'g1', pages: [2, 9]);

      expect(unmark!.action, ReadingValidationAction.unmark);
      expect(unmark.pages, [2]);
      expect(await repository.unmarkPages(goalId: 'g1', pages: [9]), isNull);
    });

    test('undoValidation looks the entry up before reverting it', () async {
      final validation = await repository.validatePages(
        goalId: 'g1',
        pages: [7],
        source: ReadingValidationSource.auto,
        action: ReadingValidationAction.page,
      );

      await repository.undoValidation(validation!.id);
      await repository.undoValidation('missing');

      expect(dataSource.undone.single.id, validation.id);
    });

    test('deleting the active goal clears the active goal id', () async {
      preferences.activeGoalId = 'g1';
      dataSource.goals['g1'] = ReadingGoal(
        id: 'g1',
        name: 'Khatm',
        status: ReadingGoalStatus.active,
        startPage: 1,
        totalPages: 604,
        startDate: const LocalDate(2026, 3, 1),
        endDate: const LocalDate(2026, 3, 30),
        createdAt: now,
        updatedAt: now,
      );

      await repository.deleteGoal('g1');

      expect(dataSource.goals, isEmpty);
      expect(await repository.getActiveGoalId(), isNull);
    });

    test('goal and validation maps round-trip through the row format', () {
      final goal = ReadingGoal(
        id: 'g1',
        name: 'Khatm',
        status: ReadingGoalStatus.paused,
        startPage: 300,
        totalPages: 604,
        startDate: const LocalDate(2026, 3, 1),
        endDate: const LocalDate(2026, 3, 30),
        pausedAt: const LocalDate(2026, 3, 10),
        lastViewedPage: 305,
        reminder: const ReminderSettings(enabled: true, hour: 7, minute: 30),
        createdAt: now,
        updatedAt: now,
        completedAt: null,
      );
      final restored = ReadingGoalLocalDataSource.goalFromMap(
        ReadingGoalLocalDataSource.goalToMap(goal),
      );
      expect(restored, goal);

      final validation = ReadingValidation(
        id: 'v1',
        goalId: 'g1',
        createdAt: now,
        source: ReadingValidationSource.auto,
        action: ReadingValidationAction.readUntil,
        fromPage: 1,
        toPage: 3,
        pages: const [1, 2, 3],
      );
      expect(
        ReadingGoalLocalDataSource.validationFromMap(
          ReadingGoalLocalDataSource.validationToMap(validation),
        ),
        validation,
      );
    });
  });
}
