import '../repositories/audio_repository.dart';
import '../../core/usecases/usecase.dart';

/// Parameters for downloading surah audio
class DownloadSurahAudioParams {
  final String reciterId;
  final int surahNumber;
  final Function(double progress)? onProgress;

  const DownloadSurahAudioParams({
    required this.reciterId,
    required this.surahNumber,
    this.onProgress,
  });
}

/// Use case for downloading surah audio
class DownloadSurahAudioUseCase
    implements UseCase<void, DownloadSurahAudioParams> {
  final AudioRepository repository;

  DownloadSurahAudioUseCase(this.repository);

  @override
  Future<void> call({required DownloadSurahAudioParams params}) async {
    await repository.downloadSurahAudio(
      params.reciterId,
      params.surahNumber,
      onProgress: params.onProgress,
    );
  }
}
