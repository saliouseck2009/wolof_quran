import 'package:shared_preferences/shared_preferences.dart';

/// Scalar reading-tracking preferences, kept apart from the goals database.
class ReadingPreferencesDataSource {
  static const _activeGoalKey = 'reading_active_goal_id';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> getActiveGoalId() async {
    final prefs = await _prefs;
    return prefs.getString(_activeGoalKey);
  }

  Future<void> setActiveGoalId(String? goalId) async {
    final prefs = await _prefs;
    if (goalId == null) {
      await prefs.remove(_activeGoalKey);
    } else {
      await prefs.setString(_activeGoalKey, goalId);
    }
  }
}
