import 'package:ciel_mobile/app/router/navigation_extras.dart';
import 'package:ciel_mobile/domain/entities/post_with_media.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
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

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      ref.read(feedNotifierProvider.notifier).loadInitialIfNeeded(user);
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
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
    ref.read(feedNotifierProvider.notifier).loadMoreIfNeeded(state.posts.last);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final state = ref.watch(feedNotifierProvider);

    ref.listen(authNotifierProvider, (prev, next) {
      if (prev?.user?.id != next.user?.id) {
        ref.read(feedNotifierProvider.notifier).refresh(next.user);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('PicShare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedNotifierProvider.notifier).refresh(auth.user),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            if (state.loading && state.posts.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              SliverToBoxAdapter(
                child: _StoryStrip(
                  myGroup: state.myStoryGroup,
                  groups: state.storyGroups,
                  onAddStory: () => context.push('/stories/create'),
                  onOpenStory: (stories, index) {
                    context.push(
                      '/stories/view',
                      extra: StoryViewerExtra(
                        stories: stories,
                        initialIndex: index,
                      ),
                    );
                  },
                ),
              ),
              if (state.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = state.posts[index];
                    return _PostTile(
                      item: item,
                      onOpen: () => context.push('/post/${item.post.id}'),
                      onOpenProfile: () =>
                          context.push('/profile/${item.post.ownerId}'),
                    );
                  },
                  childCount: state.posts.length,
                ),
              ),
              if (state.loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ],
        ),
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
  });

  final UserStoryGroup? myGroup;
  final List<UserStoryGroup> groups;
  final VoidCallback onAddStory;
  final void Function(List<Story> stories, int initialIndex) onOpenStory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _StoryAddChip(onTap: onAddStory),
          if (myGroup != null && myGroup!.stories.isNotEmpty)
            Builder(
              builder: (context) {
                final mg = myGroup!;
                return _StoryAvatar(
                  label: 'You',
                  imageUrl: mg.userAvatarUrl,
                  highlight: mg.hasUnseenStories,
                  onTap: () => onOpenStory(mg.stories, 0),
                );
              },
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

class _StoryAddChip extends StatelessWidget {
  const _StoryAddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            const Text('New', style: TextStyle(fontSize: 11)),
          ],
        ),
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
    final borderColor =
        highlight ? Theme.of(context).colorScheme.primary : Colors.grey.shade400;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 30,
                child: ClipOval(
                  child: CielNetworkImage(
                    imageUrl: imageUrl,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
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
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.item,
    required this.onOpen,
    required this.onOpenProfile,
  });

  final PostWithMedia item;
  final VoidCallback onOpen;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final thumb = item.primaryMedia?.mediumUrl ?? item.primaryMedia?.thumbUrl;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: CircleAvatar(
                child: ClipOval(
                  child: CielNetworkImage(
                    imageUrl: item.post.ownerAvatarUrl,
                  ),
                ),
              ),
              title: Text(item.post.ownerDisplayName ?? item.post.ownerHandle ?? ''),
              subtitle: Text('@${item.post.ownerHandle ?? ''}'),
              onTap: onOpenProfile,
            ),
            AspectRatio(
              aspectRatio: 1,
              child: CielNetworkImage(imageUrl: thumb),
            ),
            if (item.post.caption != null && item.post.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(item.post.caption!),
              ),
          ],
        ),
      ),
    );
  }
}
