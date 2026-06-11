import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/domain/repositories/moderation_repository.dart';
import 'package:dio/dio.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  ModerationRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<void> flagUser({required String userId, String? reason}) async {
    try {
      await _dio.post<void>(
        '/moderation/users/$userId/flag',
        data: <String, dynamic>{
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
