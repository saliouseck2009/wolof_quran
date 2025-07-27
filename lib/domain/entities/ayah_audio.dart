/// Entity representing an audio file for a specific ayah
class AyahAudio {
  final int surahNumber;
  final int ayahNumber;
  final String reciterId;
  final String localPath;
  final Duration? duration;

  const AyahAudio({
    required this.surahNumber,
    required this.ayahNumber,
    required this.reciterId,
    required this.localPath,
    this.duration,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AyahAudio &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber &&
          ayahNumber == other.ayahNumber &&
          reciterId == other.reciterId;

  @override
  int get hashCode =>
      surahNumber.hashCode ^ ayahNumber.hashCode ^ reciterId.hashCode;

  @override
  String toString() =>
      'AyahAudio(surah: $surahNumber, ayah: $ayahNumber, reciter: $reciterId)';
}
