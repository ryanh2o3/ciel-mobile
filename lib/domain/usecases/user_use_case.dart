import 'package:ciel_mobile/domain/entities/followed_user.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/relationship.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/paginated_result.dart';
import 'package:ciel_mobile/domain/repositories/user_repository.dart';

class UserUseCase {
  UserUseCase(this._repository);

  final UserRepository _repository;

  Future<User> fetchUser(String id) => _repository.fetchUser(id);

  Future<User> updateProfile({
    required String id,
    String? displayName,
    String? bio,
    String? avatarKey,
  }) {
    return _repository.updateProfile(
      id: id,
      displayName: displayName,
      bio: bio,
      avatarKey: avatarKey,
    );
  }

  Future<PaginatedResult<Post>> fetchUserPosts({
    required String id,
    required int limit,
    String? cursor,
  }) {
    return _repository.fetchUserPosts(id: id, limit: limit, cursor: cursor);
  }

  Future<void> follow(String userId) => _repository.follow(userId);

  Future<void> unfollow(String userId) => _repository.unfollow(userId);

  Future<void> block(String userId) => _repository.block(userId);

  Future<void> unblock(String userId) => _repository.unblock(userId);

  Future<PaginatedResult<FollowedUser>> fetchFollowers({
    required String id,
    required int limit,
    String? cursor,
  }) {
    return _repository.fetchFollowers(id: id, limit: limit, cursor: cursor);
  }

  Future<PaginatedResult<FollowedUser>> fetchFollowing({
    required String id,
    required int limit,
    String? cursor,
  }) {
    return _repository.fetchFollowing(id: id, limit: limit, cursor: cursor);
  }

  Future<Relationship> fetchRelationship(String id) {
    return _repository.fetchRelationship(id);
  }
}
