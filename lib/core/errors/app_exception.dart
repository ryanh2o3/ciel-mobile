/// Typed failure for API / auth flows (presentation maps to user-visible text).
class AppException implements Exception {
  AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
