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

  group('AudioPlayerService.computeTotalDuration', () {
    test('returns null when one duration is unknown', () {
      final total = AudioPlayerService.computeTotalDuration([
        const Duration(seconds: 10),
        null,
        const Duration(seconds: 20),
      ]);

      expect(total, isNull);
    });

    test('sums known segment durations', () {
      final total = AudioPlayerService.computeTotalDuration([
        const Duration(seconds: 10),
        const Duration(seconds: 20),
        const Duration(seconds: 30),
      ]);

      expect(total, const Duration(seconds: 60));
    });
  });

  group('AudioPlayerService.computeGlobalPosition', () {
    test('computes global position from current index and offset', () {
      final global = AudioPlayerService.computeGlobalPosition(
        segmentDurations: const [
          Duration(seconds: 10),
          Duration(seconds: 20),
          Duration(seconds: 30),
        ],
        currentIndex: 2,
        currentPosition: const Duration(seconds: 7),
      );

      expect(global, const Duration(seconds: 37));
    });
  });

  group('AudioPlayerService.mapGlobalSeekTarget', () {
    test('maps beginning to first ayah', () {
      final seekTarget = AudioPlayerService.mapGlobalSeekTarget(
        target: Duration.zero,
        segmentDurations: const [Duration(seconds: 10), Duration(seconds: 20)],
      );

      expect(seekTarget.ayahIndex, 0);
      expect(seekTarget.offset, Duration.zero);
    });

    test('maps middle position to proper ayah and local offset', () {
      final seekTarget = AudioPlayerService.mapGlobalSeekTarget(
        target: const Duration(seconds: 17),
        segmentDurations: const [
          Duration(seconds: 10),
          Duration(seconds: 20),
          Duration(seconds: 30),
        ],
      );

      expect(seekTarget.ayahIndex, 1);
      expect(seekTarget.offset, const Duration(seconds: 7));
    });

    test('clamps end to last ayah duration', () {
      final seekTarget = AudioPlayerService.mapGlobalSeekTarget(
        target: const Duration(seconds: 999),
        segmentDurations: const [Duration(seconds: 10), Duration(seconds: 20)],
      );

      expect(seekTarget.ayahIndex, 1);
      expect(seekTarget.offset, const Duration(seconds: 20));
    });
  });
}
