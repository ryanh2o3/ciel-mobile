import 'package:meta/meta.dart';

@immutable
class TrustScore {
  const TrustScore({
    required this.userId,
    required this.trustLevel,
    required this.trustLevelName,
    required this.trustPoints,
    required this.accountAgeDays,
    required this.postsCount,
    required this.followersCount,
    required this.strikes,
    required this.isBanned,
  });

  final String userId;
  final int trustLevel;
  final String trustLevelName;
  final int trustPoints;
  final int accountAgeDays;
  final int postsCount;
  final int followersCount;
  final int strikes;
  final bool isBanned;
}

@immutable
class RateLimitQuotas {
  const RateLimitQuotas({
    required this.posts,
    required this.follows,
    required this.likes,
    required this.comments,
    required this.mediaRead,
    required this.mediaUpload,
  });

  final int posts;
  final int follows;
  final int likes;
  final int comments;
  final int mediaRead;
  final int mediaUpload;
}

@immutable
class RateLimits {
  const RateLimits({
    required this.trustLevel,
    required this.postsPerHour,
    required this.postsPerDay,
    required this.followsPerHour,
    required this.followsPerDay,
    required this.likesPerHour,
    required this.commentsPerHour,
    required this.mediaReadPerHour,
    required this.mediaUploadPerHour,
    required this.remaining,
  });

  final String trustLevel;
  final int postsPerHour;
  final int postsPerDay;
  final int followsPerHour;
  final int followsPerDay;
  final int likesPerHour;
  final int commentsPerHour;
  final int mediaReadPerHour;
  final int mediaUploadPerHour;
  final RateLimitQuotas remaining;
}
