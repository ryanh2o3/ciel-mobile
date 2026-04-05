import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/auth/auth_token_manager.dart';
import 'package:ciel_mobile/data/dto/auth_dtos.dart';
import 'package:ciel_mobile/data/dto/user_dto.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required Dio dio,
    required AuthTokenManager tokens,
  })  : _dio = dio,
        _tokens = tokens;

  final Dio _dio;
  final AuthTokenManager _tokens;

  @override
  Future<void> clearLocalSession() => _tokens.clear();

  @override
  Future<User> fetchMe() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return UserDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to load profile', cause: res.statusMessage);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: loginRequestJson(email: email, password: password),
        options: Options(extra: {'skipAuthHeader': true}),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final tokens = AuthTokensDto.fromJson(data);
        await _tokens.setTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        return fetchMe();
      }
      throw AppException('Login failed', cause: res.statusMessage);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  @override
  Future<void> logout() async {
    final refresh = await _tokens.refreshToken;
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _dio.post<void>(
          '/auth/revoke',
          data: revokeRequestJson(refreshToken: refresh),
        );
      }
    } on DioException {
      // Best-effort revoke; always clear local session.
    } finally {
      await _tokens.clear();
    }
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    var message = 'Request failed';
    if (body is Map && body['message'] is String) {
      message = body['message'] as String;
    } else if (status == 401) {
      message = 'Invalid email or password';
    } else if (status != null) {
      message = 'Error $status';
    } else if (e.message != null) {
      message = e.message!;
    }
    return AppException(message, cause: e);
  }
}
