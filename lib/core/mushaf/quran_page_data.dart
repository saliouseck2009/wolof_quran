import 'package:equatable/equatable.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:quran/quran.dart' as quran;

import '../../l10n/generated/app_localizations.dart';

const List<int> juzStartPages = [
  1,
  22,
  42,
  62,
  82,
  102,
  121,
  142,
  162,
  182,
  201,
  222,
  242,
  262,
  282,
  302,
  322,
  342,
  362,
  382,
  402,
  422,
  442,
  462,
  482,
  502,
  522,
  542,
  562,
  582,
];

enum HizbQuarter { full, oneQuarter, half, threeQuarter }

class HizbInfo extends Equatable {
  final int hizbNumber;
  final HizbQuarter quarter;

  const HizbInfo({required this.hizbNumber, required this.quarter});

  String localizedText(AppLocalizations l10n) {
    switch (quarter) {
      case HizbQuarter.full:
        return l10n.hizbFull(hizbNumber);
      case HizbQuarter.oneQuarter:
        return l10n.hizbOneQuarter(hizbNumber);
      case HizbQuarter.half:
        return l10n.hizbHalf(hizbNumber);
      case HizbQuarter.threeQuarter:
        return l10n.hizbThreeQuarter(hizbNumber);
    }
  }

  @override
  List<Object?> get props => [hizbNumber, quarter];
}

class PageInfo extends Equatable {
  final int pageNumber;
  final int juzNumber;
  final int primarySurahNumber;
  final String surahNameArabic;
  final String surahNameEnglish;
  final HizbInfo? hizbInfo;

  const PageInfo({
    required this.pageNumber,
    required this.juzNumber,
    required this.primarySurahNumber,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    this.hizbInfo,
  });

  @override
  List<Object?> get props => [
    pageNumber,
    juzNumber,
    primarySurahNumber,
    surahNameArabic,
    surahNameEnglish,
    hizbInfo,
  ];
}

final Map<int, HizbInfo> _hizbQuarterPages = _computeHizbQuarterPages();

/// The page each quarter of a hizb starts on, from the 240 rub el hizb
/// positions of the mushaf (surah and verse of each one).
Map<int, HizbInfo> _computeHizbQuarterPages() {
  const quarters = [
    HizbQuarter.full,
    HizbQuarter.oneQuarter,
    HizbQuarter.half,
    HizbQuarter.threeQuarter,
  ];
  final map = <int, HizbInfo>{};
  for (var index = 0; index < qcf.quarters.length; index++) {
    final start = qcf.quarters[index] as Map;
    final page = qcf.getPageNumber(start['surah'] as int, start['ayah'] as int);
    // Should two quarters start on one page, the page shows the first.
    map.putIfAbsent(
      page,
      () => HizbInfo(hizbNumber: index ~/ 4 + 1, quarter: quarters[index % 4]),
    );
  }
  return map;
}

/// The quarter of a hizb that starts on [pageNumber], or `null` when none
/// does.
HizbInfo? getHizbInfoForPage(int pageNumber) {
  return _hizbQuarterPages[pageNumber];
}

PageInfo getPageInfo(int pageNumber) {
  final pageData = qcf.getPageData(pageNumber);
  final firstSegment = pageData.first;
  final surahNumber = int.parse(firstSegment['surah'].toString());
  final verseNumber = int.parse(firstSegment['start'].toString());

  return PageInfo(
    pageNumber: pageNumber,
    juzNumber: qcf.getJuzNumber(surahNumber, verseNumber),
    primarySurahNumber: surahNumber,
    surahNameArabic: quran.getSurahNameArabic(surahNumber),
    surahNameEnglish: quran.getSurahNameEnglish(surahNumber),
    hizbInfo: getHizbInfoForPage(pageNumber),
  );
}

int getFirstPageOfSurah(int surahNumber) {
  return qcf.getPageNumber(surahNumber, 1);
}
