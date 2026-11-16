import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/seasonal_theme_config.dart';
import '../../core/config/support_config.dart';

/// Fetches a remote JSON config from a GitHub Gist, caches it locally,
/// and falls back to hardcoded defaults when offline.
class RemoteConfigService {
  static const String _cacheKey = 'remote_support_config';

  /// Key of the [SeasonalThemeConfig] object in the remote JSON.
  static const String seasonalThemeKey = 'seasonal_theme';

  /// ── IMPORTANT ──
  /// Replace this URL with the **raw** URL of your GitHub Gist file.
  /// Format: `https://gist.githubusercontent.com/{user}/{gist_id}/raw/{filename}`
  static const String _gistRawUrl =
      'https://gist.githubusercontent.com/saliouseck2009/e0ef3cffe91ba33e27f0b5c1825a11f0/raw/support_config.json';

  final Dio _dio;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  SupportConfig _config = SupportConfig.defaults;
  SeasonalThemeConfig _seasonalTheme = SeasonalThemeConfig.disabled;
  final StreamController<SeasonalThemeConfig> _seasonalThemeChanges =
      StreamController<SeasonalThemeConfig>.broadcast();
  DateTime? _lastFetch;
  Future<void>? _ongoingFetch;

  RemoteConfigService({
    required Dio dio,
    required SharedPreferences prefs,
    DateTime Function()? clock,
  }) : _dio = dio,
       _prefs = prefs,
       _clock = clock ?? DateTime.now;

  /// Current config (always available — never null).
  SupportConfig get config => _config;

  /// Current seasonal theme switch, off until the remote config says
  /// otherwise.
  SeasonalThemeConfig get seasonalTheme => _seasonalTheme;

  /// Emits the seasonal theme switch each time a fetch changes it.
  Stream<SeasonalThemeConfig> get seasonalThemeChanges =>
      _seasonalThemeChanges.stream;

  /// Call once at app startup. Loads cached config first, then tries
  /// to fetch the latest from the Gist in the background.
  Future<void> init() async {
    // 1. Load from cache immediately.
    _loadFromCache();

    // 2. Try to fetch fresh config (non-blocking).
    await refresh();
  }

  /// Fetches the config again, unless the last successful fetch is more
  /// recent than [minInterval]. Never throws: offline, the current config
  /// stays.
  Future<void> refresh({Duration minInterval = Duration.zero}) {
    final lastFetch = _lastFetch;
    if (lastFetch != null && _clock().difference(lastFetch) < minInterval) {
      return Future.value();
    }
    return _ongoingFetch ??= _fetchAndCache()
        .catchError((Object e) {
          log('RemoteConfigService: fetch failed, using cache/defaults — $e');
        })
        .whenComplete(() => _ongoingFetch = null);
  }

  void _loadFromCache() {
    final cached = _prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        _apply(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        // Corrupted cache — keep defaults.
      }
    }
  }

  Future<void> _fetchAndCache() async {
    final response = await _dio.get<String>(
      _gistRawUrl,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 5),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      _apply(jsonDecode(response.data!) as Map<String, dynamic>);
      await _prefs.setString(_cacheKey, response.data!);
      _lastFetch = _clock();
      log('RemoteConfigService: fetched and cached new config successfully.');
    }
  }

  void _apply(Map<String, dynamic> json) {
    // Read first: it never throws, so the seasonal switch still follows the
    // remote file when a support value has an unexpected type.
    final seasonalTheme = SeasonalThemeConfig.fromJson(json[seasonalThemeKey]);
    if (seasonalTheme != _seasonalTheme) {
      _seasonalTheme = seasonalTheme;
      _seasonalThemeChanges.add(seasonalTheme);
    }
    _config = SupportConfig.fromJson(json);
  }
}
