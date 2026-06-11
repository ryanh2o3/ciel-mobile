import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/data/dto/device_dtos.dart';
import 'package:ciel_mobile/data/dto/request_bodies.dart';
import 'package:ciel_mobile/data/dto/trust_dtos.dart';
import 'package:ciel_mobile/domain/entities/device_info.dart';
import 'package:ciel_mobile/domain/entities/trust_score.dart';
import 'package:ciel_mobile/domain/repositories/safety_repository.dart';
import 'package:dio/dio.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  SafetyRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<void> registerDevice({required String fingerprint}) async {
    try {
      await _dio.post<void>(
        '/account/device/register',
        data: deviceRegisterRequestJson(fingerprint: fingerprint),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<DeviceInfo>> getRegisteredDevices() async {
    try {
      final res = await _dio.get<List<dynamic>>('/account/devices');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return data
            .map(
              (e) =>
                  DeviceInfoDto.fromJson(e as Map<String, dynamic>).toDomain(),
            )
            .toList();
      }
      throw AppException('Failed to load devices', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<TrustScore> fetchTrustScore() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/account/trust-score');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return TrustScoreDto.fromJson(data).toDomain();
      }
      throw AppException(
        'Failed to load trust score',
        cause: res.statusMessage,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<RateLimits> fetchRateLimits() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/account/rate-limits');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return RateLimitsDto.fromJson(data).toDomain();
      }
      throw AppException(
        'Failed to load rate limits',
        cause: res.statusMessage,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dio.delete<void>('/account');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
