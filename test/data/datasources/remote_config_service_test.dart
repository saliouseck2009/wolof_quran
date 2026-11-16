import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolof_quran/core/config/seasonal_theme_config.dart';
import 'package:wolof_quran/core/config/support_config.dart';
import 'package:wolof_quran/core/config/theme/seasonal_theme.dart';
import 'package:wolof_quran/data/datasources/remote_config_service.dart';

/// Answers every request with [body], or fails like a device offline when
/// it is null.
class _FakeGist implements HttpClientAdapter {
  String? body;
  int requests = 0;

  _FakeGist(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    final body = this.body;
    if (body == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(body, 200);
  }

  @override
  void close({bool force = false}) {}
}

const _ramadanOn = {
  'seasonal_theme': {'id': 'ramadan', 'enabled': true},
};

void main() {
  late _FakeGist gist;
  late DateTime now;

  Future<RemoteConfigService> createService({
    Map<String, Object> cache = const {},
  }) async {
    SharedPreferences.setMockInitialValues(cache);
    final prefs = await SharedPreferences.getInstance();
    return RemoteConfigService(
      dio: Dio()..httpClientAdapter = gist,
      prefs: prefs,
      clock: () => now,
    );
  }

  setUp(() {
    gist = _FakeGist(jsonEncode(_ramadanOn));
    now = DateTime(2027, 2, 20, 9);
  });

  test('the seasonal theme is off until the remote file turns it on', () async {
    gist.body = jsonEncode({'wave_label': 'Wave'});
    final service = await createService();
    expect(service.seasonalTheme, SeasonalThemeConfig.disabled);

    await service.init();

    expect(service.seasonalTheme, SeasonalThemeConfig.disabled);
    expect(service.config.waveLabel, 'Wave');
  });

  test('a fetch turns the theme on, announces it and caches it', () async {
    final service = await createService();
    final changes = <SeasonalThemeConfig>[];
    service.seasonalThemeChanges.listen(changes.add);

    await service.init();
    await pumpEventQueue();

    expect(service.seasonalTheme.themeOn(now), SeasonalTheme.ramadan);
    expect(changes, [service.seasonalTheme]);

    // Next launch, offline: the cached switch is there before any fetch.
    final prefs = await SharedPreferences.getInstance();
    gist.body = null;
    final relaunched = RemoteConfigService(
      dio: Dio()..httpClientAdapter = gist,
      prefs: prefs,
    );
    final init = relaunched.init();
    expect(relaunched.seasonalTheme.themeOn(now), SeasonalTheme.ramadan);
    await init;
    expect(relaunched.seasonalTheme.themeOn(now), SeasonalTheme.ramadan);
  });

  test('removing the switch remotely turns the theme off', () async {
    final service = await createService(
      cache: {'remote_support_config': jsonEncode(_ramadanOn)},
    );
    gist.body = jsonEncode({
      'seasonal_theme': {'id': 'ramadan', 'enabled': false},
    });
    final changes = <SeasonalThemeConfig>[];
    service.seasonalThemeChanges.listen(changes.add);

    await service.init();
    await pumpEventQueue();

    expect(service.seasonalTheme.themeOn(now), SeasonalTheme.none);
    // On from the cache first, then off once the remote file answered.
    expect(changes.map((config) => config.enabled), [true, false]);
  });

  test('refresh waits for the interval, then asks again', () async {
    final service = await createService();
    await service.init();
    expect(gist.requests, 1);

    now = now.add(const Duration(minutes: 30));
    await service.refresh(minInterval: const Duration(hours: 1));
    expect(gist.requests, 1);

    now = now.add(const Duration(minutes: 31));
    gist.body = jsonEncode(<String, dynamic>{});
    await service.refresh(minInterval: const Duration(hours: 1));
    expect(gist.requests, 2);
    expect(service.seasonalTheme, SeasonalThemeConfig.disabled);
  });

  test('offline, refresh keeps the current config and retries later', () async {
    final service = await createService();
    await service.init();

    gist.body = null;
    now = now.add(const Duration(hours: 2));
    await service.refresh(minInterval: const Duration(hours: 1));
    expect(service.seasonalTheme.themeOn(now), SeasonalTheme.ramadan);

    // A failed fetch does not count: the next resume tries again.
    await service.refresh(minInterval: const Duration(hours: 1));
    expect(gist.requests, 3);
  });

  test('a support value of the wrong type does not block the switch', () async {
    gist.body = jsonEncode({..._ramadanOn, 'wave_url': 42});
    final service = await createService();

    await service.init();

    expect(service.seasonalTheme.themeOn(now), SeasonalTheme.ramadan);
    expect(service.config.waveUrl, SupportConfig.defaults.waveUrl);
  });
}
