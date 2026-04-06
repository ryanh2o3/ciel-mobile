import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/data/dto/paginated_dtos.dart';
import 'package:ciel_mobile/data/dto/request_bodies.dart';
import 'package:ciel_mobile/data/dto/story_dtos.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/story_repository.dart';
import 'package:dio/dio.dart';

class StoryRepositoryImpl implements StoryRepository {
  StoryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginatedResult<Story>> fetchStoriesFeed({
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/feed/stories',
        queryParameters: {
          'limit': limit,
          'cursor': ?cursor,
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, StoryDto.fromJson);
        return PaginatedResult<Story>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException('Failed to load stories', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<Story>> fetchUserStories({
    required String userId,
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/users/$userId/stories',
        queryParameters: {
          'limit': limit,
          'cursor': ?cursor,
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, StoryDto.fromJson);
        return PaginatedResult<Story>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException(
        'Failed to load user stories',
        cause: res.statusMessage,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Story> fetchStory(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/stories/$id');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return StoryDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to load story', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Story> createStory({
    required String mediaId,
    required String visibility,
    String? caption,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/stories',
        data: createStoryRequestJson(
          mediaId: mediaId,
          caption: caption,
          visibility: visibility,
        ),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return StoryDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to create story', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> deleteStory(String id) async {
    try {
      await _dio.delete<void>('/stories/$id');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> markSeen(String storyId) async {
    try {
      await _dio.post<void>('/stories/$storyId/seen');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<StoryReaction> addReaction({
    required String storyId,
    required String emoji,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/stories/$storyId/reactions',
        data: addStoryReactionRequestJson(emoji: emoji),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return StoryReactionDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to add reaction', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> removeReaction(String storyId) async {
    try {
      await _dio.delete<void>('/stories/$storyId/reactions');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<StoryView>> fetchViewers({
    required String storyId,
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/stories/$storyId/viewers',
        queryParameters: {
          'limit': limit,
          'cursor': ?cursor,
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, StoryViewDto.fromJson);
        return PaginatedResult<StoryView>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException('Failed to load viewers', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<StoryReaction>> fetchReactions({
    required String storyId,
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/stories/$storyId/reactions',
        queryParameters: {
          'limit': limit,
          'cursor': ?cursor,
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, StoryReactionDto.fromJson);
        return PaginatedResult<StoryReaction>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException('Failed to load reactions', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
