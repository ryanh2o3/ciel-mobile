import 'package:meta/meta.dart';

/// Domain entity — mirrors Swift `User`.
@immutable
class User {
  const User({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.createdAt,
    this.email,
    this.bio,
    this.avatarUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  final String id;
  final String handle;
  final String? email;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  @override
  bool operator ==(Object other) {
    return other is User &&
        other.id == id &&
        other.handle == handle &&
        other.email == email &&
        other.displayName == displayName &&
        other.bio == bio &&
        other.avatarUrl == avatarUrl &&
        other.createdAt == createdAt &&
        other.followersCount == followersCount &&
        other.followingCount == followingCount &&
        other.postsCount == postsCount;
  }

  @override
  int get hashCode => Object.hash(
        id,
        handle,
        email,
        displayName,
        bio,
        avatarUrl,
        createdAt,
        followersCount,
        followingCount,
        postsCount,
      );
}
