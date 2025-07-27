/// Entity representing a Quran reciter
class Reciter {
  final String id;
  final String name;
  final String arabicName;
  final bool isAvailable;

  const Reciter({
    required this.id,
    required this.name,
    required this.arabicName,
    this.isAvailable = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reciter && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Reciter(id: $id, name: $name)';
}
