import 'package:equatable/equatable.dart';

/// Snapshot of a reciter remote audio catalog and unread updates.
class AudioAvailabilitySnapshot extends Equatable {
  final String reciterId;
  final int catalogVersion;
  final List<int> availableSurahs;
  final List<int> unreadNewSurahs;
  final DateTime? lastCheckedAt;

  const AudioAvailabilitySnapshot({
    required this.reciterId,
    required this.catalogVersion,
    required this.availableSurahs,
    required this.unreadNewSurahs,
    required this.lastCheckedAt,
  });

  bool get hasUnreadUpdates => unreadNewSurahs.isNotEmpty;

  AudioAvailabilitySnapshot copyWith({
    String? reciterId,
    int? catalogVersion,
    List<int>? availableSurahs,
    List<int>? unreadNewSurahs,
    DateTime? lastCheckedAt,
    bool clearLastCheckedAt = false,
  }) {
    return AudioAvailabilitySnapshot(
      reciterId: reciterId ?? this.reciterId,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      availableSurahs: availableSurahs ?? this.availableSurahs,
      unreadNewSurahs: unreadNewSurahs ?? this.unreadNewSurahs,
      lastCheckedAt: clearLastCheckedAt
          ? null
          : (lastCheckedAt ?? this.lastCheckedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reciterId': reciterId,
      'catalogVersion': catalogVersion,
      'availableSurahs': availableSurahs,
      'unreadNewSurahs': unreadNewSurahs,
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
    };
  }

  factory AudioAvailabilitySnapshot.fromJson(Map<String, dynamic> json) {
    List<int> parseSurahList(dynamic raw) {
      if (raw is! List) {
        return const [];
      }
      final values =
          raw
              .map((item) => item is int ? item : int.tryParse('$item'))
              .whereType<int>()
              .where((value) => value > 0)
              .toSet()
              .toList()
            ..sort();
      return values;
    }

    final rawCatalogVersion = json['catalogVersion'];
    final catalogVersion = rawCatalogVersion is int
        ? rawCatalogVersion
        : int.tryParse('$rawCatalogVersion') ?? 0;

    final rawLastCheckedAt = json['lastCheckedAt'];
    final lastCheckedAt = rawLastCheckedAt is String
        ? DateTime.tryParse(rawLastCheckedAt)
        : null;

    return AudioAvailabilitySnapshot(
      reciterId: '${json['reciterId'] ?? ''}',
      catalogVersion: catalogVersion,
      availableSurahs: parseSurahList(json['availableSurahs']),
      unreadNewSurahs: parseSurahList(json['unreadNewSurahs']),
      lastCheckedAt: lastCheckedAt,
    );
  }

  @override
  List<Object?> get props => [
    reciterId,
    catalogVersion,
    availableSurahs,
    unreadNewSurahs,
    lastCheckedAt,
  ];
}
