import 'package:uuid/uuid.dart';

class Helpers {
  /// Generates a random UUID using the package:uuid library.
  static String getRandomUuid() {
    return const Uuid().v1();
  }
}
