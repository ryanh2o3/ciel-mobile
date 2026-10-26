import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/app_failure_mapper.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/comment.dart';
import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/features/post/presentation/widgets/likers_sheet.dart';
import 'package:ciel_mobile/ui/ciel_avatar.dart';
import 'package:ciel_mobile/ui/ciel_media_carousel.dart';
import 'package:ciel_mobile/ui/ciel_relative_time.dart';
import 'package:ciel_mobile/ui/report_user_sheet.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  Post? _post;
  List<Media> _media = [];
  List<Comment> _comments = [];
  String? _commentsCursor;
  bool _loadingMoreComments = false;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _likedBusy = false;
  bool _loading = true;
  String? _error;
  final _commentBody = TextEditingController();
  final _commentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _commentBody.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await ref.read(postUseCaseProvider).fetchPost(widget.postId);
      final mediaList = <Media>[];
      for (final id in post.mediaIds) {
        try {
          final m = await ref.read(mediaUseCaseProvider).fetchMedia(id);
          mediaList.add(m);
        } on Object catch (e) {
          if (mounted) {
            showErrorSnackBar(context, e);
          }
        }
      }
      final comments = await ref.read(postUseCaseProvider).fetchComments(
            postId: widget.postId,
            limit: 50,
          );
      final liked = post.likedByViewer ?? false;
      final likeCount = post.likeCount ?? 0;
      if (mounted) {
        setState(() {
          _post = post;
          _media = mediaList;
          _comments = comments.items;
          _commentsCursor = comments.nextCursor;
          _isLiked = liked;
          _likeCount = likeCount;
          _loading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = mapToFailure(e).userMessage;
        });
      }
    }
  }

  Future<void> _loadMoreComments() async {
    final cursor = _commentsCursor;
    if (cursor == null || _loadingMoreComments) {
      return;
    }
    setState(() => _loadingMoreComments = true);
    try {
      final page = await ref.read(postUseCaseProvider).fetchComments(
            postId: widget.postId,
            limit: 50,
            cursor: cursor,
          );
      if (mounted) {
        setState(() {
          _comments = [..._comments, ...page.items];
          _commentsCursor = page.nextCursor;
          _loadingMoreComments = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _loadingMoreComments = false);
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_likedBusy || _post == null) {
      return;
    }
    final wasLiked = _isLiked;
    setState(() {
      _likedBusy = true;
      _isLiked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });
    try {
      if (wasLiked) {
        await ref.read(postUseCaseProvider).unlikePost(_post!.id);
      } else {
        await ref.read(postUseCaseProvider).likePost(_post!.id);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
        showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _likedBusy = false);
      }
    }
  }

  Future<void> _editCaption() async {
    final post = _post;
    if (post == null) {
      return;
    }
    final controller = TextEditingController(text: post.caption ?? '');
    final next = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit caption'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 2200,
          decoration: const InputDecoration(hintText: 'Caption'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null || !mounted) {
      return;
    }
    try {
      final updated = await ref.read(postUseCaseProvider).updatePost(
            id: post.id,
            caption: next.isEmpty ? null : next,
          );
      if (!mounted) {
        return;
      }
      setState(() => _post = updated);
      showSuccessSnackBar(context, 'Caption updated');
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _deleteIfOwner() async {
    final me = ref.read(authNotifierProvider).user;
    final post = _post;
    if (me == null || post == null || post.ownerId != me.id) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    try {
      await ref.read(postUseCaseProvider).deletePost(post.id);
      ref.read(feedNotifierProvider.notifier).removePost(post.id);
      if (mounted) {
        context.pop();
      }
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _reportPost() async {
    final reason = await showReportPostSheet(context);
    if (reason == null) {
      return;
    }
    try {
      await ref.read(moderationUseCaseProvider).reportPost(
            postId: widget.postId,
            reason: reason.isEmpty ? null : reason,
          );
      if (mounted) {
        showSuccessSnackBar(context, 'Report submitted');
      }
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentBody.text.trim();
    if (text.isEmpty) {
      return;
    }
    try {
      final c = await ref.read(postUseCaseProvider).addComment(
            postId: widget.postId,
            body: text,
          );
      _commentBody.clear();
      setState(() => _comments = [c, ..._comments]);
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final me = ref.read(authNotifierProvider).user;
    if (me == null || comment.userId != me.id) {
      return;
    }
    try {
      await ref.read(postUseCaseProvider).deleteComment(
            postId: widget.postId,
            commentId: comment.id,
          );
      setState(
        () => _comments = _comments.where((c) => c.id != comment.id).toList(),
      );
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Not found')),
      );
    }
    final post = _post!;
    final me = ref.watch(authNotifierProvider).user;
    final isOwner = me?.id == post.ownerId;
    final handle = post.ownerHandle ?? '';
    final name = post.ownerDisplayName ?? handle;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'report':
                  await _reportPost();
                case 'edit':
                  await _editCaption();
                case 'delete':
                  await _deleteIfOwner();
              }
            },
            itemBuilder: (context) => [
              if (isOwner) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit caption'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ] else
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report'),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
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
                        onTap: () => context.push('/profile/${post.ownerId}'),
                      ),
                      const SizedBox(width: CielSpacing.sm),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              context.push('/profile/${post.ownerId}'),
                          child: Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
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
                CielMediaCarousel(mediaItems: _media),
                Padding(
                  padding: const EdgeInsets.only(left: CielSpacing.xs),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : null,
                        ),
                        onPressed: _likedBusy ? null : _toggleLike,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline),
                        onPressed: () => _commentFocus.requestFocus(),
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
                      onTap: () => showLikersSheet(
                        context,
                        postId: post.id,
                      ),
                      child: Text(
                        '$_likeCount ${_likeCount == 1 ? 'like' : 'likes'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (post.caption != null && post.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CielSpacing.md,
                      0,
                      CielSpacing.md,
                      CielSpacing.sm,
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (handle.isNotEmpty)
                            TextSpan(
                              text: handle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          if (handle.isNotEmpty) const TextSpan(text: ' '),
                          TextSpan(text: post.caption),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 1),
                ..._comments.map(
                  (c) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: CielSpacing.md,
                    ),
                    leading: CielAvatar(
                      size: CielAvatarSize.sm,
                      label: c.authorLabel,
                      onTap: () => context.push('/profile/${c.userId}'),
                    ),
                    title: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: c.authorLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: c.body),
                        ],
                      ),
                    ),
                    subtitle: Text(cielRelativeTime(c.createdAt)),
                    onLongPress: me?.id == c.userId
                        ? () => _deleteComment(c)
                        : null,
                    trailing: me?.id == c.userId
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteComment(c),
                          )
                        : null,
                  ),
                ),
                if (_commentsCursor != null)
                  TextButton(
                    onPressed: _loadingMoreComments ? null : _loadMoreComments,
                    child: _loadingMoreComments
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load more comments'),
                  ),
                const SizedBox(height: CielSpacing.lg),
              ],
            ),
          ),
          Material(
            elevation: 2,
            color: scheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: CielSpacing.md,
                  right: CielSpacing.sm,
                  top: CielSpacing.sm,
                  bottom: MediaQuery.viewInsetsOf(context).bottom > 0
                      ? CielSpacing.sm
                      : CielSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentBody,
                        focusNode: _commentFocus,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment…',
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendComment,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
