abstract class UseCase<T, P> {
  Future<T> call({required P params});
}

/// Empty parameter class for use cases that don't require parameters
class NoParams {
  const NoParams();
}
