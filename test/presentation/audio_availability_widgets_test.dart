import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wolof_quran/core/services/audio_player_service.dart';
import 'package:wolof_quran/data/models/downloaded_surah.dart';
import 'package:wolof_quran/domain/entities/audio_availability_snapshot.dart';
import 'package:wolof_quran/domain/entities/ayah_audio.dart';
import 'package:wolof_quran/domain/entities/reciter.dart';
import 'package:wolof_quran/domain/entities/surah_audio_status.dart';
import 'package:wolof_quran/domain/repositories/audio_availability_repository.dart';
import 'package:wolof_quran/domain/repositories/audio_repository.dart';
import 'package:wolof_quran/domain/repositories/download_repository.dart';
import 'package:wolof_quran/domain/usecases/download_surah_audio_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_ayah_audios_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_cached_audio_availability_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_downloaded_surahs_usecase.dart';
import 'package:wolof_quran/domain/usecases/get_surah_audio_status_usecase.dart';
import 'package:wolof_quran/domain/usecases/mark_audio_updates_seen_usecase.dart';
import 'package:wolof_quran/domain/usecases/refresh_audio_availability_usecase.dart';
import 'package:wolof_quran/l10n/generated/app_localizations.dart';
import 'package:wolof_quran/presentation/blocs/surah_download_status_bloc.dart';
import 'package:wolof_quran/presentation/cubits/audio_availability_cubit.dart';
import 'package:wolof_quran/presentation/cubits/audio_management_cubit.dart';
import 'package:wolof_quran/presentation/cubits/ayah_playback_cubit.dart';
import 'package:wolof_quran/presentation/cubits/quran_settings_cubit.dart';
import 'package:wolof_quran/presentation/cubits/surah_detail_cubit.dart';
import 'package:wolof_quran/presentation/widgets/ayah_play_button.dart';
import 'package:wolof_quran/presentation/widgets/quran_settings/quran_settings_menu.dart';
import 'package:wolof_quran/presentation/widgets/reciter_chapters/chapter_card.dart';
import 'package:wolof_quran/presentation/widgets/surah_detail/surah_detail_app_bar.dart';
import 'package:wolof_quran/presentation/widgets/surah_detail/surah_detail_play_button.dart';
import 'package:wolof_quran/service_locator.dart';

class _InMemoryAudioAvailabilityRepository
    implements AudioAvailabilityRepository {
  final Map<String, AudioAvailabilitySnapshot> _storage;

  _InMemoryAudioAvailabilityRepository(List<AudioAvailabilitySnapshot> values)
    : _storage = {for (final value in values) value.reciterId: value};

  @override
  Future<AudioAvailabilitySnapshot?> getCachedSnapshot(String reciterId) async {
    return _storage[reciterId];
  }

  @override
  Future<AudioAvailabilitySnapshot?> markUpdatesAsSeen(String reciterId) async {
    final snapshot = _storage[reciterId];
    if (snapshot == null) {
      return null;
    }
    final updated = snapshot.copyWith(unreadNewSurahs: const []);
    _storage[reciterId] = updated;
    return updated;
  }

  @override
  Future<AudioAvailabilitySnapshot> refreshSnapshot(
    String reciterId, {
    bool force = false,
    Duration ttl = const Duration(hours: 6),
  }) async {
    final snapshot = _storage[reciterId];
    if (snapshot == null) {
      throw Exception('Missing snapshot');
    }
    return snapshot;
  }
}

class _FakeAudioRepository implements AudioRepository {
  @override
  Future<void> deleteSurahAudio(String reciterId, int surahNumber) async {}

  @override
  Future<void> downloadSurahAudio(
    String reciterId,
    int surahNumber, {
    Function(double p1)? onProgress,
  }) async {}

  @override
  Future<List<AyahAudio>> getAyahAudios(String reciterId, int surahNumber) {
    return Future.value(const []);
  }

  @override
  Future<List<int>> getDownloadedSurahs(String reciterId) {
    return Future.value(const []);
  }

  @override
  Future<String> getSurahAudioPath(String reciterId, int surahNumber) {
    return Future.value('');
  }

  @override
  Future<void> warmUpAyahDurations(String reciterId, int surahNumber) async {}

  @override
  Future<SurahAudioStatus> getSurahAudioStatus(
    String reciterId,
    int surahNumber,
  ) {
    return Future.value(
      SurahAudioStatus(reciterId: reciterId, surahNumber: surahNumber),
    );
  }

  @override
  Future<bool> isSurahAudioDownloaded(String reciterId, int surahNumber) {
    return Future.value(false);
  }
}

class _FakeDownloadRepository implements DownloadRepository {
  @override
  Future<DownloadedSurah?> getDownloadedSurah(
    String reciterId,
    int surahNumber,
  ) {
    return Future.value(null);
  }

  @override
  Future<List<DownloadedSurah>> getDownloadedSurahs(String reciterId) {
    return Future.value(const []);
  }

  @override
  Future<Map<String, int>> getDownloadStats(String reciterId) {
    return Future.value({'total': 0, 'completed': 0});
  }

  @override
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) {
    return Future.value(false);
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

class _TestQuranSettingsCubit extends QuranSettingsCubit {
  void setSelectedReciter(Reciter reciter) {
    emit(state.copyWith(selectedReciter: reciter));
  }
}

class _SpyAudioManagementCubit extends AudioManagementCubit {
  int downloadCallCount = 0;
  String? lastReciterId;
  int? lastSurahNumber;

  _SpyAudioManagementCubit()
    : super(
        downloadSurahAudioUseCase: DownloadSurahAudioUseCase(
          _FakeAudioRepository(),
        ),
        getSurahAudioStatusUseCase: GetSurahAudioStatusUseCase(
          _FakeAudioRepository(),
        ),
        getAyahAudiosUseCase: GetAyahAudiosUseCase(_FakeAudioRepository()),
        audioPlayerService: AudioPlayerService(),
        downloadRepository: _FakeDownloadRepository(),
      ) {
    initialize();
  }

  @override
  Future<void> downloadSurahAudio(String reciterId, int surahNumber) async {
    downloadCallCount += 1;
    lastReciterId = reciterId;
    lastSurahNumber = surahNumber;
  }
}

class _ModalSpyAudioManagementCubit extends _SpyAudioManagementCubit {
  @override
  Future<void> refreshSurahStatus(String reciterId, int surahNumber) async {}

  @override
  bool isSurahDownloaded(String reciterId, int surahNumber) {
    return false;
  }
}

class _FixedSurahDownloadStatusBloc extends SurahDownloadStatusBloc {
  _FixedSurahDownloadStatusBloc({
    required String reciterId,
    required int surahNumber,
    bool isDownloaded = false,
  }) : super(
         getDownloadedSurahsUseCase: GetDownloadedSurahsUseCase(
           _FakeDownloadRepository(),
         ),
       ) {
    emit(
      SurahDownloadStatusLoaded(
        isDownloaded: isDownloaded,
        reciterId: reciterId,
        surahNumber: surahNumber,
      ),
    );
  }

  @override
  void add(SurahDownloadStatusEvent event) {
    // Keep a deterministic state in widget tests.
  }
}

Widget _buildLocalizedApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audio availability widgets', () {
    const reciter = Reciter(
      id: 'imamsarr',
      name: 'Imam Sarr',
      arabicName: 'Imam',
    );

    testWidgets('shows badge and hides it after markAsSeen', (tester) async {
      final availabilityRepository = _InMemoryAudioAvailabilityRepository([
        AudioAvailabilitySnapshot(
          reciterId: reciter.id,
          catalogVersion: 2,
          availableSurahs: const [1, 2, 3],
          unreadNewSurahs: const [2, 3],
          lastCheckedAt: DateTime.now(),
        ),
      ]);
      final availabilityCubit = AudioAvailabilityCubit(
        refreshAudioAvailabilityUseCase: RefreshAudioAvailabilityUseCase(
          availabilityRepository,
        ),
        getCachedAudioAvailabilityUseCase: GetCachedAudioAvailabilityUseCase(
          availabilityRepository,
        ),
        markAudioUpdatesSeenUseCase: MarkAudioUpdatesSeenUseCase(
          availabilityRepository,
        ),
      );
      await availabilityCubit.refreshReciter(reciter.id, force: true);

      await tester.pumpWidget(
        _buildLocalizedApp(
          BlocProvider<AudioAvailabilityCubit>.value(
            value: availabilityCubit,
            child: Builder(
              builder: (context) {
                return QuranSettingsMenu(
                  state: const QuranSettingsState(selectedReciter: reciter),
                  localizations: AppLocalizations.of(context)!,
                  onTranslationTap: () {},
                  onFontSizeTap: () {},
                  onRecitersTap: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New (2)'), findsOneWidget);

      await availabilityCubit.markAsSeen(reciter.id);
      await tester.pumpAndSettle();

      expect(find.text('New (2)'), findsNothing);
      await availabilityCubit.close();
    });

    testWidgets('ChapterCard disables download for unavailable surah', (
      tester,
    ) async {
      final audioRepository = _FakeAudioRepository();
      if (locator.isRegistered<AudioRepository>()) {
        locator.unregister<AudioRepository>();
      }
      locator.registerLazySingleton<AudioRepository>(() => audioRepository);
      final audioManagementCubit = AudioManagementCubit(
        downloadSurahAudioUseCase: DownloadSurahAudioUseCase(audioRepository),
        getSurahAudioStatusUseCase: GetSurahAudioStatusUseCase(audioRepository),
        getAyahAudiosUseCase: GetAyahAudiosUseCase(audioRepository),
        audioPlayerService: AudioPlayerService(),
        downloadRepository: _FakeDownloadRepository(),
      )..initialize();

      await tester.pumpWidget(
        _buildLocalizedApp(
          BlocProvider<AudioManagementCubit>.value(
            value: audioManagementCubit,
            child: Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context)!;
                return ChapterCard(
                  reciter: reciter,
                  surahNumber: 10,
                  translation: quran.Translation.enSaheeh,
                  isDark: false,
                  isDownloaded: false,
                  isAvailableRemotely: false,
                  accentGreen: Colors.green,
                  darkSurfaceHigh: Colors.black12,
                  getSurahDisplayName: (number) => 'Surah $number',
                  localizations: localizations,
                  onDownloadComplete: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not yet available'), findsOneWidget);
      expect(find.byIcon(Icons.download_for_offline_outlined), findsOneWidget);
      await audioManagementCubit.close();
      if (locator.isRegistered<AudioRepository>()) {
        locator.unregister<AudioRepository>();
      }
    });

    testWidgets(
      'SurahPlayButton shows not yet available when remote surah is unavailable',
      (tester) async {
        final audioRepository = _FakeAudioRepository();
        if (locator.isRegistered<AudioRepository>()) {
          locator.unregister<AudioRepository>();
        }
        locator.registerLazySingleton<AudioRepository>(() => audioRepository);
        final audioManagementCubit = AudioManagementCubit(
          downloadSurahAudioUseCase: DownloadSurahAudioUseCase(audioRepository),
          getSurahAudioStatusUseCase: GetSurahAudioStatusUseCase(
            audioRepository,
          ),
          getAyahAudiosUseCase: GetAyahAudiosUseCase(audioRepository),
          audioPlayerService: AudioPlayerService(),
          downloadRepository: _FakeDownloadRepository(),
        )..initialize();

        final availabilityRepository = _InMemoryAudioAvailabilityRepository([
          AudioAvailabilitySnapshot(
            reciterId: reciter.id,
            catalogVersion: 2,
            availableSurahs: const [1],
            unreadNewSurahs: const [],
            lastCheckedAt: DateTime.now(),
          ),
        ]);
        final availabilityCubit = AudioAvailabilityCubit(
          refreshAudioAvailabilityUseCase: RefreshAudioAvailabilityUseCase(
            availabilityRepository,
          ),
          getCachedAudioAvailabilityUseCase: GetCachedAudioAvailabilityUseCase(
            availabilityRepository,
          ),
          markAudioUpdatesSeenUseCase: MarkAudioUpdatesSeenUseCase(
            availabilityRepository,
          ),
        );
        await availabilityCubit.refreshReciter(reciter.id, force: true);

        final quranSettingsCubit = _TestQuranSettingsCubit()
          ..setSelectedReciter(reciter);
        final surahStatusBloc = _FixedSurahDownloadStatusBloc(
          reciterId: reciter.id,
          surahNumber: 2,
        );

        await tester.pumpWidget(
          _buildLocalizedApp(
            MultiBlocProvider(
              providers: [
                BlocProvider<QuranSettingsCubit>.value(
                  value: quranSettingsCubit,
                ),
                BlocProvider<AudioManagementCubit>.value(
                  value: audioManagementCubit,
                ),
                BlocProvider<AudioAvailabilityCubit>.value(
                  value: availabilityCubit,
                ),
                BlocProvider<SurahDownloadStatusBloc>.value(
                  value: surahStatusBloc,
                ),
              ],
              child: const SurahPlayButton(
                surahNumber: 2,
                surahName: 'Al-Baqara',
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Not yet available'), findsOneWidget);
      },
    );

    testWidgets('SurahDetailAppBar shows "number - translated name"', (
      tester,
    ) async {
      if (locator.isRegistered<GetDownloadedSurahsUseCase>()) {
        locator.unregister<GetDownloadedSurahsUseCase>();
      }
      locator.registerLazySingleton<GetDownloadedSurahsUseCase>(
        () => GetDownloadedSurahsUseCase(_FakeDownloadRepository()),
      );

      final quranSettingsCubit = QuranSettingsCubit();
      final state = SurahDetailLoaded(
        surahNumber: 2,
        surahNameArabic: 'البقرة',
        surahNameEnglish: 'Al-Baqara',
        surahNameTranslated: 'The Cow',
        versesCount: 286,
        ayahs: [],
        translationSource: 'Sahih International',
      );

      await tester.pumpWidget(
        _buildLocalizedApp(
          BlocProvider<QuranSettingsCubit>.value(
            value: quranSettingsCubit,
            child: CustomScrollView(slivers: [SurahDetailAppBar(state: state)]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 - The Cow'), findsOneWidget);

      await quranSettingsCubit.close();
      if (locator.isRegistered<GetDownloadedSurahsUseCase>()) {
        locator.unregister<GetDownloadedSurahsUseCase>();
      }
    });

    testWidgets(
      'SurahPlayButton icon variant hides labels and triggers direct download',
      (tester) async {
        if (locator.isRegistered<AudioRepository>()) {
          locator.unregister<AudioRepository>();
        }
        locator.registerLazySingleton<AudioRepository>(
          () => _FakeAudioRepository(),
        );

        final audioManagementCubit = _SpyAudioManagementCubit();

        final availabilityRepository = _InMemoryAudioAvailabilityRepository([
          AudioAvailabilitySnapshot(
            reciterId: reciter.id,
            catalogVersion: 2,
            availableSurahs: const [2],
            unreadNewSurahs: const [],
            lastCheckedAt: DateTime.now(),
          ),
        ]);
        final availabilityCubit = AudioAvailabilityCubit(
          refreshAudioAvailabilityUseCase: RefreshAudioAvailabilityUseCase(
            availabilityRepository,
          ),
          getCachedAudioAvailabilityUseCase: GetCachedAudioAvailabilityUseCase(
            availabilityRepository,
          ),
          markAudioUpdatesSeenUseCase: MarkAudioUpdatesSeenUseCase(
            availabilityRepository,
          ),
        );
        await availabilityCubit.refreshReciter(reciter.id, force: true);

        final quranSettingsCubit = _TestQuranSettingsCubit()
          ..setSelectedReciter(reciter);
        final surahStatusBloc = _FixedSurahDownloadStatusBloc(
          reciterId: reciter.id,
          surahNumber: 2,
          isDownloaded: false,
        );

        await tester.pumpWidget(
          _buildLocalizedApp(
            MultiBlocProvider(
              providers: [
                BlocProvider<QuranSettingsCubit>.value(
                  value: quranSettingsCubit,
                ),
                BlocProvider<AudioManagementCubit>.value(
                  value: audioManagementCubit,
                ),
                BlocProvider<AudioAvailabilityCubit>.value(
                  value: availabilityCubit,
                ),
                BlocProvider<SurahDownloadStatusBloc>.value(
                  value: surahStatusBloc,
                ),
              ],
              child: const SurahPlayButton(
                surahNumber: 2,
                surahName: 'Al-Baqara',
                variant: SurahPlayButtonVariant.icon,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(SurahPlayButton.iconActionKey), findsOneWidget);
        expect(find.text('Download to play'), findsNothing);
        expect(find.text('Play Surah'), findsNothing);
        expect(audioManagementCubit.downloadCallCount, 0);
        final button = tester.widget<IconButton>(
          find.byKey(SurahPlayButton.iconActionKey),
        );
        expect(button.onPressed, isNotNull);
        button.onPressed!.call();
        await tester.pump();
        expect(audioManagementCubit.downloadCallCount, 1);
        expect(audioManagementCubit.lastReciterId, reciter.id);
        expect(audioManagementCubit.lastSurahNumber, 2);

        await quranSettingsCubit.close();
        await availabilityCubit.close();
        await audioManagementCubit.close();
        if (locator.isRegistered<AudioRepository>()) {
          locator.unregister<AudioRepository>();
        }
      },
    );

    testWidgets(
      'SurahPlayButton icon variant is disabled when surah is unavailable remotely',
      (tester) async {
        final audioRepository = _FakeAudioRepository();
        if (locator.isRegistered<AudioRepository>()) {
          locator.unregister<AudioRepository>();
        }
        locator.registerLazySingleton<AudioRepository>(() => audioRepository);

        final audioManagementCubit = AudioManagementCubit(
          downloadSurahAudioUseCase: DownloadSurahAudioUseCase(audioRepository),
          getSurahAudioStatusUseCase: GetSurahAudioStatusUseCase(
            audioRepository,
          ),
          getAyahAudiosUseCase: GetAyahAudiosUseCase(audioRepository),
          audioPlayerService: AudioPlayerService(),
          downloadRepository: _FakeDownloadRepository(),
        )..initialize();

        final availabilityRepository = _InMemoryAudioAvailabilityRepository([
          AudioAvailabilitySnapshot(
            reciterId: reciter.id,
            catalogVersion: 2,
            availableSurahs: const [1],
            unreadNewSurahs: const [],
            lastCheckedAt: DateTime.now(),
          ),
        ]);
        final availabilityCubit = AudioAvailabilityCubit(
          refreshAudioAvailabilityUseCase: RefreshAudioAvailabilityUseCase(
            availabilityRepository,
          ),
          getCachedAudioAvailabilityUseCase: GetCachedAudioAvailabilityUseCase(
            availabilityRepository,
          ),
          markAudioUpdatesSeenUseCase: MarkAudioUpdatesSeenUseCase(
            availabilityRepository,
          ),
        );
        await availabilityCubit.refreshReciter(reciter.id, force: true);

        final quranSettingsCubit = _TestQuranSettingsCubit()
          ..setSelectedReciter(reciter);
        final surahStatusBloc = _FixedSurahDownloadStatusBloc(
          reciterId: reciter.id,
          surahNumber: 2,
          isDownloaded: false,
        );

        await tester.pumpWidget(
          _buildLocalizedApp(
            MultiBlocProvider(
              providers: [
                BlocProvider<QuranSettingsCubit>.value(
                  value: quranSettingsCubit,
                ),
                BlocProvider<AudioManagementCubit>.value(
                  value: audioManagementCubit,
                ),
                BlocProvider<AudioAvailabilityCubit>.value(
                  value: availabilityCubit,
                ),
                BlocProvider<SurahDownloadStatusBloc>.value(
                  value: surahStatusBloc,
                ),
              ],
              child: const SurahPlayButton(
                surahNumber: 2,
                surahName: 'Al-Baqara',
                variant: SurahPlayButtonVariant.icon,
              ),
            ),
          ),
        );
        await tester.pump();

        final button = tester.widget<IconButton>(
          find.byKey(SurahPlayButton.iconActionKey),
        );
        expect(button.onPressed, isNull);
        expect(find.text('Not yet available'), findsNothing);
        expect(
          find.byIcon(Icons.download_for_offline_outlined),
          findsOneWidget,
        );

        await quranSettingsCubit.close();
        await availabilityCubit.close();
        await audioManagementCubit.close();
        if (locator.isRegistered<AudioRepository>()) {
          locator.unregister<AudioRepository>();
        }
      },
    );

    testWidgets(
      'AyahPlayButton opens modal and downloads surah when confirmed',
      (tester) async {
        if (locator.isRegistered<AudioRepository>()) {
          locator.unregister<AudioRepository>();
        }
        locator.registerLazySingleton<AudioRepository>(
          () => _FakeAudioRepository(),
        );

        final audioManagementCubit = _ModalSpyAudioManagementCubit();
        final availabilityRepository = _InMemoryAudioAvailabilityRepository([
          AudioAvailabilitySnapshot(
            reciterId: reciter.id,
            catalogVersion: 2,
            availableSurahs: const [2],
            unreadNewSurahs: const [],
            lastCheckedAt: DateTime.now(),
          ),
        ]);
        final availabilityCubit = AudioAvailabilityCubit(
          refreshAudioAvailabilityUseCase: RefreshAudioAvailabilityUseCase(
            availabilityRepository,
          ),
          getCachedAudioAvailabilityUseCase: GetCachedAudioAvailabilityUseCase(
            availabilityRepository,
          ),
          markAudioUpdatesSeenUseCase: MarkAudioUpdatesSeenUseCase(
            availabilityRepository,
          ),
        );
        await availabilityCubit.refreshReciter(reciter.id, force: true);

        final quranSettingsCubit = _TestQuranSettingsCubit()
          ..setSelectedReciter(reciter);
        final ayahPlaybackCubit = AyahPlaybackCubit(
          audioPlayerService: AudioPlayerService(),
          audioManagementCubit: audioManagementCubit,
        );

        await tester.pumpWidget(
          _buildLocalizedApp(
            MultiBlocProvider(
              providers: [
                BlocProvider<QuranSettingsCubit>.value(
                  value: quranSettingsCubit,
                ),
                BlocProvider<AudioManagementCubit>.value(
                  value: audioManagementCubit,
                ),
                BlocProvider<AudioAvailabilityCubit>.value(
                  value: availabilityCubit,
                ),
                BlocProvider<AyahPlaybackCubit>.value(value: ayahPlaybackCubit),
              ],
              child: const AyahPlayButton(
                surahNumber: 2,
                ayahNumber: 5,
                surahName: 'Al-Baqara',
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pumpAndSettle();

        expect(
          find.text('Audio not available. Please download the surah first.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Download'));
        await tester.pumpAndSettle();

        expect(audioManagementCubit.downloadCallCount, 1);
        expect(audioManagementCubit.lastReciterId, reciter.id);
        expect(audioManagementCubit.lastSurahNumber, 2);

        await quranSettingsCubit.close();
        await availabilityCubit.close();
        await ayahPlaybackCubit.close();
        await audioManagementCubit.close();
        if (locator.isRegistered<AudioRepository>()) {
          locator.unregister<AudioRepository>();
        }
      },
    );
  });
}
