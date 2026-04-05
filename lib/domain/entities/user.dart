/// Domain entity — mirrors Swift `User`.
class User {
  const User({
    required this.id,
    required this.handle,
    this.email,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
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
}
