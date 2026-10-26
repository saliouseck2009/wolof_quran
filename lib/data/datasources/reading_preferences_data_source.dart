import 'package:shared_preferences/shared_preferences.dart';

/// Scalar reading-tracking preferences, kept apart from the goals database.
class ReadingPreferencesDataSource {
  static const _activeGoalKey = 'reading_active_goal_id';
  static const _hintSeenKey = 'reading_goals_hint_seen';

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

  Future<bool> getHasSeenGoalsHint() async {
    final prefs = await _prefs;
    return prefs.getBool(_hintSeenKey) ?? false;
  }

  Future<void> setHasSeenGoalsHint(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_hintSeenKey, value);
  }
}
