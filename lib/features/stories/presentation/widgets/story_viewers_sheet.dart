import 'dart:async';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/error_snackbar.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/ui/ciel_empty_state.dart';
import 'package:ciel_mobile/ui/ciel_user_list_tile.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> showStoryViewersSheet(
  BuildContext context, {
  required String storyId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return _StoryViewersBody(
            storyId: storyId,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _StoryViewersBody extends ConsumerStatefulWidget {
  const _StoryViewersBody({
    required this.storyId,
    required this.scrollController,
  });

  final String storyId;
  final ScrollController scrollController;

  @override
  ConsumerState<_StoryViewersBody> createState() => _StoryViewersBodyState();
}

class _StoryViewersBodyState extends ConsumerState<_StoryViewersBody> {
  final List<StoryView> _items = [];
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
      final page = await ref.read(storyUseCaseProvider).fetchViewers(
            storyId: widget.storyId,
            limit: 50,
          );
      if (mounted) {
        setState(() {
          _items
            ..clear()
            ..addAll(page.items);
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
            'Viewers',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _items.isEmpty
                  ? CielEmptyState(
                      icon: Icons.error_outline,
                      title: 'Couldn’t load viewers',
                      actionLabel: 'Retry',
                      onAction: _load,
                    )
                  : _items.isEmpty
                      ? const CielEmptyState(
                          icon: Icons.visibility_outlined,
                          title: 'No viewers yet',
                        )
                      : ListView.builder(
                          controller: widget.scrollController,
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final v = _items[i];
                            final name =
                                v.viewerDisplayName ?? v.viewerHandle ?? 'User';
                            final handle = v.viewerHandle ?? '';
                            return CielUserListTile(
                              avatarUrl: v.viewerAvatarUrl,
                              displayName: name,
                              handle: handle.isEmpty ? name : handle,
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/profile/${v.viewerId}');
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
