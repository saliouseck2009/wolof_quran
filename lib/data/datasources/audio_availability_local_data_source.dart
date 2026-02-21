import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/audio_availability_snapshot.dart';

class AudioAvailabilityLocalDataSource {
  static const String _snapshotKeyPrefix = 'audio_availability_snapshot_';

  String _snapshotKeyForReciter(String reciterId) =>
      '$_snapshotKeyPrefix$reciterId';

  Future<AudioAvailabilitySnapshot?> getSnapshot(String reciterId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_snapshotKeyForReciter(reciterId));
    if (rawJson == null || rawJson.isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(rawJson);
      if (decoded is! Map) {
        return null;
      }
      final normalized = decoded.map((key, value) => MapEntry('$key', value));
      final snapshot = AudioAvailabilitySnapshot.fromJson(normalized);
      if (snapshot.reciterId.trim().isEmpty) {
        return snapshot.copyWith(reciterId: reciterId);
      }
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSnapshot(AudioAvailabilitySnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _snapshotKeyForReciter(snapshot.reciterId),
      json.encode(snapshot.toJson()),
    );
  }
}
