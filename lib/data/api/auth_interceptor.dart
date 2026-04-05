import 'package:ciel_mobile/data/auth/auth_token_manager.dart';
import 'package:ciel_mobile/data/dto/auth_dtos.dart';
import 'package:dio/dio.dart';

/// Attaches `Authorization: Bearer` when an access token is present.
class AuthRequestInterceptor extends Interceptor {
  AuthRequestInterceptor(this._tokens);

  final AuthTokenManager _tokens;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra['skipAuthHeader'] == true) {
      return handler.next(options);
    }
    final access = _tokens.accessToken;
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    return handler.next(options);
  }
}

/// On 401: refresh once (singleflight), retry original request (Swift `APIClient`).
class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor({
    required AuthTokenManager tokenManager,
    required Dio refreshDio,
    required Dio mainDio,
  })  : _tokens = tokenManager,
        _refreshDio = refreshDio,
        _mainDio = mainDio;

  final AuthTokenManager _tokens;
  final Dio _refreshDio;
  final Dio _mainDio;

  Future<void>? _refreshInFlight;

  Future<void> _refreshTokens() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<void> _doRefresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) {
      throw StateError('missing_refresh_token');
    }
    final res = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: refreshRequestJson(refreshToken: refresh),
    );
    final data = res.data;
    if (data == null) {
      throw StateError('empty_refresh_response');
    }
    final tokens = AuthTokensDto.fromJson(data);
    await _tokens.setTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status != 401) {
      return handler.next(err);
    }

    final path = err.requestOptions.uri.path;
    if (path.endsWith('/auth/login') || path.endsWith('/auth/refresh')) {
      return handler.next(err);
    }
    if (err.requestOptions.extra['authRetryUsed'] == true) {
      return handler.next(err);
    }

    try {
      await _refreshTokens();
      final access = _tokens.accessToken;
      if (access == null || access.isEmpty) {
        await _tokens.clear();
        return handler.next(err);
      }
      final req = err.requestOptions.copyWith(
        headers: Map<String, dynamic>.from(err.requestOptions.headers)
          ..['Authorization'] = 'Bearer $access',
        extra: Map<String, dynamic>.from(err.requestOptions.extra)..['authRetryUsed'] = true,
      );
      final response = await _mainDio.fetch<dynamic>(req);
      return handler.resolve(response);
    } catch (_) {
      await _tokens.clear();
      return handler.next(err);
    }
  }
}
