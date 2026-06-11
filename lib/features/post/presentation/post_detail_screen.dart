import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/app_failure_mapper.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/comment.dart';
import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
import 'package:ciel_mobile/ui/report_user_sheet.dart';
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
  bool _isLiked = false;
  int _likeCount = 0;
  bool _likedBusy = false;
  bool _loading = true;
  String? _error;
  final _commentBody = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _commentBody.dispose();
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
      final comments = await ref
          .read(postUseCaseProvider)
          .fetchComments(
            postId: widget.postId,
            limit: 50,
          );
      final likes = await ref
          .read(postUseCaseProvider)
          .fetchLikes(
            postId: widget.postId,
            limit: 200,
          );
      final me = ref.read(authNotifierProvider).user;
      final liked = me != null && likes.items.any((l) => l.userId == me.id);
      if (mounted) {
        setState(() {
          _post = post;
          _media = mediaList;
          _comments = comments.items;
          _isLiked = liked;
          _likeCount = likes.items.length;
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

  Future<void> _reportPostOwner() async {
    final post = _post;
    if (post == null) {
      return;
    }
    final reason = await showReportUserSheet(context);
    if (reason == null) {
      return;
    }
    final fullReason = reason.isEmpty
        ? 'Reported post ${post.id}'
        : '$reason (post ${post.id})';
    try {
      await ref.read(moderationUseCaseProvider).reportUser(
            userId: post.ownerId,
            reason: fullReason,
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
      final c = await ref
          .read(postUseCaseProvider)
          .addComment(
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
    final thumb = _media.isNotEmpty
        ? (_media.first.mediumUrl ?? _media.first.thumbUrl)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (!isOwner)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'report') {
                  await _reportPostOwner();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'report',
                  child: Text('Report'),
                ),
              ],
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteIfOwner,
            ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: ClipOval(
                child: CielNetworkImage(
                  imageUrl: post.ownerAvatarUrl,
                ),
              ),
            ),
            title: Text(post.ownerDisplayName ?? post.ownerHandle ?? ''),
            subtitle: Text('@${post.ownerHandle ?? ''}'),
            onTap: () => context.push('/profile/${post.ownerId}'),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: CielNetworkImage(imageUrl: thumb),
          ),
          if (post.caption != null && post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(post.caption!),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                  onPressed: _likedBusy ? null : _toggleLike,
                ),
                Text('$_likeCount likes · ${_comments.length} comments'),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentBody,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment…',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendComment,
                ),
              ],
            ),
          ),
          ..._comments.map(
            (c) => ListTile(
              title: Text(c.authorLabel),
              subtitle: Text(c.body),
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
        ],
      ),
    );
  }
}
