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
