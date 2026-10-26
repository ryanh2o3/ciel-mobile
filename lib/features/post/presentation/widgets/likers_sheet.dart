import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/ui/ciel_empty_state.dart';
import 'package:ciel_mobile/ui/ciel_user_list_tile.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> showLikersSheet(
  BuildContext context, {
  required String postId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return _LikersSheetBody(
            postId: postId,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _LikersSheetBody extends ConsumerStatefulWidget {
  const _LikersSheetBody({
    required this.postId,
    required this.scrollController,
  });

  final String postId;
  final ScrollController scrollController;

  @override
  ConsumerState<_LikersSheetBody> createState() => _LikersSheetBodyState();
}

class _LikersSheetBodyState extends ConsumerState<_LikersSheetBody> {
  final List<User> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final likes = await ref.read(postUseCaseProvider).fetchLikes(
            postId: widget.postId,
            limit: 50,
          );
      final users = <User>[];
      for (final like in likes.items) {
        try {
          final user =
              await ref.read(userUseCaseProvider).fetchUser(like.userId);
          users.add(user);
        } on Object {
          // Skip users that fail to load.
        }
      }
      if (mounted) {
        setState(() {
          _users
            ..clear()
            ..addAll(users);
          _loading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
        showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: CielSpacing.sm),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(CielSpacing.md),
          child: Text(
            'Likes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _users.isEmpty
                  ? CielEmptyState(
                      icon: Icons.error_outline,
                      title: 'Couldn’t load likes',
                      actionLabel: 'Retry',
                      onAction: _load,
                    )
                  : _users.isEmpty
                      ? const CielEmptyState(
                          icon: Icons.favorite_border,
                          title: 'No likes yet',
                        )
                      : ListView.builder(
                          controller: widget.scrollController,
                          itemCount: _users.length,
                          itemBuilder: (context, i) {
                            final u = _users[i];
                            return CielUserListTile(
                              avatarUrl: u.avatarUrl,
                              displayName: u.displayName,
                              handle: u.handle,
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/profile/${u.id}');
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
