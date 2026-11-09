import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/config/support_config.dart';

void main() {
  group('SupportConfig iOS external support page', () {
    test('defaults point to the hosted page and are enabled', () {
      expect(
        SupportConfig.defaults.iosSupportUrl,
        'https://saliouseck2009.github.io/wolof_quran/soutenir/',
      );
      expect(SupportConfig.defaults.iosSupportEnabled, isTrue);
    });

    test('fromJson keeps the defaults when the keys are missing', () {
      final config = SupportConfig.fromJson({'wave_url': 'https://w.example'});
      expect(config.waveUrl, 'https://w.example');
      expect(config.iosSupportUrl, SupportConfig.defaults.iosSupportUrl);
      expect(config.iosSupportEnabled, isTrue);
    });

    test('fromJson reads the remote switch and url', () {
      final config = SupportConfig.fromJson({
        'ios_support_url': 'https://example.org/soutenir/',
        'ios_support_enabled': false,
      });
      expect(config.iosSupportUrl, 'https://example.org/soutenir/');
      expect(config.iosSupportEnabled, isFalse);
    });

    test('toJson round-trips the new keys', () {
      final json = SupportConfig.defaults.toJson();
      expect(json['ios_support_url'], SupportConfig.defaults.iosSupportUrl);
      expect(json['ios_support_enabled'], isTrue);
      expect(SupportConfig.fromJson(json).iosSupportEnabled, isTrue);
    });
  });
}
