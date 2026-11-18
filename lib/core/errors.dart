enum ErrorClass {
  network,
  transient,
  auth,
  forbidden,
  validation,
  conflict,
  notFound,
  local,
  permission,
  unknown,
}

class AppError implements Exception {
  const AppError({
    required this.klass,
    required this.message,
    this.code,
    this.cause,
  });

  final ErrorClass klass;
  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'AppError($klass, $message)';
}
