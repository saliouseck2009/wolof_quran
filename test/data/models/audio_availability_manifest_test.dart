import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/data/models/audio_availability_manifest.dart';

void main() {
  group('AudioAvailabilityManifest', () {
    test('parses a valid manifest payload', () {
      final manifest = AudioAvailabilityManifest.fromJson({
        'schemaVersion': 1,
        'generatedAt': '2026-02-20T12:00:00Z',
        'reciters': [
          {
            'id': 'imamsarr',
            'catalogVersion': 7,
            'availableSurahs': [1, 2, 3, 3],
          },
        ],
      });

      final reciter = manifest.reciterById('imamsarr');

      expect(manifest.schemaVersion, 1);
      expect(reciter, isNotNull);
      expect(reciter!.catalogVersion, 7);
      expect(reciter.availableSurahs, [1, 2, 3]);
    });

    test('throws when reciters is not a list', () {
      expect(
        () => AudioAvailabilityManifest.fromJson({
          'schemaVersion': 1,
          'reciters': {'id': 'imamsarr'},
        }),
        throwsFormatException,
      );
    });

    test('returns null when requested reciter is absent', () {
      final manifest = AudioAvailabilityManifest.fromJson({
        'schemaVersion': 1,
        'reciters': [
          {
            'id': 'other',
            'catalogVersion': 1,
            'availableSurahs': [1],
          },
        ],
      });

      expect(manifest.reciterById('imamsarr'), isNull);
    });
  });
}
