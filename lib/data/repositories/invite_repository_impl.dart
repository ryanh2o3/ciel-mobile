import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/data/dto/invite_dtos.dart';
import 'package:ciel_mobile/data/dto/request_bodies.dart';
import 'package:ciel_mobile/domain/entities/invite.dart';
import 'package:ciel_mobile/domain/repositories/invite_repository.dart';
import 'package:dio/dio.dart';

class InviteRepositoryImpl implements InviteRepository {
  InviteRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<InviteCode> createInvite({required int daysValid}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/invites',
        data: createInviteRequestJson(daysValid: daysValid),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return InviteCodeDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to create invite', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<InviteCode>> getInvites() async {
    try {
      final res = await _dio.get<List<dynamic>>('/invites');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return data
            .map((e) => InviteCodeDto.fromJson(e as Map<String, dynamic>).toDomain())
            .toList();
      }
      throw AppException('Failed to load invites', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<InviteStats> getInviteStats() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/invites/stats');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return InviteStatsDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to load invite stats', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> revokeInvite(String code) async {
    try {
      await _dio.post<void>('/invites/$code/revoke');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<bool> validateInviteCode(String code) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/invites/validate/$code');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return InviteValidationResponseDto.fromJson(data).isValid;
      }
      throw AppException('Validation failed', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
