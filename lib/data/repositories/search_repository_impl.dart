import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/data/dto/models_dtos.dart';
import 'package:ciel_mobile/data/dto/paginated_dtos.dart';
import 'package:ciel_mobile/data/dto/user_dto.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/search_repository.dart';
import 'package:dio/dio.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginatedResult<User>> searchUsers({
    required String query,
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/search/users',
        queryParameters: {
          'q': query,
          'limit': limit,
          ...?(cursor == null ? null : <String, dynamic>{'cursor': cursor}),
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, UserDto.fromJson);
        return PaginatedResult<User>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException('Search failed', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<Post>> searchPosts({
    required String query,
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/search/posts',
        queryParameters: {
          'q': query,
          'limit': limit,
          ...?(cursor == null ? null : <String, dynamic>{'cursor': cursor}),
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
      throw AppException('Search failed', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
