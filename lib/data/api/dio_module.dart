import 'package:ciel_mobile/core/config/app_config.dart';
import 'package:ciel_mobile/data/api/auth_interceptor.dart';
import 'package:ciel_mobile/data/auth/auth_token_manager.dart';
import 'package:dio/dio.dart';

/// Builds the shared [Dio] used by repositories.
Dio createAppDio({
  required AppConfig config,
  required AuthTokenManager tokenManager,
}) {
  final base = BaseOptions(
    baseUrl: config.apiBaseUrl,
    contentType: Headers.jsonContentType,
  );

  final refreshDio = Dio(base);

  final dio = Dio(base);
  dio.interceptors.addAll([
    AuthRequestInterceptor(tokenManager),
    AuthRefreshInterceptor(
      tokenManager: tokenManager,
      refreshDio: refreshDio,
      mainDio: dio,
    ),
  ]);
  return dio;
}

/// Presigned S3 PUT — full URL, custom headers, no auth interceptors.
Dio createPresignedUploadDio() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(minutes: 2),
      validateStatus: (code) => code != null && code >= 200 && code < 400,
    ),
  );
}
