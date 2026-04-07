import 'package:ciel_mobile/core/errors/app_failure.dart';
import 'package:ciel_mobile/domain/entities/post_with_media.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:flutter/foundation.dart';

@immutable
class FeedState {
  const FeedState({
    required this.posts,
    required this.storyGroups,
    required this.myStoryGroup,
    required this.loading,
    required this.loadingMore,
    this.error,
    this.nextCursor,
  });

  const FeedState.initial()
    : posts = const [],
      storyGroups = const [],
      myStoryGroup = null,
      loading = false,
      loadingMore = false,
      error = null,
      nextCursor = null;

  final List<PostWithMedia> posts;
  final List<UserStoryGroup> storyGroups;
  final UserStoryGroup? myStoryGroup;
  final bool loading;
  final bool loadingMore;
  final AppFailure? error;
  final String? nextCursor;

  FeedState copyWith({
    List<PostWithMedia>? posts,
    List<UserStoryGroup>? storyGroups,
    UserStoryGroup? myStoryGroup,
    bool clearMyStoryGroup = false,
    bool? loading,
    bool? loadingMore,
    AppFailure? error,
    bool clearError = false,
    String? nextCursor,
    bool clearNextCursor = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      storyGroups: storyGroups ?? this.storyGroups,
      myStoryGroup: clearMyStoryGroup
          ? null
          : (myStoryGroup ?? this.myStoryGroup),
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    );
  }
}
