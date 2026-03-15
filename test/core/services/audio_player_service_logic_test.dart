import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/core/services/audio_player_service.dart';

void main() {
  group('AudioPlayerService.computeSeekTarget', () {
    test('clamps negative targets to zero', () {
      final target = AudioPlayerService.computeSeekTarget(
        current: const Duration(seconds: 3),
        delta: const Duration(seconds: -10),
        total: const Duration(seconds: 30),
      );

      expect(target, Duration.zero);
    });

    test('clamps target to duration upper bound', () {
      final target = AudioPlayerService.computeSeekTarget(
        current: const Duration(seconds: 28),
        delta: const Duration(seconds: 10),
        total: const Duration(seconds: 30),
      );

      expect(target, const Duration(seconds: 30));
    });

    test('keeps expected target when inside bounds', () {
      final target = AudioPlayerService.computeSeekTarget(
        current: const Duration(seconds: 10),
        delta: const Duration(seconds: 5),
        total: const Duration(seconds: 30),
      );

      expect(target, const Duration(seconds: 15));
    });
  });

  group('AudioPlayerService.computeNextPlaylistIndex', () {
    test('goes to next index when middle of playlist', () {
      final next = AudioPlayerService.computeNextPlaylistIndex(
        currentIndex: 1,
        playlistLength: 4,
        repeatEnabled: false,
      );

      expect(next, 2);
    });

    test('returns null at end when repeat disabled', () {
      final next = AudioPlayerService.computeNextPlaylistIndex(
        currentIndex: 2,
        playlistLength: 3,
        repeatEnabled: false,
      );

      expect(next, isNull);
    });

    test('returns zero at end when repeat enabled', () {
      final next = AudioPlayerService.computeNextPlaylistIndex(
        currentIndex: 2,
        playlistLength: 3,
        repeatEnabled: true,
      );

      expect(next, 0);
    });
  });
}
