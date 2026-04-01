import 'package:equatable/equatable.dart';
import 'package:qcf_quran/qcf_quran.dart' as qcf;
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

Map<int, HizbInfo> _computeHizbQuarterPages() {
  final map = <int, HizbInfo>{};
  for (int juz = 0; juz < 30; juz++) {
    final start = juzStartPages[juz];
    final end = juz < 29 ? juzStartPages[juz + 1] : 605;
    final pages = end - start;
    final hizbBase = juz * 2 + 1;

    const quarters = [
      HizbQuarter.full,
      HizbQuarter.oneQuarter,
      HizbQuarter.half,
      HizbQuarter.threeQuarter,
    ];

    for (int quarterIndex = 0; quarterIndex < 8; quarterIndex++) {
      final page = start + (pages * quarterIndex / 8).round();
      final hizb = hizbBase + (quarterIndex >= 4 ? 1 : 0);
      final quarter = quarters[quarterIndex % 4];
      map[page] = HizbInfo(hizbNumber: hizb, quarter: quarter);
    }
  }
  return map;
}

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
