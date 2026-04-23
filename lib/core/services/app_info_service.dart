import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  static String? _cachedVersionLabel;

  static Future<String> getAppVersionLabel() async {
    if (_cachedVersionLabel != null) {
      return _cachedVersionLabel!;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      final buildNumber = packageInfo.buildNumber.trim();

      if (version.isEmpty) {
        return _cachedVersionLabel = '--';
      }

      return _cachedVersionLabel = buildNumber.isEmpty
          ? version
          : '$version+$buildNumber';
    } catch (_) {
      return _cachedVersionLabel = '--';
    }
  }
}
