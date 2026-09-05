import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/app/router/navigation_extras.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/post_with_media.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_state.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_state.dart';
import 'package:ciel_mobile/ui/ciel_avatar.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
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
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _FeedEmpty(),
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

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(CielSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_outlined, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: CielSpacing.md),
          Text(
            'Your feed is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: CielSpacing.sm),
          Text(
            'Follow people or share a photo to get started.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CielSpacing.lg),
          Wrap(
            spacing: CielSpacing.sm,
            runSpacing: CielSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                onPressed: () => context.push('/search'),
                child: const Text('Find people'),
              ),
              OutlinedButton(
                onPressed: () => context.push('/create'),
                child: const Text('Create post'),
              ),
            ],
          ),
        ],
      ),
    );
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

    // Prefer own avatar; fall back to latest story thumb only if no avatar.
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

class PostCard extends ConsumerStatefulWidget {
  const PostCard({
    required this.item,
    required this.onOpen,
    required this.onOpenProfile,
    required this.onOpenComments,
    super.key,
  });

  final PostWithMedia item;
  final VoidCallback onOpen;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenComments;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with SingleTickerProviderStateMixin {
  late bool _liked;
  late int _likeCount;
  bool _busy = false;
  bool _showHeart = false;
  late final AnimationController _heartAnim;

  @override
  void initState() {
    super.initState();
    final post = widget.item.post;
    _liked = post.likedByViewer ?? false;
    _likeCount = post.likeCount ?? 0;
    _heartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.post.id != widget.item.post.id) {
      _liked = widget.item.post.likedByViewer ?? false;
      _likeCount = widget.item.post.likeCount ?? 0;
    }
  }

  @override
  void dispose() {
    _heartAnim.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_busy) {
      return;
    }
    final wasLiked = _liked;
    setState(() {
      _busy = true;
      _liked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });
    try {
      if (wasLiked) {
        await ref.read(postUseCaseProvider).unlikePost(widget.item.post.id);
      } else {
        await ref.read(postUseCaseProvider).likePost(widget.item.post.id);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
        showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _doubleTapLike() async {
    setState(() => _showHeart = true);
    _heartAnim.forward(from: 0);
    if (!_liked) {
      await _toggleLike();
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _showHeart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final post = item.post;
    final thumb = item.primaryMedia?.mediumUrl ?? item.primaryMedia?.thumbUrl;
    final name = post.ownerDisplayName ?? post.ownerHandle ?? '';
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CielSpacing.md,
          ),
          leading: CielAvatar(
            imageUrl: post.ownerAvatarUrl,
            size: CielAvatarSize.sm,
            label: name,
            onTap: widget.onOpenProfile,
          ),
          title: Text(name),
          subtitle: Text('@${post.ownerHandle ?? ''}'),
          onTap: widget.onOpenProfile,
        ),
        GestureDetector(
          onTap: widget.onOpen,
          onDoubleTap: _doubleTapLike,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CielNetworkImage(imageUrl: thumb),
                if (_showHeart)
                  Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.6, end: 1.2).animate(
                        CurvedAnimation(
                          parent: _heartAnim,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 80,
                        shadows: [
                          Shadow(blurRadius: 12, color: Colors.black45),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (post.caption != null && post.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CielSpacing.md,
              CielSpacing.sm,
              CielSpacing.md,
              0,
            ),
            child: Text(post.caption!),
          ),
        Padding(
          padding: const EdgeInsets.only(
            left: CielSpacing.xs,
            right: CielSpacing.md,
            bottom: CielSpacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Colors.red : null,
                ),
                onPressed: _busy ? null : _toggleLike,
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: widget.onOpenComments,
              ),
              if (_likeCount > 0 || (post.commentCount ?? 0) > 0)
                Expanded(
                  child: Text(
                    [
                      if (_likeCount > 0) '$_likeCount likes',
                      if ((post.commentCount ?? 0) > 0)
                        '${post.commentCount} comments',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ],
    );
  }
}
