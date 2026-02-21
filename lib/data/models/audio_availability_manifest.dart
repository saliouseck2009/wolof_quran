class AudioAvailabilityManifest {
  final int schemaVersion;
  final DateTime? generatedAt;
  final List<AudioReciterAvailabilityEntry> reciters;

  const AudioAvailabilityManifest({
    required this.schemaVersion,
    required this.generatedAt,
    required this.reciters,
  });

  AudioReciterAvailabilityEntry? reciterById(String reciterId) {
    try {
      return reciters.firstWhere((entry) => entry.id == reciterId);
    } catch (_) {
      return null;
    }
  }

  factory AudioAvailabilityManifest.fromJson(Map<String, dynamic> json) {
    if (json['reciters'] is! List) {
      throw const FormatException(
        'Invalid availability manifest: "reciters" must be a list',
      );
    }

    final rawSchemaVersion = json['schemaVersion'];
    final schemaVersion = rawSchemaVersion is int
        ? rawSchemaVersion
        : int.tryParse('$rawSchemaVersion') ?? 1;

    final rawGeneratedAt = json['generatedAt'];
    final generatedAt = rawGeneratedAt is String
        ? DateTime.tryParse(rawGeneratedAt)
        : null;

    final reciters = (json['reciters'] as List).whereType<Map>().map((entry) {
      final normalized = entry.map((key, value) => MapEntry('$key', value));
      return AudioReciterAvailabilityEntry.fromJson(normalized);
    }).toList();

    return AudioAvailabilityManifest(
      schemaVersion: schemaVersion,
      generatedAt: generatedAt,
      reciters: reciters,
    );
  }
}

class AudioReciterAvailabilityEntry {
  final String id;
  final int catalogVersion;
  final List<int> availableSurahs;

  const AudioReciterAvailabilityEntry({
    required this.id,
    required this.catalogVersion,
    required this.availableSurahs,
  });

  factory AudioReciterAvailabilityEntry.fromJson(Map<String, dynamic> json) {
    if ((json['id'] == null || '${json['id']}'.trim().isEmpty)) {
      throw const FormatException(
        'Invalid availability manifest: reciter id is missing',
      );
    }

    final rawCatalogVersion = json['catalogVersion'];
    final catalogVersion = rawCatalogVersion is int
        ? rawCatalogVersion
        : int.tryParse('$rawCatalogVersion') ?? 0;

    List<int> parseAvailableSurahs(dynamic raw) {
      if (raw is! List) {
        return const [];
      }
      final list =
          raw
              .map((item) => item is int ? item : int.tryParse('$item'))
              .whereType<int>()
              .where((value) => value > 0)
              .toSet()
              .toList()
            ..sort();
      return list;
    }

    return AudioReciterAvailabilityEntry(
      id: '${json['id']}',
      catalogVersion: catalogVersion,
      availableSurahs: parseAvailableSurahs(json['availableSurahs']),
    );
  }
}
