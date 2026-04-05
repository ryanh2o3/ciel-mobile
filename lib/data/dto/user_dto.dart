import 'package:ciel_mobile/domain/entities/user.dart';

/// API user payload — snake_case JSON from Ciel backend.
class UserDto {
  UserDto({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.createdAt,
    this.email,
    this.bio,
    this.avatarUrl,
    this.followersCount,
    this.followingCount,
    this.postsCount,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      handle: json['handle'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      followersCount: (json['followers_count'] as num?)?.toInt(),
      followingCount: (json['following_count'] as num?)?.toInt(),
      postsCount: (json['posts_count'] as num?)?.toInt(),
    );
  }

  final String id;
  final String handle;
  final String? email;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdAt;
  final int? followersCount;
  final int? followingCount;
  final int? postsCount;

  User toDomain() {
    return User(
      id: id,
      handle: handle,
      email: email,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      followersCount: followersCount ?? 0,
      followingCount: followingCount ?? 0,
      postsCount: postsCount ?? 0,
    );
  }
}
