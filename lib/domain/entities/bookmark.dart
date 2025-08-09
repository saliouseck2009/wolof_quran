/// Entity representing a bookmarked ayah
class BookmarkedAyah {
  final int surahNumber;
  final int verseNumber;
  final String surahName;
  final String arabicText;
  final String translation;
  final String translationSource;
  final DateTime createdAt;

  const BookmarkedAyah({
    required this.surahNumber,
    required this.verseNumber,
    required this.surahName,
    required this.arabicText,
    required this.translation,
    required this.translationSource,
    required this.createdAt,
  });

  /// Create a unique key for this bookmark
  String get key => '${surahNumber}_$verseNumber';

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'verseNumber': verseNumber,
      'surahName': surahName,
      'arabicText': arabicText,
      'translation': translation,
      'translationSource': translationSource,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory BookmarkedAyah.fromJson(Map<String, dynamic> json) {
    return BookmarkedAyah(
      surahNumber: json['surahNumber'] as int,
      verseNumber: json['verseNumber'] as int,
      surahName: json['surahName'] as String,
      arabicText: json['arabicText'] as String,
      translation: json['translation'] as String,
      translationSource: json['translationSource'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkedAyah &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber &&
          verseNumber == other.verseNumber;

  @override
  int get hashCode => surahNumber.hashCode ^ verseNumber.hashCode;

  @override
  String toString() => 'BookmarkedAyah($surahNumber:$verseNumber - $surahName)';
}
