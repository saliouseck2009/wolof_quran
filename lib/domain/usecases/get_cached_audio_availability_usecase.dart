import '../../core/usecases/usecase.dart';
import '../entities/audio_availability_snapshot.dart';
import '../repositories/audio_availability_repository.dart';

class GetCachedAudioAvailabilityUseCase
    implements UseCase<AudioAvailabilitySnapshot?, String> {
  final AudioAvailabilityRepository repository;

  GetCachedAudioAvailabilityUseCase(this.repository);

  @override
  Future<AudioAvailabilitySnapshot?> call({required String params}) async {
    return await repository.getCachedSnapshot(params);
  }
}
