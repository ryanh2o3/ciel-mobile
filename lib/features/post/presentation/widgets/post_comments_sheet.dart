import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/comment.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:ciel_mobile/features/feed/presentation/feed_notifier.dart';
import 'package:ciel_mobile/ui/ciel_avatar.dart';
import 'package:ciel_mobile/ui/ciel_relative_time.dart';
import 'package:ciel_mobile/ui/ciel_skeleton.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showPostCommentsSheet(
  BuildContext context, {
  required String postId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PostCommentsSheet(postId: postId),
  );
}

class _PostCommentsSheet extends ConsumerStatefulWidget {
  const _PostCommentsSheet({required this.postId});

  final String postId;

  @override
  ConsumerState<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends ConsumerState<_PostCommentsSheet> {
  static const _pageSize = 30;

  final _body = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  List<Comment> _comments = [];
  String? _nextCursor;
  String? _loadError;
  bool _loading = true;
  bool _loadingMore = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _body.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final page = await ref
          .read(postUseCaseProvider)
          .fetchComments(
            postId: widget.postId,
            limit: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _comments = page.items;
        _nextCursor = page.nextCursor;
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loadError = 'Comments couldn’t load. Try again.';
          _loading = false;
        });
        showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(postUseCaseProvider)
          .fetchComments(
            postId: widget.postId,
            limit: _pageSize,
            cursor: cursor,
          );
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, ...page.items];
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() => _loadingMore = false);
        showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _send() async {
    final text = _body.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment = await ref
          .read(postUseCaseProvider)
          .addComment(
            postId: widget.postId,
            body: text,
          );
      if (!mounted) return;
      _body.clear();
      setState(() {
        _comments = [comment, ..._comments];
        _sending = false;
      });
      ref
          .read(feedNotifierProvider.notifier)
          .changeCommentCount(postId: widget.postId, delta: 1);
      if (_scroll.hasClients) {
        await _scroll.animateTo(
          0,
          duration: CielDurations.normal,
          curve: Curves.easeOut,
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _delete(Comment comment) async {
    final userId = ref.read(authNotifierProvider).user?.id;
    if (userId == null || comment.userId != userId) return;
    try {
      await ref
          .read(postUseCaseProvider)
          .deleteComment(
            postId: widget.postId,
            commentId: comment.id,
          );
      if (mounted) {
        setState(() {
          _comments = _comments.where((item) => item.id != comment.id).toList();
        });
        ref
            .read(feedNotifierProvider.notifier)
            .changeCommentCount(postId: widget.postId, delta: -1);
      }
    } on Object catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authNotifierProvider).user?.id;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final availableHeight =
        MediaQuery.sizeOf(context).height - viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: availableHeight * 0.82,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(CielRadii.xl),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: CielSpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CielSpacing.md,
                  CielSpacing.md,
                  CielSpacing.md,
                  CielSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close comments',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildComments(userId)),
              _CommentComposer(
                controller: _body,
                focusNode: _focus,
                sending: _sending,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComments(String? userId) {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: CielSpacing.sm),
        itemCount: 7,
        itemBuilder: (_, _) => const _CommentSkeleton(),
      );
    }
    if (_loadError != null && _comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!),
            const SizedBox(height: CielSpacing.sm),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(CielSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 36,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: CielSpacing.sm),
              Text(
                'Start the conversation',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: CielSpacing.xs),
              Text(
                'Be the first to leave a comment.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: CielSpacing.xs),
      itemCount: _comments.length + (_nextCursor == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == _comments.length) {
          return Center(
            child: TextButton(
              onPressed: _loadingMore ? null : _loadMore,
              child: _loadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load earlier comments'),
            ),
          );
        }
        final comment = _comments[index];
        return _CommentTile(
          comment: comment,
          canDelete: userId == comment.userId,
          onDelete: () => _delete(comment),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  final Comment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CielSpacing.md,
        vertical: CielSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CielAvatar(
            size: CielAvatarSize.sm,
            label: comment.authorLabel,
          ),
          const SizedBox(width: CielSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: comment.authorLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(text: comment.body),
                    ],
                  ),
                ),
                const SizedBox(height: CielSpacing.xs),
                Text(
                  cielRelativeTime(comment.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'Delete comment',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CielSpacing.md,
            CielSpacing.sm,
            CielSpacing.sm,
            CielSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Add a comment…',
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: CielSpacing.md,
                      vertical: CielSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CielSpacing.xs),
              IconButton.filled(
                tooltip: 'Send comment',
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentSkeleton extends StatelessWidget {
  const _CommentSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: CielSpacing.md,
        vertical: CielSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CielSkeleton(
            width: CielAvatarSize.sm,
            height: CielAvatarSize.sm,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          SizedBox(width: CielSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CielSkeleton(height: 14),
                SizedBox(height: CielSpacing.xs),
                CielSkeleton(width: 90, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
