import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolof_quran/presentation/cubits/quran_settings_cubit.dart';

void main() {
  group('QuranSettingsCubit reading tracking', () {
    test('defaults to automatic tracking at 30 seconds', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final cubit = QuranSettingsCubit();
      addTearDown(cubit.close);

      cubit.loadSettings();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.autoTrackingEnabled, isTrue);
      expect(cubit.state.autoTrackingThreshold, const Duration(seconds: 30));
    });

    test('restores saved tracking settings', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'reading_auto_tracking_enabled': false,
        'reading_auto_tracking_threshold_seconds': 60,
      });
      final cubit = QuranSettingsCubit();
      addTearDown(cubit.close);

      cubit.loadSettings();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.autoTrackingEnabled, isFalse);
      expect(cubit.state.autoTrackingThresholdSeconds, 60);
    });

    test('updates are persisted', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final cubit = QuranSettingsCubit();
      addTearDown(cubit.close);

      cubit.updateAutoTrackingEnabled(false);
      cubit.updateAutoTrackingThreshold(45);
      cubit.updateAutoTrackingThreshold(0);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.autoTrackingEnabled, isFalse);
      expect(cubit.state.autoTrackingThresholdSeconds, 45);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reading_auto_tracking_enabled'), isFalse);
      expect(prefs.getInt('reading_auto_tracking_threshold_seconds'), 45);
    });
  });
}
