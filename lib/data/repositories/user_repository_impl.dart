import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/data/dto/models_dtos.dart';
import 'package:ciel_mobile/data/dto/paginated_dtos.dart';
import 'package:ciel_mobile/data/dto/request_bodies.dart';
import 'package:ciel_mobile/data/dto/user_dto.dart';
import 'package:ciel_mobile/domain/entities/followed_user.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/relationship.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/user_repository.dart';
import 'package:dio/dio.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<User> fetchUser(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/$id');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return UserDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to load user', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<User> updateProfile({
    required String id,
    String? displayName,
    String? bio,
    String? avatarKey,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/users/$id',
        data: updateProfileRequestJson(
          displayName: displayName,
          bio: bio,
          avatarKey: avatarKey,
        ),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return UserDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to update profile', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<Post>> fetchUserPosts({
    required String id,
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/users/$id/posts',
        queryParameters: {
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
      throw AppException('Failed to load posts', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> follow(String userId) async {
    try {
      await _dio.post<void>('/users/$userId/follow');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> unfollow(String userId) async {
    try {
      await _dio.post<void>('/users/$userId/unfollow');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> block(String userId) async {
    try {
      await _dio.post<void>('/users/$userId/block');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> unblock(String userId) async {
    try {
      await _dio.post<void>('/users/$userId/unblock');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<FollowedUser>> fetchFollowers({
    required String id,
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/users/$id/followers',
        queryParameters: {
          'limit': limit,
          ...?(cursor == null ? null : <String, dynamic>{'cursor': cursor}),
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, FollowedUserDto.fromJson);
        return PaginatedResult<FollowedUser>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException('Failed to load followers', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<FollowedUser>> fetchFollowing({
    required String id,
    required int limit,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/users/$id/following',
        queryParameters: {
          'limit': limit,
          ...?(cursor == null ? null : <String, dynamic>{'cursor': cursor}),
        },
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final page = paginatedFromJson(data, FollowedUserDto.fromJson);
        return PaginatedResult<FollowedUser>(
          items: page.items.map((dto) => dto.toDomain()).toList(),
          nextCursor: page.nextCursor,
          totalCount: page.totalCount,
        );
      }
      throw AppException('Failed to load following', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Relationship> fetchRelationship(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/users/$id/relationship',
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return RelationshipDto.fromJson(data).toDomain();
      }
      throw AppException(
        'Failed to load relationship',
        cause: res.statusMessage,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
