import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/reciter.dart';
import '../datasources/reciter_data_source.dart';

/// Local implementation of ReciterDataSource using SharedPreferences
class ReciterLocalDataSource implements ReciterDataSource {
  static const String _selectedReciterKey = 'selected_reciter_id';

  @override
  Future<List<Reciter>> getReciters() async {
    // For now, we only support Imam Sarr
    // This can be expanded in the future to load from a remote source
    return const [
      Reciter(
        id: 'imamsarr',
        name: 'Imam Sarr',
        arabicName: 'إمام سار',
        isAvailable: true,
      ),
    ];
  }

  @override
  Future<Reciter?> getReciterById(String id) async {
    final reciters = await getReciters();
    try {
      return reciters.firstWhere((reciter) => reciter.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getSelectedReciterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedReciterKey);
  }

  @override
  Future<void> setSelectedReciterId(String reciterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedReciterKey, reciterId);
  }
}
