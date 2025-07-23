class InternetException implements Exception {
  final String message;
  InternetException(this.message);
  @override
  String toString() {
    return message;
  }
}

class ClientException implements Exception {
  static const clientCode = "CLIENT_CODE";
  final String message;
  ClientException(this.message);
  @override
  String toString() {
    return message;
  }
}
