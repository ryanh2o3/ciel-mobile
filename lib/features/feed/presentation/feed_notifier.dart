import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/app/providers/shared_preferences_provider.dart';
import 'package:ciel_mobile/core/errors/app_failure_mapper.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _seenStoryIdsKey = 'seen_story_ids';
const _maxSeenStoryIds = 500;

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() => const FeedState.initial();

  FeedUseCase get _feed => ref.read(feedUseCaseProvider);
  StoryUseCase get _stories => ref.read(storyUseCaseProvider);
  MediaUseCase get _media => ref.read(mediaUseCaseProvider);

  final Map<String, Media> _mediaCache = <String, Media>{};
  final Map<String, Future<Media>> _mediaInFlight = <String, Future<Media>>{};

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
        error: mapToFailure(e),
      );
    }
  }

  Future<void> _loadStories(User? currentUser) async {
    try {
      final seen = await _readSeenIdsSet();
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
        } on Object catch (e) {
          _debugLog('load my stories failed', e);
        }
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
    } on Object catch (e) {
      _debugLog('load stories failed', e);
    }
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
      final newPosts = page.items
          .where((p) => !existingIds.contains(p.id))
          .toList();
      final withMedia = await _loadMediaForPosts(newPosts);
      state = state.copyWith(
        posts: [...state.posts, ...withMedia],
        nextCursor: page.nextCursor,
        loadingMore: false,
      );
    } on Object catch (e) {
      state = state.copyWith(
        loadingMore: false,
        error: mapToFailure(e),
      );
    }
  }

  Future<void> markStorySeen(String storyId) async {
    final list = await _readSeenIdsList();
    if (!list.contains(storyId)) {
      list.add(storyId);
    }
    final trimmed = list.length <= _maxSeenStoryIds
        ? list
        : list.sublist(list.length - _maxSeenStoryIds);
    await _writeSeenIdsList(trimmed);
    try {
      await ref.read(storyUseCaseProvider).markSeen(storyId);
    } on Object catch (e) {
      _debugLog('mark story seen failed', e);
    }
    final user = ref.read(authNotifierProvider).user;
    await _loadStories(user);
  }

  Future<List<String>> _readSeenIdsList() async {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getStringList(_seenStoryIdsKey) ?? const <String>[];
  }

  Future<void> _writeSeenIdsList(List<String> ids) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_seenStoryIdsKey, ids);
  }

  Future<Set<String>> _readSeenIdsSet() async {
    final list = await _readSeenIdsList();
    return list.toSet();
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
    final futures = posts.map((post) async {
      final mediaFutures = post.mediaIds.map(_getMediaBestEffort).toList();
      final mediaItems = (await Future.wait(mediaFutures))
          .whereType<Media>()
          .toList(growable: false);
      return PostWithMedia(post: post, mediaItems: mediaItems);
    }).toList();
    return Future.wait(futures);
  }

  Future<Media?> _getMediaBestEffort(String id) async {
    final cached = _mediaCache[id];
    if (cached != null) return cached;

    final inFlight = _mediaInFlight[id];
    Future<Media> future;
    if (inFlight == null) {
      future = _media.fetchMedia(id);
      _mediaInFlight[id] = future;
    } else {
      future = inFlight;
    }

    try {
      final media = await future;
      _mediaCache[id] = media;
      return media;
    } on Object catch (e) {
      _debugLog('fetch media failed: $id', e);
      return null;
    } finally {
      unawaited(_mediaInFlight.remove(id) ?? Future<void>.value());
    }
  }

  void _debugLog(String message, Object error) {
    assert(() {
      debugPrint('[FeedNotifier] $message: $error');
      return true;
    }(), 'FeedNotifier debug log');
  }

  void removePost(String postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.post.id != postId).toList(),
    );
  }
}

final feedNotifierProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);
