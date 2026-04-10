import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/support_config.dart';

/// Fetches a remote JSON config from a GitHub Gist, caches it locally,
/// and falls back to hardcoded defaults when offline.
class RemoteConfigService {
  static const String _cacheKey = 'remote_support_config';

  /// ── IMPORTANT ──
  /// Replace this URL with the **raw** URL of your GitHub Gist file.
  /// Format: `https://gist.githubusercontent.com/{user}/{gist_id}/raw/{filename}`
  static const String _gistRawUrl =
      'https://gist.githubusercontent.com/saliouseck2009/e0ef3cffe91ba33e27f0b5c1825a11f0/raw/support_config.json';

  final Dio _dio;
  final SharedPreferences _prefs;

  SupportConfig _config = SupportConfig.defaults;

  RemoteConfigService({required Dio dio, required SharedPreferences prefs})
    : _dio = dio,
      _prefs = prefs;

  /// Current config (always available — never null).
  SupportConfig get config => _config;

  /// Call once at app startup. Loads cached config first, then tries
  /// to fetch the latest from the Gist in the background.
  Future<void> init() async {
    // 1. Load from cache immediately.
    _loadFromCache();

    // 2. Try to fetch fresh config (non-blocking).
    try {
      await _fetchAndCache();
    } catch (e) {
      log('RemoteConfigService: fetch failed, using cache/defaults — $e');
    }
  }

  void _loadFromCache() {
    final cached = _prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        _config = SupportConfig.fromJson(json);
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
      final json = jsonDecode(response.data!) as Map<String, dynamic>;
      _config = SupportConfig.fromJson(json);
      await _prefs.setString(_cacheKey, response.data!);
      log('RemoteConfigService: fetched and cached new config successfully.');
    }
  }
}
