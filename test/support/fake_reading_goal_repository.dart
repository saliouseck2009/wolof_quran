import 'package:wolof_quran/domain/entities/reading_goal.dart';
import 'package:wolof_quran/domain/entities/reading_session.dart';
import 'package:wolof_quran/domain/entities/reading_validation.dart';
import 'package:wolof_quran/domain/repositories/reading_goal_repository.dart';

/// In-memory [ReadingGoalRepository] for widget tests.
class FakeReadingGoalRepository implements ReadingGoalRepository {
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
  Future<List<ReadingSession>> getAllSessions() async => sessions;

  @override
  Future<String?> getActiveGoalId() async => activeGoalId;

  @override
  Future<void> setActiveGoalId(String? goalId) async => activeGoalId = goalId;
}
