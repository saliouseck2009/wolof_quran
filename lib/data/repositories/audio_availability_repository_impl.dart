import '../../domain/entities/audio_availability_snapshot.dart';
import '../../domain/repositories/audio_availability_repository.dart';
import '../datasources/audio_availability_local_data_source.dart';
import '../datasources/audio_availability_remote_data_source.dart';
import '../models/audio_availability_manifest.dart';

class AudioAvailabilityRepositoryImpl implements AudioAvailabilityRepository {
  final AudioAvailabilityRemoteDataSource remoteDataSource;
  final AudioAvailabilityLocalDataSource localDataSource;

  AudioAvailabilityRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<AudioAvailabilitySnapshot?> getCachedSnapshot(String reciterId) async {
    return await localDataSource.getSnapshot(reciterId);
  }

  @override
  Future<AudioAvailabilitySnapshot> refreshSnapshot(
    String reciterId, {
    bool force = false,
    Duration ttl = const Duration(hours: 1),
  }) async {
    final cachedSnapshot = await localDataSource.getSnapshot(reciterId);
    final now = DateTime.now();

    if (!force &&
        cachedSnapshot?.lastCheckedAt != null &&
        now.difference(cachedSnapshot!.lastCheckedAt!) < ttl) {
      return cachedSnapshot;
    }

    AudioReciterAvailabilityEntry? remoteAvailability;
    try {
      remoteAvailability = await remoteDataSource.fetchReciterAvailability(
        reciterId,
      );
    } catch (_) {
      if (cachedSnapshot != null) {
        return cachedSnapshot;
      }
      rethrow;
    }

    if (remoteAvailability == null) {
      if (cachedSnapshot != null) {
        final unchangedSnapshot = cachedSnapshot.copyWith(lastCheckedAt: now);
        await localDataSource.saveSnapshot(unchangedSnapshot);
        return unchangedSnapshot;
      }

      final emptyBaseline = AudioAvailabilitySnapshot(
        reciterId: reciterId,
        catalogVersion: 0,
        availableSurahs: const [],
        unreadNewSurahs: const [],
        lastCheckedAt: now,
      );
      await localDataSource.saveSnapshot(emptyBaseline);
      return emptyBaseline;
    }

    final normalizedRemoteSurahs = _normalizeSurahList(
      remoteAvailability.availableSurahs,
    );

    if (cachedSnapshot == null) {
      final baselineSnapshot = AudioAvailabilitySnapshot(
        reciterId: reciterId,
        catalogVersion: remoteAvailability.catalogVersion,
        availableSurahs: normalizedRemoteSurahs,
        unreadNewSurahs: const [],
        lastCheckedAt: now,
      );
      await localDataSource.saveSnapshot(baselineSnapshot);
      return baselineSnapshot;
    }

    final previousSet = cachedSnapshot.availableSurahs.toSet();
    final newlyAvailable =
        normalizedRemoteSurahs
            .where((surahNumber) => !previousSet.contains(surahNumber))
            .toList()
          ..sort();

    final updatedUnread = {
      ...cachedSnapshot.unreadNewSurahs,
      ...newlyAvailable,
    }.toList()..sort();

    final refreshedSnapshot = AudioAvailabilitySnapshot(
      reciterId: reciterId,
      catalogVersion: remoteAvailability.catalogVersion,
      availableSurahs: normalizedRemoteSurahs,
      unreadNewSurahs: updatedUnread,
      lastCheckedAt: now,
    );
    await localDataSource.saveSnapshot(refreshedSnapshot);
    return refreshedSnapshot;
  }

  @override
  Future<AudioAvailabilitySnapshot?> markUpdatesAsSeen(String reciterId) async {
    final cachedSnapshot = await localDataSource.getSnapshot(reciterId);
    if (cachedSnapshot == null) {
      return null;
    }

    final updatedSnapshot = cachedSnapshot.copyWith(unreadNewSurahs: const []);
    await localDataSource.saveSnapshot(updatedSnapshot);
    return updatedSnapshot;
  }

  List<int> _normalizeSurahList(List<int> surahNumbers) {
    return surahNumbers.where((value) => value > 0).toSet().toList()..sort();
  }
}
