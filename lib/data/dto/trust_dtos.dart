import 'package:ciel_mobile/domain/entities/trust_score.dart';

class TrustScoreDto {
  TrustScoreDto({
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

  factory TrustScoreDto.fromJson(Map<String, dynamic> json) {
    return TrustScoreDto(
      userId: json['user_id'] as String,
      trustLevel: (json['trust_level'] as num).toInt(),
      trustLevelName: json['trust_level_name'] as String,
      trustPoints: (json['trust_points'] as num).toInt(),
      accountAgeDays: (json['account_age_days'] as num).toInt(),
      postsCount: (json['posts_count'] as num).toInt(),
      followersCount: (json['followers_count'] as num).toInt(),
      strikes: (json['strikes'] as num).toInt(),
      isBanned: json['is_banned'] as bool,
    );
  }

  TrustScore toDomain() {
    return TrustScore(
      userId: userId,
      trustLevel: trustLevel,
      trustLevelName: trustLevelName,
      trustPoints: trustPoints,
      accountAgeDays: accountAgeDays,
      postsCount: postsCount,
      followersCount: followersCount,
      strikes: strikes,
      isBanned: isBanned,
    );
  }

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

class RateLimitQuotasDto {
  RateLimitQuotasDto({
    required this.posts,
    required this.follows,
    required this.likes,
    required this.comments,
    required this.mediaRead,
    required this.mediaUpload,
  });

  factory RateLimitQuotasDto.fromJson(Map<String, dynamic> json) {
    return RateLimitQuotasDto(
      posts: (json['posts'] as num).toInt(),
      follows: (json['follows'] as num).toInt(),
      likes: (json['likes'] as num).toInt(),
      comments: (json['comments'] as num).toInt(),
      mediaRead: (json['media_read'] as num).toInt(),
      mediaUpload: (json['media_upload'] as num).toInt(),
    );
  }

  RateLimitQuotas toDomain() {
    return RateLimitQuotas(
      posts: posts,
      follows: follows,
      likes: likes,
      comments: comments,
      mediaRead: mediaRead,
      mediaUpload: mediaUpload,
    );
  }

  final int posts;
  final int follows;
  final int likes;
  final int comments;
  final int mediaRead;
  final int mediaUpload;
}

class RateLimitsDto {
  RateLimitsDto({
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

  factory RateLimitsDto.fromJson(Map<String, dynamic> json) {
    return RateLimitsDto(
      trustLevel: json['trust_level'] as String,
      postsPerHour: (json['posts_per_hour'] as num).toInt(),
      postsPerDay: (json['posts_per_day'] as num).toInt(),
      followsPerHour: (json['follows_per_hour'] as num).toInt(),
      followsPerDay: (json['follows_per_day'] as num).toInt(),
      likesPerHour: (json['likes_per_hour'] as num).toInt(),
      commentsPerHour: (json['comments_per_hour'] as num).toInt(),
      mediaReadPerHour: (json['media_read_per_hour'] as num).toInt(),
      mediaUploadPerHour: (json['media_upload_per_hour'] as num).toInt(),
      remaining: RateLimitQuotasDto.fromJson(
        json['remaining'] as Map<String, dynamic>,
      ),
    );
  }

  RateLimits toDomain() {
    return RateLimits(
      trustLevel: trustLevel,
      postsPerHour: postsPerHour,
      postsPerDay: postsPerDay,
      followsPerHour: followsPerHour,
      followsPerDay: followsPerDay,
      likesPerHour: likesPerHour,
      commentsPerHour: commentsPerHour,
      mediaReadPerHour: mediaReadPerHour,
      mediaUploadPerHour: mediaUploadPerHour,
      remaining: remaining.toDomain(),
    );
  }

  final String trustLevel;
  final int postsPerHour;
  final int postsPerDay;
  final int followsPerHour;
  final int followsPerDay;
  final int likesPerHour;
  final int commentsPerHour;
  final int mediaReadPerHour;
  final int mediaUploadPerHour;
  final RateLimitQuotasDto remaining;
}
