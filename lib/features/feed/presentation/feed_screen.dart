import 'dart:async';

import 'package:ciel_mobile/app/router/navigation_extras.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_state.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_state.dart';
import 'package:ciel_mobile/features/feed/presentation/widgets/post_card.dart';
import 'package:ciel_mobile/ui/ciel_avatar.dart';
import 'package:ciel_mobile/ui/ciel_empty_state.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scroll = ScrollController();
  ProviderSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _authSub = ref.listenManual<AuthState>(authNotifierProvider, (prev, next) {
      if (prev?.user?.id != next.user?.id) {
        unawaited(ref.read(feedNotifierProvider.notifier).refresh(next.user));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      unawaited(
        ref.read(feedNotifierProvider.notifier).loadInitialIfNeeded(user),
      );
    });
  }

  @override
  void dispose() {
    _authSub?.close();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) {
      return;
    }
    if (_scroll.position.pixels < max - 400) {
      return;
    }
    final state = ref.read(feedNotifierProvider);
    if (state.posts.isEmpty) {
      return;
    }
    unawaited(
      ref
          .read(feedNotifierProvider.notifier)
          .loadMoreIfNeeded(state.posts.last),
    );
  }

  Future<void> _refresh() {
    final user = ref.read(authNotifierProvider).user;
    return ref.read(feedNotifierProvider.notifier).refresh(user);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final feed = ref.watch(feedNotifierProvider);
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final slivers = _feedSlivers(context, auth, feed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ciel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: isIos
          ? CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: _refresh),
                ...slivers,
              ],
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: slivers,
              ),
            ),
    );
  }

  List<Widget> _feedSlivers(
    BuildContext context,
    AuthState auth,
    FeedState feed,
  ) {
    return [
      if (feed.loading && feed.posts.isEmpty)
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        )
      else ...[
        SliverToBoxAdapter(
          child: _StoryStrip(
            myGroup: feed.myStoryGroup,
            groups: feed.storyGroups,
            currentUserAvatarUrl: auth.user?.avatarUrl,
            currentUserLabel: auth.user?.displayName ?? auth.user?.handle,
            onAddStory: () => context.push('/stories/create'),
            onOpenStory: (stories, index) {
              unawaited(
                context.push(
                  '/stories/view',
                  extra: StoryViewerExtra(
                    stories: stories,
                    initialIndex: index,
                  ),
                ),
              );
            },
          ),
        ),
        if (feed.error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(CielSpacing.md),
              child: Column(
                children: [
                  Text(
                    feed.error!.userMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CielSpacing.sm),
                  OutlinedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        if (!feed.loading && feed.posts.isEmpty && feed.error == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: CielEmptyState(
              icon: Icons.photo_outlined,
              title: 'Your feed is empty',
              subtitle: 'Follow people or share a photo to get started.',
              actionLabel: 'Find people',
              onAction: () => context.push('/search'),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = feed.posts[index];
                return PostCard(
                  item: item,
                  onOpen: () => context.push('/post/${item.post.id}'),
                  onOpenProfile: () =>
                      context.push('/profile/${item.post.ownerId}'),
                  onOpenComments: () => context.push('/post/${item.post.id}'),
                );
              },
              childCount: feed.posts.length,
            ),
          ),
        if (feed.loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(CielSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    ];
  }
}

class _StoryStrip extends StatelessWidget {
  const _StoryStrip({
    required this.myGroup,
    required this.groups,
    required this.onAddStory,
    required this.onOpenStory,
    this.currentUserAvatarUrl,
    this.currentUserLabel,
  });

  final UserStoryGroup? myGroup;
  final List<UserStoryGroup> groups;
  final String? currentUserAvatarUrl;
  final String? currentUserLabel;
  final VoidCallback onAddStory;
  final void Function(List<Story> stories, int initialIndex) onOpenStory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: CielSpacing.md - 4,
          vertical: CielSpacing.sm,
        ),
        children: [
          _MyStoryChip(
            myGroup: myGroup,
            avatarUrl: currentUserAvatarUrl ?? myGroup?.userAvatarUrl,
            label: currentUserLabel ?? 'You',
            onAddStory: onAddStory,
            onOpenStory: onOpenStory,
          ),
          ...groups.map(
            (g) => _StoryAvatar(
              label: g.userHandle ?? g.userDisplayName ?? 'User',
              imageUrl: g.userAvatarUrl,
              highlight: g.hasUnseenStories,
              onTap: () => onOpenStory(g.stories, 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyStoryChip extends StatelessWidget {
  const _MyStoryChip({
    required this.myGroup,
    required this.onAddStory,
    required this.onOpenStory,
    this.avatarUrl,
    this.label,
  });

  final UserStoryGroup? myGroup;
  final String? avatarUrl;
  final String? label;
  final VoidCallback onAddStory;
  final void Function(List<Story> stories, int initialIndex) onOpenStory;

  @override
  Widget build(BuildContext context) {
    final group = myGroup;
    final stories = group?.stories ?? const <Story>[];
    final hasStories = stories.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    final ring = !hasStories
        ? CielStoryRingStyle.none
        : (group?.hasUnseenStories ?? false)
            ? CielStoryRingStyle.unseen
            : CielStoryRingStyle.seen;

    var imageUrl = avatarUrl;
    if ((imageUrl == null || imageUrl.isEmpty) && hasStories) {
      final latest = stories.reduce(
        (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
      );
      imageUrl = latest.media?.mediumUrl ?? latest.media?.thumbUrl;
    }

    return Padding(
      padding: const EdgeInsets.only(right: CielSpacing.md - 4),
      child: Column(
        children: [
          CielAvatar(
            imageUrl: imageUrl,
            size: CielAvatarSize.lg,
            label: label,
            ring: ring,
            onTap: hasStories ? () => onOpenStory(stories, 0) : onAddStory,
            badge: Material(
              color: scheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAddStory,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.add,
                    size: 14,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: CielSpacing.xs),
          const SizedBox(
            width: 72,
            child: Text(
              'Your story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({
    required this.label,
    required this.imageUrl,
    required this.highlight,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: CielSpacing.md - 4),
      child: Column(
        children: [
          CielAvatar(
            imageUrl: imageUrl,
            size: CielAvatarSize.lg,
            label: label,
            ring: highlight
                ? CielStoryRingStyle.unseen
                : CielStoryRingStyle.seen,
            onTap: onTap,
          ),
          const SizedBox(height: CielSpacing.xs),
          SizedBox(
            width: 72,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
