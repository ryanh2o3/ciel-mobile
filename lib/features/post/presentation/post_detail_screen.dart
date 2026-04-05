import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/domain/entities/comment.dart';
import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
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
  bool _likedBusy = false;
  bool _loading = true;
  String? _error;
  final _commentBody = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
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
        } on Object catch (_) {}
      }
      final comments = await ref.read(postUseCaseProvider).fetchComments(
            postId: widget.postId,
            limit: 50,
          );
      if (mounted) {
        setState(() {
          _post = post;
          _media = mediaList;
          _comments = comments.items;
          _loading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _like() async {
    if (_likedBusy || _post == null) {
      return;
    }
    setState(() => _likedBusy = true);
    try {
      await ref.read(postUseCaseProvider).likePost(_post!.id);
    } on Object catch (_) {}
    if (mounted) {
      setState(() => _likedBusy = false);
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
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
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
    } on Object catch (_) {}
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
      setState(() => _comments = [..._comments, c]);
    } on Object catch (_) {}
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
    final thumb = _media.isNotEmpty
        ? (_media.first.mediumUrl ?? _media.first.thumbUrl)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (me?.id == post.ownerId)
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
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: _like,
              ),
            ],
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
              title: Text(c.body),
              subtitle: Text('User ${c.userId}'),
            ),
          ),
        ],
      ),
    );
  }
}
