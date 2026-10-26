import 'package:equatable/equatable.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:quran/quran.dart' as quran;

enum QuranSectionType { juz, hizb, surah }

/// A juz, hizb or surah expressed as mushaf pages. Sections can start or
/// end in the middle of a page: [sharesFirstPage] and [sharesLastPage] flag
/// pages also covered by the neighbouring section, so the user can confirm
/// whether such a page is fully read.
class QuranSection extends Equatable {
  final QuranSectionType type;
  final int number;
  final int firstPage;
  final int lastPage;
  final bool sharesFirstPage;
  final bool sharesLastPage;

  const QuranSection({
    required this.type,
    required this.number,
    required this.firstPage,
    required this.lastPage,
    required this.sharesFirstPage,
    required this.sharesLastPage,
  });

  List<int> get pages => [for (var p = firstPage; p <= lastPage; p++) p];

  int get pageCount => lastPage - firstPage + 1;

  /// Pages of the section, optionally leaving out the shared boundary
  /// pages the user did not confirm.
  List<int> pagesIncluding({
    required bool sharedFirst,
    required bool sharedLast,
  }) {
    return pages.where((page) {
      if (page == firstPage && sharesFirstPage && !sharedFirst) {
        return false;
      }
      if (page == lastPage && sharesLastPage && !sharedLast) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  List<Object?> get props => [
    type,
    number,
    firstPage,
    lastPage,
    sharesFirstPage,
    sharesLastPage,
  ];
}

/// Page ranges of every juz, hizb and surah, computed once from the
/// mushaf data.
class QuranSections {
  const QuranSections._();

  static const juzCount = 30;
  static const hizbCount = 60;
  static const surahCount = 114;

  static final Map<QuranSectionType, List<QuranSection>> _cache = {};

  static List<QuranSection> of(QuranSectionType type) {
    return _cache.putIfAbsent(type, () {
      switch (type) {
        case QuranSectionType.juz:
          return [
            for (var n = 1; n <= juzCount; n++)
              _fromQuarters(type, n, (n - 1) * 8, n == juzCount ? null : n * 8),
          ];
        case QuranSectionType.hizb:
          return [
            for (var n = 1; n <= hizbCount; n++)
              _fromQuarters(
                type,
                n,
                (n - 1) * 4,
                n == hizbCount ? null : n * 4,
              ),
          ];
        case QuranSectionType.surah:
          return [
            for (var s = 1; s <= surahCount; s++)
              _section(type, s, s, 1, s, quran.getVerseCount(s)),
          ];
      }
    });
  }

  static QuranSection get(QuranSectionType type, int number) =>
      of(type)[number - 1];

  /// Section starting at quarter index [startIndex] and ending just before
  /// quarter index [endIndex] (`null` for the end of the Quran).
  static QuranSection _fromQuarters(
    QuranSectionType type,
    int number,
    int startIndex,
    int? endIndex,
  ) {
    final start = qcf.quarters[startIndex];
    final startSurah = start['surah'] as int;
    final startAyah = start['ayah'] as int;
    final int endSurah;
    final int endAyah;
    if (endIndex == null) {
      endSurah = surahCount;
      endAyah = quran.getVerseCount(surahCount);
    } else {
      final next = qcf.quarters[endIndex];
      final nextSurah = next['surah'] as int;
      final nextAyah = next['ayah'] as int;
      if (nextAyah > 1) {
        endSurah = nextSurah;
        endAyah = nextAyah - 1;
      } else {
        endSurah = nextSurah - 1;
        endAyah = quran.getVerseCount(nextSurah - 1);
      }
    }
    return _section(type, number, startSurah, startAyah, endSurah, endAyah);
  }

  static QuranSection _section(
    QuranSectionType type,
    int number,
    int startSurah,
    int startAyah,
    int endSurah,
    int endAyah,
  ) {
    final firstPage = qcf.getPageNumber(startSurah, startAyah);
    final lastPage = qcf.getPageNumber(endSurah, endAyah);
    return QuranSection(
      type: type,
      number: number,
      firstPage: firstPage,
      lastPage: lastPage,
      sharesFirstPage: !_startsPage(firstPage, startSurah, startAyah),
      sharesLastPage: !_endsPage(lastPage, endSurah, endAyah),
    );
  }

  /// Whether verse [surah]:[ayah] is the first verse printed on [page].
  static bool _startsPage(int page, int surah, int ayah) {
    final segments = qcf.getPageData(page);
    if (segments.isEmpty) {
      return true;
    }
    final first = segments.first;
    return _toInt(first['surah']) == surah && _toInt(first['start']) == ayah;
  }

  /// Whether verse [surah]:[ayah] is the last verse printed on [page].
  static bool _endsPage(int page, int surah, int ayah) {
    final segments = qcf.getPageData(page);
    if (segments.isEmpty) {
      return true;
    }
    final last = segments.last;
    return _toInt(last['surah']) == surah && _toInt(last['end']) == ayah;
  }

  static int _toInt(Object? value) => int.parse(value.toString());
}
