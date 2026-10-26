import '../entities/reading_goal.dart';
import '../entities/reading_validation.dart';

abstract class ReadingGoalRepository {
  Future<List<ReadingGoal>> getGoals();

  Future<ReadingGoal?> getGoal(String id);

  /// Inserts or replaces [goal].
  Future<void> saveGoal(ReadingGoal goal);

  /// Removes the goal with its pages and journal.
  Future<void> deleteGoal(String id);

  /// Validated page → validation time, for one goal.
  Future<Map<int, DateTime>> getValidatedPages(String goalId);

  /// Validated pages of every goal, keyed by goal id.
  Future<Map<String, Map<int, DateTime>>> getAllValidatedPages();

  /// Marks [pages] as read in [goalId]. Pages already validated are left
  /// untouched. Returns the journal entry, or `null` when nothing changed.
  Future<ReadingValidation?> validatePages({
    required String goalId,
    required List<int> pages,
    required ReadingValidationSource source,
    required ReadingValidationAction action,
    int? fromPage,
    int? toPage,
  });

  /// Removes the validation of [pages] in [goalId]. Returns the journal
  /// entry, or `null` when none of the pages was validated.
  Future<ReadingValidation?> unmarkPages({
    required String goalId,
    required List<int> pages,
  });

  /// Journal of [goalId], most recent first.
  Future<List<ReadingValidation>> getValidations(String goalId);

  /// Reverts the journal entry [validationId] and removes it.
  Future<void> undoValidation(String validationId);

  /// Goal followed in the mushaf, `null` for free reading.
  Future<String?> getActiveGoalId();

  Future<void> setActiveGoalId(String? goalId);
}
