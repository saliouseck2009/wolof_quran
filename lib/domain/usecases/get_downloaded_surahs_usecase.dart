import '../../core/usecases/usecase.dart';
import '../../data/models/downloaded_surah.dart';
import '../repositories/download_repository.dart';

class GetDownloadedSurahsUseCase
    implements UseCase<List<DownloadedSurah>, String> {
  final DownloadRepository repository;

  GetDownloadedSurahsUseCase(this.repository);

  @override
  Future<List<DownloadedSurah>> call({required String params}) async {
    return await repository.getDownloadedSurahs(params);
  }
}
