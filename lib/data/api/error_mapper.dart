import 'package:emberday/core/errors.dart';

AppError mapApiError(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('socket') ||
      text.contains('network') ||
      text.contains('failed host')) {
    return AppError(
      klass: ErrorClass.network,
      message: 'Network unavailable',
      cause: error,
    );
  }
  if (text.contains('401') || text.contains('unauthorized')) {
    return AppError(klass: ErrorClass.auth, message: 'Sign in again', cause: error);
  }
  if (text.contains('403') || text.contains('forbidden')) {
    return AppError(
      klass: ErrorClass.forbidden,
      message: 'Not allowed',
      cause: error,
    );
  }
  if (text.contains('409') || text.contains('stale_write')) {
    return AppError(
      klass: ErrorClass.conflict,
      message: 'stale_write',
      code: 'stale_write',
      cause: error,
    );
  }
  if (text.contains('404')) {
    return AppError(
      klass: ErrorClass.notFound,
      message: 'Not found',
      cause: error,
    );
  }
  if (text.contains('429') || text.contains('500') || text.contains('502')) {
    return AppError(
      klass: ErrorClass.transient,
      message: 'Temporary server issue',
      cause: error,
    );
  }
  if (text.contains('400') || text.contains('422')) {
    return AppError(
      klass: ErrorClass.validation,
      message: 'Invalid data',
      cause: error,
    );
  }
  return AppError(
    klass: ErrorClass.unknown,
    message: 'Unexpected error',
    cause: error,
  );
}
