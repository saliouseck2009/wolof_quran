import '../../core/usecases/usecase.dart';
import '../entities/audio_availability_snapshot.dart';
import '../repositories/audio_availability_repository.dart';

class MarkAudioUpdatesSeenUseCase
    implements UseCase<AudioAvailabilitySnapshot?, String> {
  final AudioAvailabilityRepository repository;

  MarkAudioUpdatesSeenUseCase(this.repository);

  @override
  Future<AudioAvailabilitySnapshot?> call({required String params}) async {
    return await repository.markUpdatesAsSeen(params);
  }
}
