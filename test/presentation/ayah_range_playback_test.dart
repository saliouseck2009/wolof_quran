import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolof_quran/core/services/audio_player_service.dart';
import 'package:wolof_quran/data/models/downloaded_surah.dart';
import 'package:wolof_quran/domain/entities/ayah_audio.dart';
import 'package:wolof_quran/domain/entities/ayah_range.dart';
import 'package:wolof_quran/domain/entities/surah_audio_status.dart';
import 'package:wolof_quran/domain/repositories/audio_repository.dart';
import 'package:wolof_quran/domain/repositories/download_repository.dart';
import 'package:wolof_quran/l10n/generated/app_localizations.dart';
import 'package:wolof_quran/presentation/cubits/surah_mini_player_cubit.dart';
import 'package:wolof_quran/presentation/widgets/ayah_range_play_sheet.dart';

class _FakeAudioRepository implements AudioRepository {
  final Map<int, List<int>> ayahsBySurah;

  _FakeAudioRepository(this.ayahsBySurah);

  @override
  Future<void> deleteSurahAudio(String reciterId, int surahNumber) async {}

  @override
  Future<void> downloadSurahAudio(
    String reciterId,
    int surahNumber, {
    Function(double p1)? onProgress,
  }) async {}

  @override
  Future<List<AyahAudio>> getAyahAudios(
    String reciterId,
    int surahNumber,
  ) async {
    return [
      for (final ayah in ayahsBySurah[surahNumber] ?? const <int>[])
        AyahAudio(
          surahNumber: surahNumber,
          ayahNumber: ayah,
          reciterId: reciterId,
          localPath: '/tmp/$surahNumber-$ayah.mp3',
          duration: const Duration(seconds: 5),
        ),
    ];
  }

  @override
  Future<List<int>> getDownloadedSurahs(String reciterId) async {
    return ayahsBySurah.keys.toList();
  }

  @override
  Future<String> getSurahAudioPath(String reciterId, int surahNumber) async {
    return '/tmp/$reciterId/$surahNumber';
  }

  @override
  Future<SurahAudioStatus> getSurahAudioStatus(
    String reciterId,
    int surahNumber,
  ) async {
    return SurahAudioStatus(reciterId: reciterId, surahNumber: surahNumber);
  }

  @override
  Future<bool> isSurahAudioDownloaded(String reciterId, int surahNumber) async {
    return ayahsBySurah.containsKey(surahNumber);
  }

  @override
  Future<void> warmUpAyahDurations(String reciterId, int surahNumber) async {}
}

class _FakeDownloadRepository implements DownloadRepository {
  final List<DownloadedSurah> downloaded;

  _FakeDownloadRepository(this.downloaded);

  @override
  bool tryStartSurahDownload(String reciterId, int surahNumber) => true;

  @override
  void finishSurahDownload(String reciterId, int surahNumber) {}

  @override
  bool isSurahDownloadInProgress(String reciterId, int surahNumber) => false;

  @override
  Future<DownloadedSurah?> getDownloadedSurah(
    String reciterId,
    int surahNumber,
  ) async {
    return null;
  }

  @override
  Future<List<DownloadedSurah>> getDownloadedSurahs(String reciterId) async {
    return downloaded;
  }

  @override
  Future<Map<String, int>> getDownloadStats(String reciterId) async {
    return <String, int>{'total': 0, 'completed': 0};
  }

  @override
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    return downloaded.any(
      (item) => item.surahNumber == surahNumber && item.isComplete,
    );
  }

  @override
  Future<void> markSurahAsDownloaded(
    String reciterId,
    int surahNumber,
    String filePath,
  ) async {}

  @override
  Future<void> markSurahAsInProgress(
    String reciterId,
    int surahNumber,
    String filePath,
  ) async {}

  @override
  Future<void> removeSurahDownload(String reciterId, int surahNumber) async {}
}

DownloadedSurah _downloaded(int surahNumber, {bool isComplete = true}) {
  return DownloadedSurah(
    reciterId: 'imamsarr',
    surahNumber: surahNumber,
    filePath: '/tmp/$surahNumber',
    isComplete: isComplete,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = AudioPlayerService();
    await service.initialize();
    await service.stop();
  });

  group('PlayingAudioInfo.verseNumber', () {
    test('returns the verse itself for single ayah playback', () {
      const info = PlayingAudioInfo(
        surahNumber: 2,
        ayahNumber: 255,
        reciterId: 'imamsarr',
      );
      expect(info.verseNumber, 255);
    });

    test('maps a full surah playlist index to its verse', () {
      const info = PlayingAudioInfo(
        surahNumber: 2,
        ayahNumber: 4,
        reciterId: 'imamsarr',
        isPlaylist: true,
      );
      expect(info.verseNumber, 5);
    });

    test('offsets a verse range playlist index by the range start', () {
      const info = PlayingAudioInfo(
        surahNumber: 2,
        ayahNumber: 3,
        reciterId: 'imamsarr',
        isPlaylist: true,
        firstAyahNumber: 255,
      );
      expect(info.verseNumber, 258);
    });
  });

  group('AyahRange', () {
    const range = AyahRange(
      startSurah: 2,
      startAyah: 284,
      endSurah: 4,
      endAyah: 3,
    );

    test('lists every surah of the range', () {
      expect(range.surahNumbers, <int>[2, 3, 4]);
    });

    test('bounds verses of each surah', () {
      expect(range.firstAyahIn(2), 284);
      expect(range.lastAyahIn(2, verseCount: 286), 286);
      expect(range.firstAyahIn(3), 1);
      expect(range.lastAyahIn(3, verseCount: 200), 200);
      expect(range.firstAyahIn(4), 1);
      expect(range.lastAyahIn(4, verseCount: 176), 3);
    });

    test('is invalid when the end precedes the start', () {
      expect(range.isValid, isTrue);
      expect(
        const AyahRange(
          startSurah: 2,
          startAyah: 10,
          endSurah: 2,
          endAyah: 9,
        ).isValid,
        isFalse,
      );
    });
  });

  group('SurahMiniPlayerCubit verse range', () {
    test('reports surahs of the range that are not fully downloaded', () async {
      final cubit = SurahMiniPlayerCubit(
        audioPlayerService: AudioPlayerService(),
        downloadRepository: _FakeDownloadRepository([
          _downloaded(2),
          _downloaded(3, isComplete: false),
        ]),
        audioRepository: _FakeAudioRepository(const {}),
      );
      addTearDown(cubit.close);

      final missing = await cubit.missingSurahsForRange(
        reciterId: 'imamsarr',
        range: const AyahRange(
          startSurah: 2,
          startAyah: 280,
          endSurah: 4,
          endAyah: 2,
        ),
      );

      expect(missing, <int>[3, 4]);
    });

    test('does not play a range when a verse file is missing', () async {
      final service = AudioPlayerService();
      final cubit = SurahMiniPlayerCubit(
        audioPlayerService: service,
        downloadRepository: _FakeDownloadRepository([_downloaded(1)]),
        // Verse 5 of Al-Fatiha is missing on the device.
        audioRepository: _FakeAudioRepository(const {
          1: <int>[1, 2, 3, 4, 6, 7],
        }),
      );
      addTearDown(cubit.close);

      final result = await cubit.playAyahRange(
        reciterId: 'imamsarr',
        range: const AyahRange(
          startSurah: 1,
          startAyah: 3,
          endSurah: 1,
          endAyah: 7,
        ),
      );

      expect(result, AyahRangePlaybackResult.audioMissing);
      expect(service.isPlayingRange, isFalse);
    });
  });

  group('showAyahRangePlaySheet', () {
    /// Opens the sheet for [surahNumber]:[ayahNumber]; the picked range is
    /// stored in the returned list once the sheet closes.
    Future<List<AyahRange?>> openSheet(
      WidgetTester tester, {
      required int surahNumber,
      required int ayahNumber,
    }) async {
      final results = <AyahRange?>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  results.add(
                    await showAyahRangePlaySheet(
                      context,
                      surahNumber: surahNumber,
                      ayahNumber: ayahNumber,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('plays until the end of the surah by default', (tester) async {
      final results = await openSheet(tester, surahNumber: 2, ayahNumber: 255);

      expect(find.text('2:255'), findsOneWidget);
      expect(find.text('2:286'), findsOneWidget);
      await tester.tap(find.text('Play 32 verses'));
      await tester.pumpAndSettle();

      expect(results, const <AyahRange?>[
        AyahRange(startSurah: 2, startAyah: 255, endSurah: 2, endAyah: 286),
      ]);
    });

    testWidgets('keeps the play button above the system navigation bar', (
      tester,
    ) async {
      // 48 logical pixels of navigation bar, set in physical pixels.
      final navigationBar = 48 * tester.view.devicePixelRatio;
      tester.view.padding = FakeViewPadding(bottom: navigationBar);
      tester.view.viewPadding = FakeViewPadding(bottom: navigationBar);
      addTearDown(tester.view.reset);
      await openSheet(tester, surahNumber: 2, ayahNumber: 255);

      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final buttonBottom = tester
          .getBottomLeft(find.widgetWithText(FilledButton, 'Play 32 verses'))
          .dy;
      expect(buttonBottom, lessThanOrEqualTo(screenHeight - 48));
    });

    testWidgets('custom range uses quick choices and the verse picker', (
      tester,
    ) async {
      final results = await openSheet(tester, surahNumber: 2, ayahNumber: 255);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      // The custom range starts and ends on the current verse.
      expect(find.text('Play 1 verse'), findsOneWidget);

      await tester.tap(find.text('+10 verses'));
      await tester.pumpAndSettle();
      expect(find.text('2:264'), findsOneWidget);

      await tester.tap(find.text('2:264'));
      await tester.pumpAndSettle();
      expect(find.text('Choose the last verse'), findsOneWidget);
      // Verses before the range start cannot be picked.
      await tester.tap(find.text('250'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Choose the last verse'), findsOneWidget);

      await tester.tap(find.text('270'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play 16 verses'));
      await tester.pumpAndSettle();

      expect(results, const <AyahRange?>[
        AyahRange(startSurah: 2, startAyah: 255, endSurah: 2, endAyah: 270),
      ]);
    });
  });
}
