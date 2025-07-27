import '../../domain/entities/reciter.dart';
import '../../domain/repositories/reciter_repository.dart';
import '../datasources/reciter_data_source.dart';

/// Implementation of ReciterRepository
class ReciterRepositoryImpl implements ReciterRepository {
  final ReciterDataSource localDataSource;

  ReciterRepositoryImpl(this.localDataSource);

  @override
  Future<List<Reciter>> getReciters() async {
    return await localDataSource.getReciters();
  }

  @override
  Future<Reciter?> getReciterById(String id) async {
    return await localDataSource.getReciterById(id);
  }

  @override
  Future<Reciter?> getSelectedReciter() async {
    final selectedId = await localDataSource.getSelectedReciterId();
    if (selectedId != null) {
      return await localDataSource.getReciterById(selectedId);
    }

    // Return default reciter if none selected
    final reciters = await localDataSource.getReciters();
    if (reciters.isNotEmpty) {
      await setSelectedReciter(reciters.first.id);
      return reciters.first;
    }

    return null;
  }

  @override
  Future<void> setSelectedReciter(String reciterId) async {
    await localDataSource.setSelectedReciterId(reciterId);
  }
}
