import '../../core/usecases/usecase.dart';
import '../entities/audio_availability_snapshot.dart';
import '../repositories/audio_availability_repository.dart';

class RefreshAudioAvailabilityParams {
  final String reciterId;
  final bool force;
  final Duration ttl;

  const RefreshAudioAvailabilityParams({
    required this.reciterId,
    this.force = false,
    this.ttl = const Duration(hours: 6),
  });
}

class RefreshAudioAvailabilityUseCase
    implements
        UseCase<AudioAvailabilitySnapshot, RefreshAudioAvailabilityParams> {
  final AudioAvailabilityRepository repository;

  RefreshAudioAvailabilityUseCase(this.repository);

  @override
  Future<AudioAvailabilitySnapshot> call({
    required RefreshAudioAvailabilityParams params,
  }) async {
    return await repository.refreshSnapshot(
      params.reciterId,
      force: params.force,
      ttl: params.ttl,
    );
  }
}
