import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/post_with_media.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/features/post/presentation/post_share_service.dart';
import 'package:ciel_mobile/features/post/presentation/widgets/likers_sheet.dart';
import 'package:ciel_mobile/ui/ciel_avatar.dart';
import 'package:ciel_mobile/ui/ciel_media_carousel.dart';
import 'package:ciel_mobile/ui/ciel_relative_time.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({
    required this.item,
    required this.onOpen,
    required this.onOpenProfile,
    required this.onOpenComments,
    this.onOpenAtIndex,
    super.key,
  });

  final PostWithMedia item;
  final VoidCallback onOpen;
  final ValueChanged<int>? onOpenAtIndex;
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
    } else if (oldWidget.item.post.likeCount != widget.item.post.likeCount ||
        oldWidget.item.post.likedByViewer != widget.item.post.likedByViewer) {
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
    ref
        .read(feedNotifierProvider.notifier)
        .updatePostEngagement(
          postId: widget.item.post.id,
          likedByViewer: !wasLiked,
          likeCount: _likeCount,
        );
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
        ref
            .read(feedNotifierProvider.notifier)
            .updatePostEngagement(
              postId: widget.item.post.id,
              likedByViewer: wasLiked,
              likeCount: _likeCount,
            );
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

  Future<void> _openLikers() async {
    await showLikersSheet(context, postId: widget.item.post.id);
  }

  Future<void> _share(BuildContext anchorContext) async {
    try {
      await PostShareService.share(
        widget.item.post,
        sharePositionOrigin: PostShareService.originFrom(anchorContext),
      );
    } on Object catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final post = item.post;
    final name = post.ownerDisplayName ?? post.ownerHandle ?? '';
    final handle = post.ownerHandle ?? '';
    final scheme = Theme.of(context).colorScheme;
    final caption = post.caption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CielSpacing.md,
            vertical: CielSpacing.sm,
          ),
          child: Row(
            children: [
              CielAvatar(
                imageUrl: post.ownerAvatarUrl,
                size: CielAvatarSize.sm,
                label: name,
                onTap: widget.onOpenProfile,
              ),
              const SizedBox(width: CielSpacing.sm),
              Expanded(
                child: InkWell(
                  onTap: widget.onOpenProfile,
                  child: Text(
                    name.isNotEmpty ? name : '@$handle',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                cielRelativeTime(post.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        CielMediaCarousel(
          key: ValueKey(post.id),
          mediaItems: item.mediaItems,
          heroTagPrefix: 'post:${post.id}:media',
          onTapPage: (index) {
            final onOpenAtIndex = widget.onOpenAtIndex;
            if (onOpenAtIndex != null) {
              onOpenAtIndex(index);
            } else {
              widget.onOpen();
            }
          },
          onDoubleTap: _doubleTapLike,
          overlay: _showHeart
              ? Center(
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
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: CielSpacing.xs,
            right: CielSpacing.md,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: _liked ? 'Unlike post' : 'Like post',
                icon: Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Colors.red : null,
                ),
                onPressed: _busy ? null : _toggleLike,
              ),
              IconButton(
                tooltip: 'Open comments',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: widget.onOpenComments,
              ),
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Share post',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _share(context),
                ),
              ),
            ],
          ),
        ),
        if (_likeCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CielSpacing.md,
              0,
              CielSpacing.md,
              CielSpacing.xs,
            ),
            child: GestureDetector(
              onTap: _openLikers,
              child: Text(
                '$_likeCount ${_likeCount == 1 ? 'like' : 'likes'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (caption != null && caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CielSpacing.md,
              0,
              CielSpacing.md,
              CielSpacing.xs,
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  if (handle.isNotEmpty)
                    TextSpan(
                      text: handle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  if (handle.isNotEmpty) const TextSpan(text: ' '),
                  TextSpan(text: caption),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CielSpacing.md,
            0,
            CielSpacing.md,
            CielSpacing.sm,
          ),
          child: GestureDetector(
            onTap: widget.onOpenComments,
            child: Text(
              (post.commentCount ?? 0) > 0
                  ? 'View all ${post.commentCount} comments'
                  : 'Be the first to comment',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ],
    );
  }
}
