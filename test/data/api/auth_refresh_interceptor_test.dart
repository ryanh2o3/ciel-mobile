import 'dart:async';
import 'dart:convert';

import 'package:ciel_mobile/data/api/auth_interceptor.dart';
import 'package:ciel_mobile/data/auth/auth_token_manager.dart';
import 'package:ciel_mobile/data/local/secure_refresh_token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRefreshTokenStore extends SecureRefreshTokenStore {
  _FakeRefreshTokenStore(this._token) : super();

  String? _token;

  @override
  Future<String?> readRefreshToken() async => _token;

  @override
  Future<void> writeRefreshToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final FutureOr<_FakeResponse> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final resp = await _handler(options);
    return ResponseBody.fromString(
      jsonEncode(resp.data),
      resp.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _FakeResponse {
  _FakeResponse(this.statusCode, this.data);

  final int statusCode;
  final Object? data;
}

Map<String, dynamic> _tokenJson({
  required String access,
  required String refresh,
}) {
  return <String, dynamic>{
    'access_token': access,
    'refresh_token': refresh,
    'access_expires_at': DateTime.utc(2030).toIso8601String(),
    'refresh_expires_at': DateTime.utc(2030).toIso8601String(),
  };
}

void main() {
  test('401 triggers refresh and retries original request', () async {
    final store = _FakeRefreshTokenStore('r1');
    final tokens = AuthTokenManager(store);
    await tokens.setTokens(accessToken: 'old_access', refreshToken: 'r1');

    var refreshCalls = 0;
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _FakeAdapter((options) async {
        if (options.uri.path.endsWith('/auth/refresh')) {
          refreshCalls++;
          return _FakeResponse(
            200,
            _tokenJson(access: 'new_access', refresh: 'r2'),
          );
        }
        return _FakeResponse(404, {'message': 'not found'});
      });

    final mainDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _FakeAdapter((options) async {
      if (options.uri.path.endsWith('/protected')) {
        final auth = options.headers['Authorization'] as String?;
        if (auth == 'Bearer new_access') {
          return _FakeResponse(200, {'ok': true});
        }
        return _FakeResponse(401, {'message': 'Unauthorized'});
      }
      return _FakeResponse(404, {'message': 'not found'});
    });

    mainDio.interceptors.addAll([
      AuthRequestInterceptor(tokens),
      AuthRefreshInterceptor(
        tokenManager: tokens,
        refreshDio: refreshDio,
        mainDio: mainDio,
      ),
    ]);

    final res = await mainDio.get<Map<String, dynamic>>('/protected');
    expect(res.statusCode, 200);
    expect(res.data, {'ok': true});
    expect(refreshCalls, 1);
    expect(tokens.accessToken, 'new_access');
    expect(await tokens.refreshToken, 'r2');
  });

  test('concurrent 401s only refresh once (singleflight)', () async {
    final store = _FakeRefreshTokenStore('r1');
    final tokens = AuthTokenManager(store);
    await tokens.setTokens(accessToken: 'old_access', refreshToken: 'r1');

    var refreshCalls = 0;
    final refreshCompleter = Completer<void>();

    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _FakeAdapter((options) async {
        if (options.uri.path.endsWith('/auth/refresh')) {
          refreshCalls++;
          await refreshCompleter.future;
          return _FakeResponse(
            200,
            _tokenJson(access: 'new_access', refresh: 'r2'),
          );
        }
        return _FakeResponse(404, {'message': 'not found'});
      });

    final mainDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _FakeAdapter((options) async {
      if (options.uri.path.endsWith('/protected')) {
        final auth = options.headers['Authorization'] as String?;
        if (auth == 'Bearer new_access') {
          return _FakeResponse(200, {'ok': true});
        }
        return _FakeResponse(401, {'message': 'Unauthorized'});
      }
      return _FakeResponse(404, {'message': 'not found'});
    });

    mainDio.interceptors.addAll([
      AuthRequestInterceptor(tokens),
      AuthRefreshInterceptor(
        tokenManager: tokens,
        refreshDio: refreshDio,
        mainDio: mainDio,
      ),
    ]);

    final f1 = mainDio.get<Map<String, dynamic>>('/protected');
    final f2 = mainDio.get<Map<String, dynamic>>('/protected');

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(refreshCalls, 1);
    refreshCompleter.complete();

    final results = await Future.wait([f1, f2]);
    expect(results[0].statusCode, 200);
    expect(results[1].statusCode, 200);
    expect(refreshCalls, 1);
  });

  test('refresh failure clears tokens and does not loop', () async {
    final store = _FakeRefreshTokenStore('r1');
    final tokens = AuthTokenManager(store);
    await tokens.setTokens(accessToken: 'old_access', refreshToken: 'r1');

    var refreshCalls = 0;
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _FakeAdapter((options) async {
        if (options.uri.path.endsWith('/auth/refresh')) {
          refreshCalls++;
          return _FakeResponse(401, {'message': 'Unauthorized'});
        }
        return _FakeResponse(404, {'message': 'not found'});
      });

    final mainDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _FakeAdapter((options) async {
      if (options.uri.path.endsWith('/protected')) {
        return _FakeResponse(401, {'message': 'Unauthorized'});
      }
      return _FakeResponse(404, {'message': 'not found'});
    });

    mainDio.interceptors.addAll([
      AuthRequestInterceptor(tokens),
      AuthRefreshInterceptor(
        tokenManager: tokens,
        refreshDio: refreshDio,
        mainDio: mainDio,
      ),
    ]);

    await expectLater(
      () => mainDio.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 1);
    expect(tokens.accessToken, isNull);
    expect(await tokens.refreshToken, isNull);
  });
}
