import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:meta/meta.dart';

enum StoryVisibility {
  public,
  friendsOnly,
  closeFriendsOnly,
}

@immutable
class Story {
  const Story({
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

  final String id;
  final String userId;
  final String? userHandle;
  final String? userDisplayName;
  final String? userAvatarUrl;
  final String mediaId;
  final Media? media;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final StoryVisibility visibility;
  final int viewCount;
  final int reactionCount;
}

@immutable
class StoryReaction {
  const StoryReaction({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
    this.userHandle,
  });

  final String id;
  final String storyId;
  final String userId;
  final String? userHandle;
  final String emoji;
  final DateTime createdAt;
}

@immutable
class StoryView {
  const StoryView({
    required this.viewerId,
    required this.viewedAt,
    this.viewerHandle,
    this.viewerDisplayName,
    this.viewerAvatarUrl,
  });

  final String viewerId;
  final String? viewerHandle;
  final String? viewerDisplayName;
  final String? viewerAvatarUrl;
  final DateTime viewedAt;
}

@immutable
class UserStoryGroup {
  const UserStoryGroup({
    required this.userId,
    required this.stories,
    required this.hasUnseenStories,
    this.userHandle,
    this.userDisplayName,
    this.userAvatarUrl,
  });

  final String userId;
  final String? userHandle;
  final String? userDisplayName;
  final String? userAvatarUrl;
  final List<Story> stories;
  final bool hasUnseenStories;

  DateTime get latestStoryDate {
    if (stories.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return stories
        .map((s) => s.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }
}
