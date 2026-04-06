import 'package:ciel_mobile/data/api/json_parse.dart';
import 'package:ciel_mobile/data/dto/user_dto.dart';
import 'package:ciel_mobile/domain/entities/app_notification.dart';
import 'package:ciel_mobile/domain/entities/comment.dart';
import 'package:ciel_mobile/domain/entities/followed_user.dart';
import 'package:ciel_mobile/domain/entities/like.dart';
import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/relationship.dart';

PostVisibility _postVisibility(String raw) {
  switch (raw) {
    case 'followers_only':
    case 'FollowersOnly':
      return PostVisibility.followersOnly;
    case 'public':
    case 'Public':
    default:
      return PostVisibility.public;
  }
}

class PostDto {
  PostDto({
    required this.id,
    required this.ownerId,
    required this.mediaIds,
    required this.visibility,
    required this.createdAt,
    this.ownerHandle,
    this.ownerDisplayName,
    this.ownerAvatarUrl,
    this.caption,
    this.primaryMedia,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) {
    final primaryMediaJson = json['primary_media'];
    return PostDto(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      ownerHandle: json['owner_handle'] as String?,
      ownerDisplayName: json['owner_display_name'] as String?,
      ownerAvatarUrl: json['owner_avatar_url'] as String?,
      mediaIds: (json['media_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      caption: json['caption'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      createdAt: parseApiDateTime(json['created_at'] as String),
      primaryMedia: primaryMediaJson is Map<String, dynamic>
          ? MediaDto.fromJson(primaryMediaJson).toDomain()
          : null,
    );
  }

  final String id;
  final String ownerId;
  final String? ownerHandle;
  final String? ownerDisplayName;
  final String? ownerAvatarUrl;
  final List<String> mediaIds;
  final String? caption;
  final String visibility;
  final DateTime createdAt;
  final Media? primaryMedia;

  Post toDomain() {
    return Post(
      id: id,
      ownerId: ownerId,
      ownerHandle: ownerHandle,
      ownerDisplayName: ownerDisplayName,
      ownerAvatarUrl: ownerAvatarUrl,
      mediaIds: mediaIds,
      caption: caption,
      visibility: _postVisibility(visibility),
      createdAt: createdAt,
      primaryMedia: primaryMedia,
    );
  }
}

class MediaDto {
  MediaDto({
    required this.id,
    required this.ownerId,
    required this.originalKey,
    required this.thumbKey,
    required this.mediumKey,
    required this.width,
    required this.height,
    required this.bytes,
    required this.createdAt,
    this.thumbUrl,
    this.mediumUrl,
    this.originalUrl,
  });

  factory MediaDto.fromJson(Map<String, dynamic> json) {
    return MediaDto(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      originalKey: json['original_key'] as String,
      thumbKey: json['thumb_key'] as String,
      mediumKey: json['medium_key'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      bytes: (json['bytes'] as num).toInt(),
      createdAt: parseApiDateTime(json['created_at'] as String),
      thumbUrl: json['thumb_url'] as String?,
      mediumUrl: json['medium_url'] as String?,
      originalUrl: json['original_url'] as String?,
    );
  }

  final String id;
  final String ownerId;
  final String originalKey;
  final String thumbKey;
  final String mediumKey;
  final int width;
  final int height;
  final int bytes;
  final DateTime createdAt;
  final String? thumbUrl;
  final String? mediumUrl;
  final String? originalUrl;

  Media toDomain() {
    return Media(
      id: id,
      ownerId: ownerId,
      originalKey: originalKey,
      thumbKey: thumbKey,
      mediumKey: mediumKey,
      width: width,
      height: height,
      bytes: bytes,
      createdAt: createdAt,
      thumbUrl: thumbUrl,
      mediumUrl: mediumUrl,
      originalUrl: originalUrl,
    );
  }
}

class LikeDto {
  LikeDto({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });

  factory LikeDto.fromJson(Map<String, dynamic> json) {
    return LikeDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      postId: json['post_id'] as String,
      createdAt: parseApiDateTime(json['created_at'] as String),
    );
  }

  Like toDomain() {
    return Like(
      id: id,
      userId: userId,
      postId: postId,
      createdAt: createdAt,
    );
  }

  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;
}

class CommentDto {
  CommentDto({
    required this.id,
    required this.userId,
    required this.postId,
    required this.body,
    required this.createdAt,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    return CommentDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      postId: json['post_id'] as String,
      body: json['body'] as String,
      createdAt: parseApiDateTime(json['created_at'] as String),
    );
  }

  Comment toDomain() {
    return Comment(
      id: id,
      userId: userId,
      postId: postId,
      body: body,
      createdAt: createdAt,
    );
  }

  final String id;
  final String userId;
  final String postId;
  final String body;
  final DateTime createdAt;
}

Map<String, dynamic> _payloadFromJson(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return Map<String, dynamic>.from(raw);
  }
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }
  return {};
}

class NotificationDto {
  NotificationDto({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.payload,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      notificationType: json['notification_type'] as String,
      payload: _payloadFromJson(json['payload']),
      readAt: json['read_at'] != null
          ? parseApiDateTime(json['read_at'] as String)
          : null,
      createdAt: parseApiDateTime(json['created_at'] as String),
    );
  }

  AppNotification toDomain() {
    return AppNotification(
      id: id,
      userId: userId,
      notificationType: notificationType,
      payload: payload,
      readAt: readAt,
      createdAt: createdAt,
    );
  }

  final String id;
  final String userId;
  final String notificationType;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;
}

class RelationshipDto {
  RelationshipDto({
    required this.isFollowing,
    required this.isFollowedBy,
    required this.isBlocking,
    required this.isBlockedBy,
  });

  factory RelationshipDto.fromJson(Map<String, dynamic> json) {
    return RelationshipDto(
      isFollowing: json['is_following'] as bool,
      isFollowedBy: json['is_followed_by'] as bool,
      isBlocking: json['is_blocking'] as bool,
      isBlockedBy: json['is_blocked_by'] as bool,
    );
  }

  Relationship toDomain() {
    return Relationship(
      isFollowing: isFollowing,
      isFollowedBy: isFollowedBy,
      isBlocking: isBlocking,
      isBlockedBy: isBlockedBy,
    );
  }

  final bool isFollowing;
  final bool isFollowedBy;
  final bool isBlocking;
  final bool isBlockedBy;
}

class FollowedUserDto {
  FollowedUserDto({required this.user, required this.followedAt});

  factory FollowedUserDto.fromJson(Map<String, dynamic> json) {
    return FollowedUserDto(
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      followedAt: parseApiDateTime(json['followed_at'] as String),
    );
  }

  FollowedUser toDomain() {
    return FollowedUser(user: user.toDomain(), followedAt: followedAt);
  }

  final UserDto user;
  final DateTime followedAt;
}
