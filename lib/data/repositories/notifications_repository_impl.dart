import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/data/dto/models_dtos.dart';
import 'package:ciel_mobile/data/dto/paginated_dtos.dart';
import 'package:ciel_mobile/domain/entities/app_notification.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/notifications_repository.dart';
import 'package:dio/dio.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginatedResult<AppNotification>> fetchNotifications({
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {
          'limit': limit,
          'cursor': ?cursor,
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, NotificationDto.fromJson);
        return PaginatedResult<AppNotification>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException(
        'Failed to load notifications',
        cause: res.statusMessage,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _dio.post<void>('/notifications/$id/read');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
