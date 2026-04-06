import 'package:ciel_mobile/data/api/json_parse.dart';
import 'package:ciel_mobile/data/dto/models_dtos.dart';
import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/domain/entities/story.dart';

StoryVisibility _storyVisibility(String raw) {
  switch (raw) {
    case 'friends_only':
    case 'FriendsOnly':
      return StoryVisibility.friendsOnly;
    case 'close_friends_only':
    case 'CloseFriendsOnly':
      return StoryVisibility.closeFriendsOnly;
    case 'public':
    case 'Public':
    default:
      return StoryVisibility.public;
  }
}

class StoryDto {
  StoryDto({
    required this.id,
    required this.userId,
    required this.mediaId,
    required this.createdAt,
    required this.expiresAt,
    required this.visibility,
    required this.viewCount,
    required this.reactionCount,
    this.userHandle,
    this.userDisplayName,
    this.userAvatarUrl,
    this.caption,
    this.media,
  });

  factory StoryDto.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['media'];
    return StoryDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userHandle: json['user_handle'] as String?,
      userDisplayName: json['user_display_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
      mediaId: json['media_id'] as String,
      caption: json['caption'] as String?,
      createdAt: parseApiDateTime(json['created_at'] as String),
      expiresAt: parseApiDateTime(json['expires_at'] as String),
      visibility: json['visibility'] as String? ?? 'Public',
      viewCount: (json['view_count'] as num).toInt(),
      reactionCount: (json['reaction_count'] as num).toInt(),
      media: mediaJson is Map<String, dynamic>
          ? MediaDto.fromJson(mediaJson).toDomain()
          : null,
    );
  }

  Story toDomain() {
    return Story(
      id: id,
      userId: userId,
      userHandle: userHandle,
      userDisplayName: userDisplayName,
      userAvatarUrl: userAvatarUrl,
      mediaId: mediaId,
      media: media,
      caption: caption,
      createdAt: createdAt,
      expiresAt: expiresAt,
      visibility: _storyVisibility(visibility),
      viewCount: viewCount,
      reactionCount: reactionCount,
    );
  }

  final String id;
  final String userId;
  final String? userHandle;
  final String? userDisplayName;
  final String? userAvatarUrl;
  final String mediaId;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String visibility;
  final int viewCount;
  final int reactionCount;
  final Media? media;
}

class StoryReactionDto {
  StoryReactionDto({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
    this.userHandle,
  });

  factory StoryReactionDto.fromJson(Map<String, dynamic> json) {
    return StoryReactionDto(
      id: json['id'] as String,
      storyId: json['story_id'] as String,
      userId: json['user_id'] as String,
      userHandle: json['user_handle'] as String?,
      emoji: json['emoji'] as String,
      createdAt: parseApiDateTime(json['created_at'] as String),
    );
  }

  StoryReaction toDomain() {
    return StoryReaction(
      id: id,
      storyId: storyId,
      userId: userId,
      userHandle: userHandle,
      emoji: emoji,
      createdAt: createdAt,
    );
  }

  final String id;
  final String storyId;
  final String userId;
  final String? userHandle;
  final String emoji;
  final DateTime createdAt;
}

class StoryViewDto {
  StoryViewDto({
    required this.viewerId,
    required this.viewedAt,
    this.viewerHandle,
    this.viewerDisplayName,
    this.viewerAvatarUrl,
  });

  factory StoryViewDto.fromJson(Map<String, dynamic> json) {
    return StoryViewDto(
      viewerId: json['viewer_id'] as String,
      viewerHandle: json['viewer_handle'] as String?,
      viewerDisplayName: json['viewer_display_name'] as String?,
      viewerAvatarUrl: json['viewer_avatar_url'] as String?,
      viewedAt: parseApiDateTime(json['viewed_at'] as String),
    );
  }

  StoryView toDomain() {
    return StoryView(
      viewerId: viewerId,
      viewerHandle: viewerHandle,
      viewerDisplayName: viewerDisplayName,
      viewerAvatarUrl: viewerAvatarUrl,
      viewedAt: viewedAt,
    );
  }

  final String viewerId;
  final String? viewerHandle;
  final String? viewerDisplayName;
  final String? viewerAvatarUrl;
  final DateTime viewedAt;
}
