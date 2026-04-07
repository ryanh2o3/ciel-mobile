import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/data/dto/models_dtos.dart';
import 'package:ciel_mobile/data/dto/paginated_dtos.dart';
import 'package:ciel_mobile/data/dto/request_bodies.dart';
import 'package:ciel_mobile/domain/entities/comment.dart';
import 'package:ciel_mobile/domain/entities/like.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/post_repository.dart';
import 'package:dio/dio.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Post> createPost({
    required List<String> mediaIds,
    String? caption,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/posts',
        data: createPostRequestJson(mediaIds: mediaIds, caption: caption),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return PostDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to create post', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Post> fetchPost(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/posts/$id');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return PostDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to load post', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Post> updatePost({required String id, String? caption}) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/posts/$id',
        data: updatePostRequestJson(caption: caption),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return PostDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to update post', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> deletePost(String id) async {
    try {
      await _dio.delete<void>('/posts/$id');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> likePost(String id) async {
    try {
      await _dio.post<void>('/posts/$id/like');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> unlikePost(String id) async {
    try {
      await _dio.delete<void>('/posts/$id/like');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<Like>> fetchLikes({
    required String id,
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/posts/$id/likes',
        queryParameters: {
          'limit': limit,
          ...?(cursor == null ? null : <String, dynamic>{'cursor': cursor}),
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, LikeDto.fromJson);
        return PaginatedResult<Like>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException('Failed to load likes', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Comment> addComment({
    required String postId,
    required String body,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/posts/$postId/comment',
        data: createCommentRequestJson(body: body),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return CommentDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to add comment', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<Comment>> fetchComments({
    required String postId,
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/posts/$postId/comments',
        queryParameters: {
          'limit': limit,
          ...?(cursor == null ? null : <String, dynamic>{'cursor': cursor}),
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, CommentDto.fromJson);
        return PaginatedResult<Comment>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException('Failed to load comments', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      await _dio.delete<void>('/posts/$postId/comments/$commentId');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
