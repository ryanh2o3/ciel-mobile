import 'package:ciel_mobile/domain/entities/followed_user.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/relationship.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';

abstract class UserRepository {
  Future<User> fetchUser(String id);

  Future<User> updateProfile({
    required String id,
    String? displayName,
    String? bio,
    String? avatarKey,
  });

  Future<PaginatedResult<Post>> fetchUserPosts({
    required String id,
    required int limit,
    String? cursor,
  });

  Future<void> follow(String userId);

  Future<void> unfollow(String userId);

  Future<void> block(String userId);

  Future<void> unblock(String userId);

  Future<PaginatedResult<FollowedUser>> fetchFollowers({
    required String id,
    required int limit,
    String? cursor,
  });

  Future<PaginatedResult<FollowedUser>> fetchFollowing({
    required String id,
    required int limit,
    String? cursor,
  });

  Future<Relationship> fetchRelationship(String id);
}
