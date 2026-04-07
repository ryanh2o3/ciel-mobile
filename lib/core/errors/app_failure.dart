import 'package:flutter/foundation.dart';

enum AppFailureKind {
  unauthorized,
  network,
  server,
  invalidResponse,
  unknown,
}

@immutable
class AppFailure {
  const AppFailure({
    required this.kind,
    required this.message,
    this.statusCode,
    this.cause,
  });

  const AppFailure.unauthorized({this.cause})
    : kind = AppFailureKind.unauthorized,
      message = 'Unauthorized',
      statusCode = 401;

  const AppFailure.network({this.message = 'Network error', this.cause})
    : kind = AppFailureKind.network,
      statusCode = null;

  const AppFailure.server({
    this.message = 'Server error',
    this.statusCode,
    this.cause,
  }) : kind = AppFailureKind.server,
       super();

  const AppFailure.unknown({
    this.message = 'Something went wrong. Please try again.',
    this.cause,
  }) : kind = AppFailureKind.unknown,
       statusCode = null;

  final AppFailureKind kind;
  final String message;
  final int? statusCode;
  final Object? cause;

  String get userMessage => message;
}
