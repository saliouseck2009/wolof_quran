import 'package:equatable/equatable.dart';

/// A contiguous span of verses from `startSurah:startAyah` to
/// `endSurah:endAyah`, both inclusive. It may span several surahs.
class AyahRange extends Equatable {
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;

  const AyahRange({
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
  });

  bool get isValid =>
      startSurah < endSurah || (startSurah == endSurah && startAyah <= endAyah);

  /// Surahs covered by the range, in reading order.
  List<int> get surahNumbers => [
    for (var surah = startSurah; surah <= endSurah; surah++) surah,
  ];

  /// First verse of [surahNumber] that belongs to the range.
  int firstAyahIn(int surahNumber) => surahNumber == startSurah ? startAyah : 1;

  /// Last verse of [surahNumber] that belongs to the range, [verseCount]
  /// being the number of verses of that surah.
  int lastAyahIn(int surahNumber, {required int verseCount}) =>
      surahNumber == endSurah ? endAyah : verseCount;

  @override
  List<Object?> get props => [startSurah, startAyah, endSurah, endAyah];
}
