import '../../domain/entities/reciter.dart';

/// Data source for managing reciter data
abstract class ReciterDataSource {
  Future<List<Reciter>> getReciters();
  Future<Reciter?> getReciterById(String id);
  Future<String?> getSelectedReciterId();
  Future<void> setSelectedReciterId(String reciterId);
}
