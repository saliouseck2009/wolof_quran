import '../../domain/entities/ayah_audio.dart';

/// Limits of a shared verse video.
abstract final class VerseVideoLimits {
  /// Most verses a video holds, whatever their length: one card is
  /// rendered per verse.
  static const int maxVerses = 20;

  /// Longest video the app builds. A longer one takes too long to
  /// encode and is too heavy to send.
  static const Duration maxDuration = Duration(minutes: 3);

  /// Longest video a WhatsApp status plays in full.
  static const Duration statusDuration = Duration(seconds: 90);
}

enum VerseVideoLength {
  /// Short enough for everything.
  ok,

  /// Can be built, but a WhatsApp status would cut it.
  longForStatus,

  /// Over [VerseVideoLimits.maxDuration]: not built.
  tooLong,
}

/// The downloaded audios of a range of verses of one surah.
class VerseAudioSelection {
  /// Audio of each verse of the range that has one, in reading order.
  final List<AyahAudio> audios;

  /// Verses of the range without a downloaded audio file.
  final List<int> missingVerses;

  const VerseAudioSelection({
    required this.audios,
    required this.missingVerses,
  });

  bool get isComplete => missingVerses.isEmpty && audios.isNotEmpty;

  /// Length of the video, or `null` when an audio is missing or the
  /// length of one of them is not known yet.
  Duration? get totalDuration {
    if (!isComplete) return null;
    var total = Duration.zero;
    for (final audio in audios) {
      final duration = audio.duration;
      if (duration == null) return null;
      total += duration;
    }
    return total;
  }

  /// How [totalDuration] compares to the limits; [VerseVideoLength.ok]
  /// while the length is unknown.
  VerseVideoLength get length {
    final total = totalDuration;
    if (total == null) return VerseVideoLength.ok;
    if (total > VerseVideoLimits.maxDuration) return VerseVideoLength.tooLong;
    if (total > VerseVideoLimits.statusDuration) {
      return VerseVideoLength.longForStatus;
    }
    return VerseVideoLength.ok;
  }

  /// Picks, among the [available] audios of a surah, those of the verses
  /// [firstVerse] to [lastVerse] whose file [fileExists].
  factory VerseAudioSelection.resolve({
    required List<AyahAudio> available,
    required int firstVerse,
    required int lastVerse,
    required bool Function(String path) fileExists,
  }) {
    final byVerse = {for (final audio in available) audio.ayahNumber: audio};
    final audios = <AyahAudio>[];
    final missing = <int>[];
    for (var verse = firstVerse; verse <= lastVerse; verse++) {
      final audio = byVerse[verse];
      if (audio != null &&
          audio.localPath.isNotEmpty &&
          fileExists(audio.localPath)) {
        audios.add(audio);
      } else {
        missing.add(verse);
      }
    }
    return VerseAudioSelection(audios: audios, missingVerses: missing);
  }
}
