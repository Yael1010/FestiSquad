import 'dart:async';

typedef RetryDelay = Future<void> Function(Duration duration);

class RetryPolicy {
  const RetryPolicy({
    this.maxRetries = 2,
    this.initialDelay = const Duration(milliseconds: 150),
  });

  final int maxRetries;
  final Duration initialDelay;

  Future<T> execute<T>(
    Future<T> Function() operation, {
    required bool Function(Object error) shouldRetry,
    RetryDelay delay = Future<void>.delayed,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (error) {
        if (attempt >= maxRetries || !shouldRetry(error)) rethrow;
        final multiplier = 1 << attempt;
        await delay(initialDelay * multiplier);
        attempt++;
      }
    }
  }
}
