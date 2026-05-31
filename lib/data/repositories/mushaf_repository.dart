import 'package:shared_preferences/shared_preferences.dart';

import '../../core/mushaf/mushaf_theme.dart';

class MushafRepository {
  static const _lastPageKey = 'mushaf_last_read_page';
  static const _themeKey = 'mushaf_theme';
  static const _longPressHintSeenKey = 'mushaf_long_press_hint_seen';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<int> getLastReadPage() async {
    final prefs = await _prefs;
    return prefs.getInt(_lastPageKey) ?? 1;
  }

  Future<void> saveLastReadPage(int page) async {
    final prefs = await _prefs;
    await prefs.setInt(_lastPageKey, page);
  }

  Future<int> getThemeIndex() async {
    final prefs = await _prefs;
    return prefs.getInt(_themeKey) ?? MushafThemeData.defaultThemeIndex;
  }

  Future<void> saveThemeIndex(int index) async {
    final prefs = await _prefs;
    await prefs.setInt(_themeKey, index);
  }

  Future<bool> getHasSeenLongPressHint() async {
    final prefs = await _prefs;
    return prefs.getBool(_longPressHintSeenKey) ?? false;
  }

  Future<void> setHasSeenLongPressHint(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_longPressHintSeenKey, value);
  }
}
