import '../repositories/download_repository.dart';

class CheckSurahDownloadStatusUseCase {
  final DownloadRepository repository;

  CheckSurahDownloadStatusUseCase(this.repository);

  Future<bool> call(String reciterId, int surahNumber) async {
    return await repository.isSurahDownloaded(reciterId, surahNumber);
  }
}

class MarkSurahDownloadedUseCase {
  final DownloadRepository repository;

  MarkSurahDownloadedUseCase(this.repository);

  Future<void> call(String reciterId, int surahNumber, String filePath) async {
    await repository.markSurahAsDownloaded(reciterId, surahNumber, filePath);
  }
}

class RemoveSurahDownloadUseCase {
  final DownloadRepository repository;

  RemoveSurahDownloadUseCase(this.repository);

  Future<void> call(String reciterId, int surahNumber) async {
    await repository.removeSurahDownload(reciterId, surahNumber);
  }
}
