// Typed Failures Taxonomy — مشروع «مُعين» (Mouin)
abstract class Failure {
  final String message;
  final String? code;
  const Failure(this.message, [this.code]);

  @override
  String toString() => '$runtimeType: $message (${code ?? "NO_CODE"})';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, [super.code]);
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

class ConflictFailure extends Failure {
  const ConflictFailure(super.message, [super.code]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, [super.code]);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.code]);
}

class SyncFailure extends Failure {
  const SyncFailure(super.message, [super.code]);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code]);
}
