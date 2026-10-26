import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/app/router/navigation_extras.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/features/stories/presentation/widgets/story_viewers_sheet.dart';
import 'package:ciel_mobile/ui/ciel_avatar.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({required this.extra, super.key});

  final StoryViewerExtra extra;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, Media?> _media = {};
  late int _index;
  bool _paused = false;
  double _dragOffset = 0;
  late final AnimationController _progress;

  static const _storyDuration = Duration(seconds: 5);

  StoryViewerExtra get extra => widget.extra;
  List<Story> get stories => extra.stories;

  @override
  void initState() {
    super.initState();
    _index = extra.initialIndex.clamp(
      0,
      stories.isEmpty ? 0 : stories.length - 1,
    );
    _progress = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener(_onProgressStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (stories.isEmpty) {
        return;
      }
      unawaited(_markSeen(_index));
      unawaited(_prefetch(_index));
      unawaited(_prefetch(_index + 1));
      _startProgress();
    });
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goNext();
    }
  }

  void _startProgress() {
    if (!mounted || stories.isEmpty || _paused) {
      return;
    }
    _progress
      ..duration = _storyDuration
      ..forward(from: 0);
  }

  void _pause() {
    if (_paused) {
      return;
    }
    setState(() => _paused = true);
    _progress.stop();
  }

  void _resume() {
    if (!_paused) {
      return;
    }
    setState(() => _paused = false);
    _progress.forward();
  }

  Future<void> _markSeen(int i) async {
    if (i < 0 || i >= stories.length) {
      return;
    }
    await ref.read(feedNotifierProvider.notifier).markStorySeen(stories[i].id);
  }

  Future<void> _prefetch(int i) async {
    if (i < 0 || i >= stories.length) {
      return;
    }
    final story = stories[i];
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

  void _goNext() {
    if (_index >= stories.length - 1) {
      if (mounted) {
        context.pop();
      }
      return;
    }
    setState(() => _index += 1);
    unawaited(_markSeen(_index));
    unawaited(_prefetch(_index + 1));
    _startProgress();
  }

  void _goPrev() {
    if (_progress.value > 0.2) {
      _startProgress();
      return;
    }
    if (_index <= 0) {
      _startProgress();
      return;
    }
    setState(() => _index -= 1);
    unawaited(_markSeen(_index));
    unawaited(_prefetch(_index - 1));
    _startProgress();
  }

  Future<void> _openViewers(Story story) async {
    _pause();
    await showStoryViewersSheet(context, storyId: story.id);
    if (mounted) {
      _resume();
    }
  }

  @override
  void dispose() {
    _progress
      ..removeStatusListener(_onProgressStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Story')),
        body: const Center(child: Text('No stories')),
      );
    }

    final story = stories[_index];
    final media = _media[story.mediaId];
    final url = media?.mediumUrl ?? media?.originalUrl;
    final name = story.userDisplayName ?? story.userHandle ?? 'Story';
    final me = ref.watch(authNotifierProvider).user;
    final isOwner = me?.id == story.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (d) {
          setState(() => _dragOffset += d.delta.dy);
        },
        onVerticalDragEnd: (d) {
          if (_dragOffset > 100 || (d.primaryVelocity ?? 0) > 600) {
            context.pop();
            return;
          }
          setState(() => _dragOffset = 0);
        },
        child: Transform.translate(
          offset: Offset(0, _dragOffset.clamp(0, 400)),
          child: Opacity(
            opacity: (1 - (_dragOffset / 400)).clamp(0.4, 1),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Row(
                      children: [
                        for (var i = 0; i < stories.length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: _ProgressSegment(
                                controller: _progress,
                                active: i == _index,
                                filled: i < _index,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ListTile(
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    leading: CielAvatar(
                      imageUrl: story.userAvatarUrl,
                      size: CielAvatarSize.sm,
                      label: name,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '@${story.userHandle ?? ''}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOwner)
                          IconButton(
                            tooltip: 'Viewers',
                            icon: const Icon(
                              Icons.visibility_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () => unawaited(_openViewers(story)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onLongPressStart: (_) => _pause(),
                      onLongPressEnd: (_) => _resume(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CielNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _goPrev,
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _goNext,
                                ),
                              ),
                            ],
                          ),
                          if (story.caption != null &&
                              story.caption!.isNotEmpty)
                            Positioned(
                              left: CielSpacing.md,
                              right: CielSpacing.md,
                              bottom: CielSpacing.md,
                              child: Text(
                                story.caption!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 8,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (isOwner)
                    Padding(
                      padding: const EdgeInsets.only(bottom: CielSpacing.xs),
                      child: TextButton.icon(
                        onPressed: () => unawaited(_openViewers(story)),
                        icon: const Icon(
                          Icons.visibility_outlined,
                          color: Colors.white70,
                          size: 18,
                        ),
                        label: Text(
                          '${story.viewCount} '
                          '${story.viewCount == 1 ? 'view' : 'views'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    _ReactionRow(storyId: story.id),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({
    required this.controller,
    required this.active,
    required this.filled,
  });

  final AnimationController controller;
  final bool active;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 2.5,
        child: filled
            ? const ColoredBox(color: Colors.white)
            : active
                ? AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      return LinearProgressIndicator(
                        value: controller.value,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                        minHeight: 2.5,
                      );
                    },
                  )
                : const ColoredBox(color: Colors.white24),
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
  String? _lastReacted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CielSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final e in ['❤️', '🔥', '😂', '👏'])
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                try {
                  await ref
                      .read(storyUseCaseProvider)
                      .addReaction(storyId: widget.storyId, emoji: e);
                  if (context.mounted) {
                    setState(() => _lastReacted = e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reacted $e'),
                        duration: const Duration(milliseconds: 640),
                      ),
                    );
                  }
                } on Object catch (err) {
                  if (context.mounted) {
                    showErrorSnackBar(context, err);
                  }
                }
              },
              icon: Opacity(
                opacity: _lastReacted == e ? 1 : 0.95,
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            ),
        ],
      ),
    );
  }
}
