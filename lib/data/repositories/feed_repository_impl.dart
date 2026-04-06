import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/data/dto/models_dtos.dart';
import 'package:ciel_mobile/data/dto/paginated_dtos.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/feed_repository.dart';
import 'package:dio/dio.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginatedResult<Post>> fetchFeed({
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/feed',
        queryParameters: {
          'limit': limit,
          'cursor': ?cursor,
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, PostDto.fromJson);
        return PaginatedResult<Post>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException('Failed to load feed', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> refreshFeedCache() async {
    try {
      await _dio.post<void>('/feed/refresh');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
