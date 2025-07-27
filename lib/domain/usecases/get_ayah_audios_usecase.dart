import '../repositories/audio_repository.dart';
import '../entities/ayah_audio.dart';
import '../../core/usecases/usecase.dart';

/// Parameters for getting ayah audios
class GetAyahAudiosParams {
  final String reciterId;
  final int surahNumber;

  const GetAyahAudiosParams({
    required this.reciterId,
    required this.surahNumber,
  });
}

/// Use case for getting ayah audio files for a surah
class GetAyahAudiosUseCase
    implements UseCase<List<AyahAudio>, GetAyahAudiosParams> {
  final AudioRepository repository;

  GetAyahAudiosUseCase(this.repository);

  @override
  Future<List<AyahAudio>> call({required GetAyahAudiosParams params}) async {
    return await repository.getAyahAudios(params.reciterId, params.surahNumber);
  }
}
