import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/core/errors/app_failure.dart';
import 'package:dio/dio.dart';

AppFailure mapToFailure(Object error) {
  if (error is AppFailure) return error;

  if (error is AppException) {
    final cause = error.cause;
    if (cause is DioException) {
      final status = cause.response?.statusCode;
      if (status == 401) {
        return AppFailure.unauthorized(cause: error);
      }
      if (status != null && status >= 500) {
        return AppFailure.server(
          statusCode: status,
          message: error.message,
          cause: error,
        );
      }
      if (cause.type == DioExceptionType.connectionTimeout ||
          cause.type == DioExceptionType.sendTimeout ||
          cause.type == DioExceptionType.receiveTimeout ||
          cause.type == DioExceptionType.connectionError) {
        return AppFailure.network(message: error.message, cause: error);
      }
      return AppFailure(
        kind: AppFailureKind.unknown,
        message: error.message,
        statusCode: status,
        cause: error,
      );
    }

    if (error.message == 'Unauthorized') {
      return AppFailure.unauthorized(cause: error);
    }

    return AppFailure(
      kind: AppFailureKind.unknown,
      message: error.message,
      cause: error,
    );
  }

  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401) {
      return AppFailure.unauthorized(cause: error);
    }
    if (status != null && status >= 500) {
      return AppFailure.server(statusCode: status);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return AppFailure.network(cause: error);
    }
    return AppFailure.unknown(cause: error);
  }

  return AppFailure.unknown(cause: error);
}
