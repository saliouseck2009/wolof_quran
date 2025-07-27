import '../entities/reciter.dart';

/// Repository interface for managing reciters
abstract class ReciterRepository {
  /// Get all available reciters
  Future<List<Reciter>> getReciters();

  /// Get a specific reciter by ID
  Future<Reciter?> getReciterById(String id);

  /// Get the currently selected reciter
  Future<Reciter?> getSelectedReciter();

  /// Set the selected reciter
  Future<void> setSelectedReciter(String reciterId);
}
