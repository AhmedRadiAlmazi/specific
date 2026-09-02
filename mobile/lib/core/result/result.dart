// Functional Result Type — مشروع «مُعين» (Mouin)
class Result<T, E> {
  final T? _value;
  final E? _failure;
  final bool isSuccess;

  const Result.success(T value)
      : _value = value,
        _failure = null,
        isSuccess = true;

  const Result.failure(E failure)
      : _value = null,
        _failure = failure,
        isSuccess = false;

  T get value {
    if (!isSuccess) throw StateError('Cannot access value of a failure Result');
    return _value as T;
  }

  E get failure {
    if (isSuccess) throw StateError('Cannot access failure of a success Result');
    return _failure as E;
  }

  R fold<R>(R Function(T value) onSuccess, R Function(E failure) onFailure) {
    if (isSuccess) {
      return onSuccess(_value as T);
    } else {
      return onFailure(_failure as E);
    }
  }
}
