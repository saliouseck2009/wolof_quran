import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/domain/entities/ayah_audio.dart';
import 'package:wolof_quran/presentation/utils/verse_video_selection.dart';

AyahAudio _audio(int verse, {int? seconds, String? path}) => AyahAudio(
  surahNumber: 2,
  ayahNumber: verse,
  reciterId: 'reciter',
  localPath: path ?? '/audio/$verse.mp3',
  duration: seconds == null ? null : Duration(seconds: seconds),
);

VerseAudioSelection _resolve(
  List<AyahAudio> available, {
  required int first,
  required int last,
  Set<String> missingFiles = const {},
}) => VerseAudioSelection.resolve(
  available: available,
  firstVerse: first,
  lastVerse: last,
  fileExists: (path) => !missingFiles.contains(path),
);

void main() {
  group('VerseAudioSelection.resolve', () {
    test('keeps the audios of the range, in reading order', () {
      final selection = _resolve(
        [_audio(4), _audio(1), _audio(3), _audio(2), _audio(5)],
        first: 2,
        last: 4,
      );

      expect(selection.audios.map((audio) => audio.ayahNumber), [2, 3, 4]);
      expect(selection.missingVerses, isEmpty);
      expect(selection.isComplete, isTrue);
    });

    test('lists the verses without a usable file', () {
      final selection = _resolve(
        [_audio(1), _audio(2), _audio(3, path: ''), _audio(5)],
        first: 1,
        last: 5,
        missingFiles: {'/audio/2.mp3'},
      );

      expect(selection.audios.map((audio) => audio.ayahNumber), [1, 5]);
      expect(selection.missingVerses, [2, 3, 4]);
      expect(selection.isComplete, isFalse);
    });

    test('nothing downloaded is not complete', () {
      final selection = _resolve(const [], first: 1, last: 2);

      expect(selection.missingVerses, [1, 2]);
      expect(selection.isComplete, isFalse);
    });
  });

  group('video length', () {
    test('is the sum of the audios', () {
      final selection = _resolve(
        [_audio(1, seconds: 20), _audio(2, seconds: 35)],
        first: 1,
        last: 2,
      );

      expect(selection.totalDuration, const Duration(seconds: 55));
      expect(selection.length, VerseVideoLength.ok);
    });

    test('is unknown when one audio has no length yet', () {
      final selection = _resolve(
        [_audio(1, seconds: 400), _audio(2)],
        first: 1,
        last: 2,
      );

      expect(selection.totalDuration, isNull);
      expect(selection.length, VerseVideoLength.ok);
    });

    test('is unknown when an audio is missing', () {
      final selection = _resolve([_audio(1, seconds: 20)], first: 1, last: 2);

      expect(selection.totalDuration, isNull);
    });

    test('at the status limit is still ok', () {
      final selection = _resolve([_audio(1, seconds: 90)], first: 1, last: 1);

      expect(selection.length, VerseVideoLength.ok);
    });

    test('over the status limit is flagged but allowed', () {
      final selection = _resolve([_audio(1, seconds: 91)], first: 1, last: 1);

      expect(selection.length, VerseVideoLength.longForStatus);
    });

    test('over the maximum is too long', () {
      final selection = _resolve(
        [_audio(1, seconds: 180), _audio(2, seconds: 1)],
        first: 1,
        last: 2,
      );

      expect(selection.length, VerseVideoLength.tooLong);
    });
  });
}
