import '../repositories/audio_repository.dart';
import '../entities/surah_audio_status.dart';
import '../../core/usecases/usecase.dart';

/// Parameters for getting surah audio status
class GetSurahAudioStatusParams {
  final String reciterId;
  final int surahNumber;

  const GetSurahAudioStatusParams({
    required this.reciterId,
    required this.surahNumber,
  });
}

/// Use case for getting surah audio status
class GetSurahAudioStatusUseCase
    implements UseCase<SurahAudioStatus, GetSurahAudioStatusParams> {
  final AudioRepository repository;

  GetSurahAudioStatusUseCase(this.repository);

  @override
  Future<SurahAudioStatus> call({
    required GetSurahAudioStatusParams params,
  }) async {
    return await repository.getSurahAudioStatus(
      params.reciterId,
      params.surahNumber,
    );
  }
}
