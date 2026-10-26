import 'package:uuid/uuid.dart';

import '../../domain/entities/reading_goal.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/entities/reading_validation.dart';
import '../../domain/repositories/reading_goal_repository.dart';
import '../datasources/reading_goal_local_data_source.dart';
import '../datasources/reading_preferences_data_source.dart';

class ReadingGoalRepositoryImpl implements ReadingGoalRepository {
  final ReadingGoalLocalDataSource _localDataSource;
  final ReadingPreferencesDataSource _preferences;
  final DateTime Function() _now;
  final Uuid _uuid;

  ReadingGoalRepositoryImpl({
    required ReadingGoalLocalDataSource localDataSource,
    required ReadingPreferencesDataSource preferences,
    DateTime Function()? now,
    Uuid? uuid,
  }) : _localDataSource = localDataSource,
       _preferences = preferences,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  @override
  Future<List<ReadingGoal>> getGoals() => _localDataSource.getGoals();

  @override
  Future<ReadingGoal?> getGoal(String id) => _localDataSource.getGoal(id);

  @override
  Future<void> saveGoal(ReadingGoal goal) => _localDataSource.saveGoal(goal);

  @override
  Future<void> deleteGoal(String id) async {
    await _localDataSource.deleteGoal(id);
    if (await _preferences.getActiveGoalId() == id) {
      await _preferences.setActiveGoalId(null);
    }
  }

  @override
  Future<Map<int, DateTime>> getValidatedPages(String goalId) =>
      _localDataSource.getValidatedPages(goalId);

  @override
  Future<Map<String, Map<int, DateTime>>> getAllValidatedPages() =>
      _localDataSource.getAllValidatedPages();

  @override
  Future<ReadingValidation?> validatePages({
    required String goalId,
    required List<int> pages,
    required ReadingValidationSource source,
    required ReadingValidationAction action,
    int? fromPage,
    int? toPage,
  }) {
    final distinct = pages.toSet().toList();
    if (distinct.isEmpty) {
      return Future.value(null);
    }
    return _localDataSource.insertValidation(
      ReadingValidation(
        id: _uuid.v4(),
        goalId: goalId,
        createdAt: _now(),
        source: source,
        action: action,
        fromPage: fromPage,
        toPage: toPage,
        pages: distinct,
      ),
    );
  }

  @override
  Future<ReadingValidation?> unmarkPages({
    required String goalId,
    required List<int> pages,
  }) {
    final distinct = pages.toSet().toList();
    if (distinct.isEmpty) {
      return Future.value(null);
    }
    return _localDataSource.insertUnmark(
      ReadingValidation(
        id: _uuid.v4(),
        goalId: goalId,
        createdAt: _now(),
        source: ReadingValidationSource.manual,
        action: ReadingValidationAction.unmark,
        fromPage: distinct.first,
        toPage: distinct.last,
        pages: distinct,
      ),
    );
  }

  @override
  Future<List<ReadingValidation>> getValidations(String goalId) =>
      _localDataSource.getValidations(goalId);

  @override
  Future<void> undoValidation(String validationId) async {
    final validation = await _localDataSource.getValidation(validationId);
    if (validation == null) {
      return;
    }
    await _localDataSource.undoValidation(validation);
  }

  @override
  Future<void> saveSession(ReadingSession session) =>
      _localDataSource.saveSession(session);

  @override
  Future<List<ReadingSession>> getSessions(String goalId) =>
      _localDataSource.getSessions(goalId);

  @override
  Future<String?> getActiveGoalId() => _preferences.getActiveGoalId();

  @override
  Future<void> setActiveGoalId(String? goalId) =>
      _preferences.setActiveGoalId(goalId);
}
