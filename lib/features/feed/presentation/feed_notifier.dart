import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/app/providers/shared_preferences_provider.dart';
import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/domain/entities/post_with_media.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/usecases/feed_use_case.dart';
import 'package:ciel_mobile/domain/usecases/media_use_case.dart';
import 'package:ciel_mobile/domain/usecases/story_use_case.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _seenStoryIdsKey = 'seen_story_ids';

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() => FeedState.initial();

  FeedUseCase get _feed => ref.read(feedUseCaseProvider);
  StoryUseCase get _stories => ref.read(storyUseCaseProvider);
  MediaUseCase get _media => ref.read(mediaUseCaseProvider);

  Future<void> loadInitialIfNeeded(User? currentUser) async {
    if (state.loading || state.posts.isNotEmpty) {
      return;
    }
    await refresh(currentUser);
  }

  Future<void> refresh(User? currentUser) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _feed.fetchFeed(limit: 30);
      final posts = page.items;
      final withMedia = await _loadMediaForPosts(posts);
      state = state.copyWith(
        posts: withMedia,
        nextCursor: page.nextCursor,
        loading: false,
      );
      unawaited(_loadStories(currentUser));
    } on Object catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _loadStories(User? currentUser) async {
    try {
      final seen = await _readSeenIds();
      final feedPage = await _stories.fetchStoriesFeed(limit: 50);
      var groups = _stories.groupStoriesByUser(feedPage.items);
      groups = _applySeen(groups, seen);

      UserStoryGroup? myGroup;
      if (currentUser != null) {
        try {
          final mine = await _stories.fetchUserStories(
            userId: currentUser.id,
            limit: 50,
          );
          if (mine.items.isNotEmpty) {
            final sorted = List<Story>.from(mine.items)
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            myGroup = UserStoryGroup(
              userId: currentUser.id,
              userHandle: currentUser.handle,
              userDisplayName: currentUser.displayName,
              userAvatarUrl: currentUser.avatarUrl,
              stories: sorted,
              hasUnseenStories: sorted.any((s) => !seen.contains(s.id)),
            );
          }
        } on Object catch (_) {}
      }

      var resolvedMy = myGroup;
      if (resolvedMy == null && currentUser != null) {
        for (final g in groups) {
          if (g.userId == currentUser.id) {
            resolvedMy = g;
            break;
          }
        }
      }

      final others = currentUser == null
          ? groups
          : groups.where((g) => g.userId != currentUser.id).toList();

      state = state.copyWith(
        storyGroups: others,
        myStoryGroup: resolvedMy,
      );
    } on Object catch (_) {}
  }

  Future<void> loadMoreIfNeeded(PostWithMedia item) async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loading || state.loadingMore) {
      return;
    }
    if (state.posts.isEmpty || item.id != state.posts.last.id) {
      return;
    }
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _feed.fetchFeed(limit: 30, cursor: cursor);
      final existingIds = state.posts.map((p) => p.post.id).toSet();
      final newPosts =
          page.items.where((p) => !existingIds.contains(p.id)).toList();
      final withMedia = await _loadMediaForPosts(newPosts);
      state = state.copyWith(
        posts: [...state.posts, ...withMedia],
        nextCursor: page.nextCursor,
        loadingMore: false,
      );
    } on Object catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> markStorySeen(String storyId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final seen = await _readSeenIds();
    seen.add(storyId);
    await prefs.setStringList(_seenStoryIdsKey, seen.toList());
    try {
      await ref.read(storyUseCaseProvider).markSeen(storyId);
    } on Object catch (_) {}
    final user = ref.read(authNotifierProvider).user;
    await _loadStories(user);
  }

  Future<Set<String>> _readSeenIds() async {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getStringList(_seenStoryIdsKey)?.toSet() ?? {};
  }

  List<UserStoryGroup> _applySeen(
    List<UserStoryGroup> groups,
    Set<String> seen,
  ) {
    return groups
        .map(
          (g) => UserStoryGroup(
            userId: g.userId,
            userHandle: g.userHandle,
            userDisplayName: g.userDisplayName,
            userAvatarUrl: g.userAvatarUrl,
            stories: g.stories,
            hasUnseenStories: g.stories.any((s) => !seen.contains(s.id)),
          ),
        )
        .toList();
  }

  Future<List<PostWithMedia>> _loadMediaForPosts(List<Post> posts) async {
    final out = <PostWithMedia>[];
    for (final post in posts) {
      final mediaItems = <Media>[];
      for (final id in post.mediaIds) {
        try {
          final m = await _media.fetchMedia(id);
          mediaItems.add(m);
        } on Object catch (_) {}
      }
      out.add(PostWithMedia(post: post, mediaItems: mediaItems));
    }
    return out;
  }

  void removePost(String postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.post.id != postId).toList(),
    );
  }
}

final feedNotifierProvider =
    NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);
