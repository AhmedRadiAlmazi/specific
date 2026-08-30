// Result / Either Monad — مشروع «مُعين» (Mouin)
import 'package:mouin/core/errors/failures.dart';

class Result<T, F extends Failure> {
  final T? _value;
  final F? _failure;
  final bool isSuccess;

  const Result.success(T value)
      : _value = value,
        _failure = null,
        isSuccess = true;

  const Result.failure(F failure)
      : _value = null,
        _failure = failure,
        isSuccess = false;

  T get value => _value!;
  F get failure => _failure!;

  R fold<R>(R Function(F failure) onFailure, R Function(T value) onSuccess) {
    if (isSuccess) {
      return onSuccess(_value as T);
    } else {
      return onFailure(_failure as F);
    }
  }
}
