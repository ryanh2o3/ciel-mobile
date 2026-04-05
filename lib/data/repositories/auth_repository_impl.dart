import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/data/auth/auth_token_manager.dart';
import 'package:ciel_mobile/data/dto/auth_dtos.dart';
import 'package:ciel_mobile/data/dto/request_bodies.dart';
import 'package:ciel_mobile/data/dto/user_dto.dart';
import 'package:ciel_mobile/domain/entities/signup_request.dart';
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
  Future<User> signup(SignupRequest request) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/users',
        data: signupRequestJson(
          handle: request.handle,
          email: request.email,
          displayName: request.displayName,
          password: request.password,
          inviteCode: request.inviteCode,
          bio: request.bio,
          avatarKey: request.avatarKey,
        ),
        options: Options(extra: {'skipAuthHeader': true}),
      );
      final data = res.data;
      if ((res.statusCode == 200 || res.statusCode == 201) && data != null) {
        return UserDto.fromJson(data).toDomain();
      }
      throw AppException('Signup failed', cause: res.statusMessage);
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
    if (e.response?.statusCode == 401) {
      return AppException('Invalid email or password', cause: e);
    }
    return mapDioException(e);
  }
}
