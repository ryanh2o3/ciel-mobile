import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/app/router/navigation_extras.dart';
import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({required this.extra, super.key});

  final StoryViewerExtra extra;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  late final PageController _page = PageController(
    initialPage: extra.initialIndex,
  );
  final Map<String, Media?> _media = {};
  int _index = 0;

  StoryViewerExtra get extra => widget.extra;

  @override
  void initState() {
    super.initState();
    _index = extra.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (extra.stories.isEmpty) {
        return;
      }
      unawaited(
        ref
            .read(feedNotifierProvider.notifier)
            .markStorySeen(extra.stories[_index].id),
      );
      unawaited(_prefetch(_index));
    });
  }

  Future<void> _prefetch(int i) async {
    if (i < 0 || i >= extra.stories.length) {
      return;
    }
    final story = extra.stories[i];
    if (_media.containsKey(story.mediaId)) {
      return;
    }
    try {
      final m = await ref.read(mediaUseCaseProvider).fetchMedia(story.mediaId);
      if (mounted) {
        setState(() => _media[story.mediaId] = m);
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() => _media[story.mediaId] = null);
      }
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = extra.stories;
    if (stories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Story')),
        body: const Center(child: Text('No stories')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _page,
              itemCount: stories.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                final s = stories[i];
                unawaited(
                  ref.read(feedNotifierProvider.notifier).markStorySeen(s.id),
                );
                unawaited(_prefetch(i));
              },
              itemBuilder: (context, i) {
                final story = stories[i];
                final media = _media[story.mediaId];
                final url = media?.mediumUrl ?? media?.originalUrl;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      textColor: Colors.white,
                      iconColor: Colors.white,
                      leading: CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: ClipOval(
                          child: CielNetworkImage(
                            imageUrl: story.userAvatarUrl,
                          ),
                        ),
                      ),
                      title: Text(
                        story.userDisplayName ?? story.userHandle ?? 'Story',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '@${story.userHandle ?? ''}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Expanded(
                      child: CielNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (story.caption != null && story.caption!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          story.caption!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    _ReactionRow(storyId: story.id),
                  ],
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionRow extends ConsumerStatefulWidget {
  const _ReactionRow({required this.storyId});

  final String storyId;

  @override
  ConsumerState<_ReactionRow> createState() => _ReactionRowState();
}

class _ReactionRowState extends ConsumerState<_ReactionRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final e in ['❤️', '🔥', '😂', '👏'])
            IconButton(
              onPressed: () async {
                try {
                  await ref
                      .read(storyUseCaseProvider)
                      .addReaction(storyId: widget.storyId, emoji: e);
                } on Object catch (_) {}
              },
              icon: Text(e, style: const TextStyle(fontSize: 28)),
            ),
        ],
      ),
    );
  }
}
