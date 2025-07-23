extension ListX<T> on List<T> {
  T? firstOrNullWhere(bool Function(T) condition) {
    for (var item in this) {
      if (condition(item)) {
        return item;
      }
    }
    return null;
  }
}
