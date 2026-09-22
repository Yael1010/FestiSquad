sealed class OfflineState<T> {
  const OfflineState();
}

class OfflineLoading<T> extends OfflineState<T> {
  const OfflineLoading();
}

class OfflineData<T> extends OfflineState<T> {
  const OfflineData(this.value, {required this.fromCache});

  final T value;
  final bool fromCache;
}

class OfflineFailure<T> extends OfflineState<T> {
  const OfflineFailure(this.message);

  final String message;
}
