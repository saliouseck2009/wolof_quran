import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolof_quran/data/datasources/audio_availability_local_data_source.dart';
import 'package:wolof_quran/data/datasources/audio_availability_remote_data_source.dart';
import 'package:wolof_quran/data/models/audio_availability_manifest.dart';
import 'package:wolof_quran/data/repositories/audio_availability_repository_impl.dart';
import 'package:wolof_quran/domain/entities/audio_availability_snapshot.dart';

class _FakeLocalDataSource extends AudioAvailabilityLocalDataSource {
  AudioAvailabilitySnapshot? storedSnapshot;
  int saveCalls = 0;

  @override
  Future<AudioAvailabilitySnapshot?> getSnapshot(String reciterId) async {
    return storedSnapshot;
  }

  @override
  Future<void> saveSnapshot(AudioAvailabilitySnapshot snapshot) async {
    storedSnapshot = snapshot;
    saveCalls++;
  }
}

class _FakeRemoteDataSource extends AudioAvailabilityRemoteDataSource {
  _FakeRemoteDataSource() : super(Dio());

  AudioReciterAvailabilityEntry? nextAvailability;
  Object? nextError;
  int fetchCalls = 0;

  @override
  Future<AudioReciterAvailabilityEntry?> fetchReciterAvailability(
    String reciterId,
  ) async {
    fetchCalls++;
    if (nextError != null) {
      throw nextError!;
    }
    return nextAvailability;
  }
}

void main() {
  group('AudioAvailabilityRepositoryImpl', () {
    late _FakeLocalDataSource localDataSource;
    late _FakeRemoteDataSource remoteDataSource;
    late AudioAvailabilityRepositoryImpl repository;

    setUp(() {
      localDataSource = _FakeLocalDataSource();
      remoteDataSource = _FakeRemoteDataSource();
      repository = AudioAvailabilityRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
    });

    test('first sync creates baseline with no unread updates', () async {
      remoteDataSource.nextAvailability = const AudioReciterAvailabilityEntry(
        id: 'imamsarr',
        catalogVersion: 1,
        availableSurahs: [1, 2, 3],
      );

      final snapshot = await repository.refreshSnapshot(
        'imamsarr',
        force: true,
      );

      expect(snapshot.availableSurahs, [1, 2, 3]);
      expect(snapshot.unreadNewSurahs, isEmpty);
      expect(snapshot.catalogVersion, 1);
      expect(localDataSource.storedSnapshot, isNotNull);
    });

    test('sync computes new surahs as unread updates', () async {
      localDataSource.storedSnapshot = AudioAvailabilitySnapshot(
        reciterId: 'imamsarr',
        catalogVersion: 1,
        availableSurahs: const [1, 2],
        unreadNewSurahs: const [],
        lastCheckedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      remoteDataSource.nextAvailability = const AudioReciterAvailabilityEntry(
        id: 'imamsarr',
        catalogVersion: 2,
        availableSurahs: [1, 2, 3, 4],
      );

      final snapshot = await repository.refreshSnapshot(
        'imamsarr',
        force: true,
      );

      expect(snapshot.availableSurahs, [1, 2, 3, 4]);
      expect(snapshot.unreadNewSurahs, [3, 4]);
      expect(snapshot.catalogVersion, 2);
    });

    test('markUpdatesAsSeen clears unread updates', () async {
      localDataSource.storedSnapshot = AudioAvailabilitySnapshot(
        reciterId: 'imamsarr',
        catalogVersion: 3,
        availableSurahs: const [1, 2, 3],
        unreadNewSurahs: const [3],
        lastCheckedAt: DateTime.now(),
      );

      final snapshot = await repository.markUpdatesAsSeen('imamsarr');

      expect(snapshot, isNotNull);
      expect(snapshot!.unreadNewSurahs, isEmpty);
      expect(localDataSource.storedSnapshot!.unreadNewSurahs, isEmpty);
    });

    test('ttl uses cache and skips remote call when fresh', () async {
      localDataSource.storedSnapshot = AudioAvailabilitySnapshot(
        reciterId: 'imamsarr',
        catalogVersion: 3,
        availableSurahs: const [1, 2, 3],
        unreadNewSurahs: const [],
        lastCheckedAt: DateTime.now(),
      );
      remoteDataSource.nextAvailability = const AudioReciterAvailabilityEntry(
        id: 'imamsarr',
        catalogVersion: 4,
        availableSurahs: [1, 2, 3, 4],
      );

      final snapshot = await repository.refreshSnapshot(
        'imamsarr',
        force: false,
        ttl: const Duration(hours: 6),
      );

      expect(remoteDataSource.fetchCalls, 0);
      expect(snapshot.availableSurahs, [1, 2, 3]);
      expect(snapshot.catalogVersion, 3);
    });
  });
}
