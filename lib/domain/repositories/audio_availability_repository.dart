import '../entities/audio_availability_snapshot.dart';

abstract class AudioAvailabilityRepository {
  Future<AudioAvailabilitySnapshot?> getCachedSnapshot(String reciterId);

  Future<AudioAvailabilitySnapshot> refreshSnapshot(
    String reciterId, {
    bool force = false,
    Duration ttl = const Duration(hours: 6),
  });

  Future<AudioAvailabilitySnapshot?> markUpdatesAsSeen(String reciterId);
}
