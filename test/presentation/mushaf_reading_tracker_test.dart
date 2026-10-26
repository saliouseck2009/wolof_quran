import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/presentation/utils/mushaf_reading_tracker.dart';

void main() {
  group('MushafReadingTracker', () {
    late DateTime now;
    late List<int> read;
    late List<int> tooShort;
    late Set<int> validated;
    late MushafReadingTracker tracker;

    void advance(int seconds) => now = now.add(Duration(seconds: seconds));

    setUp(() {
      now = DateTime(2026, 3, 1, 10);
      read = [];
      tooShort = [];
      validated = {};
      tracker = MushafReadingTracker(
        threshold: const Duration(seconds: 30),
        enabled: true,
        goalId: 'g1',
        isValidated: validated.contains,
        onPageRead: read.add,
        onPageTooShort: tooShort.add,
        now: () => now,
      );
    });

    test('a page left after the threshold is read', () {
      tracker.onPageChanged(120);
      advance(45);
      tracker.onPageChanged(121);

      expect(read, [120]);
      expect(tooShort, isEmpty);
      expect(tracker.pagesViewed, {120, 121});
    });

    test('a page left too early only triggers the hint', () {
      tracker.onPageChanged(120);
      advance(8);
      tracker.onPageChanged(121);

      expect(read, isEmpty);
      expect(tooShort, [120]);
    });

    test('flipping through pages shows no hint', () {
      tracker.onPageChanged(120);
      advance(1);
      tracker.onPageChanged(121);
      advance(2);
      tracker.onPageChanged(122);

      expect(read, isEmpty);
      expect(tooShort, isEmpty);
    });

    test('hints are rate limited', () {
      tracker.onPageChanged(1);
      advance(5);
      tracker.onPageChanged(2);
      advance(5);
      tracker.onPageChanged(3);
      advance(40);
      tracker.onPageChanged(4);
      advance(5);
      tracker.onPageChanged(5);

      expect(tooShort, [1, 4]);
      expect(read, [3]);
    });

    test('an already validated page is ignored', () {
      validated.add(120);
      tracker.onPageChanged(120);
      advance(60);
      tracker.onPageChanged(121);

      expect(read, isEmpty);
      expect(tooShort, isEmpty);
    });

    test('the clock pauses in the background and resumes', () {
      tracker.onPageChanged(120);
      advance(10);
      tracker.onVisibilityChanged(false);
      advance(600);
      tracker.onVisibilityChanged(true);
      advance(10);
      tracker.onPageChanged(121);

      // 10 s before + 10 s after, background time excluded, and the counter
      // restarted from zero on return.
      expect(read, isEmpty);
      expect(tooShort, [120]);
      expect(tracker.activeTotal, const Duration(seconds: 20));
    });

    test('going to the background past the threshold reads the page once', () {
      tracker.onPageChanged(120);
      advance(40);
      tracker.onVisibilityChanged(false);
      validated.add(120);
      tracker.onVisibilityChanged(true);
      advance(40);
      tracker.onPageChanged(121);

      expect(read, [120]);
    });

    test('switching goal drops the accumulated time', () {
      tracker.onPageChanged(120);
      advance(25);
      tracker.onGoalChanged('g2');
      advance(10);
      tracker.onPageChanged(121);

      expect(read, isEmpty);
      expect(tooShort, [120]);
      expect(tracker.goalId, 'g2');
    });

    test('nothing is tracked in free reading or when disabled', () {
      tracker.onGoalChanged(null);
      tracker.onPageChanged(120);
      advance(60);
      tracker.onPageChanged(121);
      expect(read, isEmpty);
      expect(tracker.pagesViewed, isEmpty);

      tracker.onGoalChanged('g1');
      tracker.setEnabled(false);
      advance(60);
      tracker.onPageChanged(122);
      expect(read, isEmpty);
      expect(tooShort, isEmpty);
    });

    test('dispose flushes the current page', () {
      tracker.onPageChanged(120);
      advance(31);
      tracker.dispose();

      expect(read, [120]);
      expect(tracker.elapsedOnCurrentPage, Duration.zero);
    });

    test('a higher threshold applies to the next page', () {
      tracker.onPageChanged(120);
      tracker.threshold = const Duration(seconds: 60);
      advance(45);
      tracker.onPageChanged(121);

      expect(read, isEmpty);
      expect(tooShort, [120]);
    });
  });
}
